package com.skep.documentservice.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import javax.crypto.SecretKey;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.nio.file.attribute.FileTime;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.ReentrantLock;

import org.springframework.scheduling.annotation.Scheduled;

@Slf4j
@Service
@RequiredArgsConstructor
public class WorksheetEditorService {

    private static final Path SESSION_DIR = Paths.get("/tmp/skep-worksheet-sessions");
    private static final Duration SESSION_TTL = Duration.ofHours(24);
    private static final HttpClient HTTP = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();
    private final ConcurrentHashMap<String, ReentrantLock> sessionLocks = new ConcurrentHashMap<>();
    private final ObjectMapper objectMapper;

    @Value("${ONLYOFFICE_JWT_SECRET:change_me_jwt}")
    private String jwtSecret;

    // OnlyOffice 컨테이너가 호출할 document-service 내부 URL (docker network 내부)
    @Value("${ONLYOFFICE_INTERNAL_DOC_SERVICE:http://document-service:9082}")
    private String internalDocServiceUrl;

    // OnlyOffice 문서 서버 HTTP URL — 콜백에서 편집본 다운로드 시 사용
    // (OnlyOffice가 보내는 callback body의 url은 http://skep-onlyoffice:80/... 임)
    // 별도 변환 필요 없음 — 그대로 사용

    private SecretKey signKey() {
        return Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));
    }

    // 세션 생성: DOCX 저장 + OnlyOffice editor config 반환
    public Map<String, Object> createSession(MultipartFile docx, String userName, String baseName) throws IOException {
        if (docx == null || docx.isEmpty()) throw new IllegalArgumentException("DOCX 파일이 필요합니다");
        Files.createDirectories(SESSION_DIR);
        String sessionId = UUID.randomUUID().toString();
        Path sessionFile = SESSION_DIR.resolve(sessionId + ".docx");
        Files.write(sessionFile, docx.getBytes());

        String safeBase = (baseName == null || baseName.isBlank()) ? "worksheet" : baseName;
        String fileName = safeBase + ".docx";

        // OnlyOffice가 내부에서 호출할 URL — document-service에 직접 접근
        String documentUrl = internalDocServiceUrl + "/api/worksheet/editor-file/" + sessionId;
        String callbackUrl = internalDocServiceUrl + "/api/worksheet/onlyoffice-callback/" + sessionId;

        // OnlyOffice config
        ObjectNode config = objectMapper.createObjectNode();
        config.put("documentType", "word");
        ObjectNode document = config.putObject("document");
        document.put("fileType", "docx");
        document.put("key", sessionId);
        document.put("title", fileName);
        document.put("url", documentUrl);
        ObjectNode editorConfig = config.putObject("editorConfig");
        editorConfig.put("callbackUrl", callbackUrl);
        editorConfig.put("lang", "ko");
        editorConfig.put("mode", "edit");
        ObjectNode user = editorConfig.putObject("user");
        user.put("id", UUID.randomUUID().toString());
        user.put("name", userName == null || userName.isBlank() ? "SKEP 사용자" : userName);
        ObjectNode custom = editorConfig.putObject("customization");
        custom.put("autosave", true);
        custom.put("forcesave", true);
        custom.put("uiTheme", "theme-light");
        ObjectNode goback = custom.putObject("goback");
        goback.put("text", "작업계획서로 돌아가기");
        // JWT 토큰 — OnlyOffice 7.1+ 는 config 최상위 필드(document.key 등)를 JWT claims로 flat 하게 요구
        @SuppressWarnings("unchecked")
        Map<String, Object> configMap = objectMapper.convertValue(config, Map.class);
        String token = Jwts.builder()
                .claims().add(configMap).and()
                .expiration(new Date(System.currentTimeMillis() + TimeUnit.HOURS.toMillis(6)))
                .signWith(signKey())
                .compact();
        config.put("token", token);

        return Map.of(
                "sessionId", sessionId,
                "fileName", fileName,
                "config", config
        );
    }

    public byte[] readSession(String sessionId) throws IOException {
        try {
            return Files.readAllBytes(SESSION_DIR.resolve(sessionId + ".docx"));
        } catch (NoSuchFileException e) {
            throw new IllegalArgumentException("세션을 찾을 수 없습니다: " + sessionId);
        }
    }

    public Path sessionFile(String sessionId) {
        return SESSION_DIR.resolve(sessionId + ".docx");
    }

    public Map<String, Object> handleCallback(String sessionId, JsonNode body) {
        int status = body.has("status") ? body.get("status").asInt() : 0;
        log.info("OnlyOffice callback: session={} status={}", sessionId, status);
        // status: 1=editing, 2=save, 3=error save, 4=no change, 6=forcesave, 7=error forcesave
        if (status != 2 && status != 6) return Map.of("error", 0);

        String url = body.has("url") ? body.get("url").asText() : null;
        if (url == null) {
            log.warn("Callback without url for session {}", sessionId);
            return Map.of("error", 1);
        }
        // 동일 세션에 대한 동시 save 콜백이 서로 덮어쓰지 않도록 세션별 lock
        ReentrantLock lock = sessionLocks.computeIfAbsent(sessionId, k -> new ReentrantLock());
        lock.lock();
        try {
            HttpRequest req = HttpRequest.newBuilder(URI.create(url))
                    .timeout(Duration.ofSeconds(30))
                    .GET().build();
            HttpResponse<byte[]> resp = HTTP.send(req, HttpResponse.BodyHandlers.ofByteArray());
            if (resp.statusCode() != 200) {
                log.error("Edited DOCX download failed for session {}: status={}", sessionId, resp.statusCode());
                return Map.of("error", 1);
            }
            Path tmp = SESSION_DIR.resolve(sessionId + ".docx.tmp");
            Files.write(tmp, resp.body());
            Files.move(tmp, sessionFile(sessionId), StandardCopyOption.REPLACE_EXISTING);
            log.info("Saved edited DOCX for session {} ({} bytes)", sessionId, resp.body().length);
            return Map.of("error", 0);
        } catch (Exception e) {
            log.error("Callback error for session " + sessionId, e);
            return Map.of("error", 1);
        } finally {
            lock.unlock();
        }
    }

    // 24시간 지난 세션 파일 정리 — 편집하지 않는 파일이 무한 적체되는 것 방지
    @Scheduled(cron = "0 0 * * * *")
    public void cleanupExpiredSessions() {
        if (!Files.isDirectory(SESSION_DIR)) return;
        Instant cutoff = Instant.now().minus(SESSION_TTL);
        try (var stream = Files.list(SESSION_DIR)) {
            stream.filter(p -> p.toString().endsWith(".docx")).forEach(p -> {
                try {
                    FileTime mtime = Files.getLastModifiedTime(p);
                    if (mtime.toInstant().isBefore(cutoff)) {
                        Files.deleteIfExists(p);
                        String id = p.getFileName().toString().replaceFirst("\\.docx$", "");
                        sessionLocks.remove(id);
                        log.info("Deleted expired session {}", id);
                    }
                } catch (IOException ignored) { /* best-effort */ }
            });
        } catch (IOException e) {
            log.warn("Session cleanup failed: {}", e.getMessage());
        }
    }
}
