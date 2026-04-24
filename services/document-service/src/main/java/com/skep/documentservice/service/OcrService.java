package com.skep.documentservice.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.http.client.MultipartBodyBuilder;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

@Slf4j
@Service
@RequiredArgsConstructor
public class OcrService {

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    @Value("${verify.server-url:${VERIFY_SERVER_URL:http://verify-main-api:8080}}")
    private String verifyServerUrl;

    @Value("${verify.api-key:${VERIFY_API_KEY:}}")
    private String verifyApiKey;

    @Value("${verify.timeout:30000}")
    private long verifyTimeout;

    // skep-ocr-service 내부 주소 (docker network) — Mock OCR
    @Value("${skep.ocr-url:${OCR_SERVICE_URL:http://ocr-service:9089}}")
    private String skepOcrUrl;

    /**
     * skep-ocr-service (Mock)에서 document_type 기반 필드 추출
     * document-service 내부 네트워크 호출
     */
    public JsonNode extractViaSkepOcr(String docTypeName) {
        try {
            String ocrType = mapToOcrType(docTypeName);
            java.util.Map<String, String> body = java.util.Map.of("document_type", ocrType, "file_data", "mock");
            String response = webClient.post()
                    .uri(skepOcrUrl + "/api/ocr/extract")
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(java.time.Duration.ofMillis(10000))
                    .onErrorResume(e -> {
                        log.warn("skep-ocr call failed for {} ({}): {}", docTypeName, ocrType, e.getMessage());
                        return Mono.just("{}");
                    })
                    .block();
            log.info("skep-ocr response for {} ({}): {}", docTypeName, ocrType,
                    response != null ? response.substring(0, Math.min(200, response.length())) : "null");
            return objectMapper.readTree(response != null ? response : "{}");
        } catch (Exception e) {
            log.error("skep-ocr error for {}", docTypeName, e);
            return null;
        }
    }

    /**
     * 한국어 document type 이름 → skep-ocr의 document_type enum 매핑
     */
    private String mapToOcrType(String name) {
        if (name == null) return "BUSINESS_REGISTRATION";
        if (name.contains("운전면허") || name.contains("조종사면허")) return "DRIVER_LICENSE";
        if (name.contains("등록증") || name.contains("등록원부")) return "VEHICLE_LICENSE";
        if (name.contains("사업자")) return "BUSINESS_REGISTRATION";
        if (name.contains("보험")) return "VEHICLE_LICENSE";
        if (name.contains("안전인증") || name.contains("검사")) return "VEHICLE_LICENSE";
        if (name.contains("교육") || name.contains("이수")) return "DRIVER_LICENSE";
        return "BUSINESS_REGISTRATION";
    }

    /**
     * Process OCR by calling the verify-server KOSHA endpoint (multipart with image).
     * Used for education certificate verification via QR/OCR.
     */
    public JsonNode processKoshaOcr(byte[] imageBytes, String filename) {
        try {
            MultipartBodyBuilder builder = new MultipartBodyBuilder();
            builder.part("image", new ByteArrayResource(imageBytes) {
                @Override
                public String getFilename() {
                    return filename;
                }
            }).contentType(MediaType.APPLICATION_OCTET_STREAM);

            String response = webClient.post()
                    .uri(verifyServerUrl + "/api/verify/kosha")
                    .header("X-API-KEY", verifyApiKey)
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(BodyInserters.fromMultipartData(builder.build()))
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(java.time.Duration.ofMillis(verifyTimeout))
                    .onErrorResume(e -> {
                        log.warn("Verify-server KOSHA call failed: {}", e.getMessage());
                        return Mono.just("{}");
                    })
                    .block();

            return objectMapper.readTree(response != null ? response : "{}");
        } catch (Exception e) {
            log.error("Failed to process KOSHA OCR for file: {}", filename, e);
            return null;
        }
    }

    /**
     * Generic OCR processing - delegates to verify-server based on document type.
     */
    public JsonNode processOcr(String fileUrl, String documentType) {
        try {
            log.info("Processing OCR for documentType={}, fileUrl={}", documentType, fileUrl);
            if ("KOSHA_CERTIFICATE".equalsIgnoreCase(documentType) || "SAFETY_TRAINING".equalsIgnoreCase(documentType)) {
                log.warn("KOSHA OCR requires image bytes - use processKoshaOcr() instead");
                return objectMapper.readTree("{}");
            }
            // 기본 동작을 skep-ocr-service(mock)로 위임해 extractedFields를 채운다
            JsonNode r = extractViaSkepOcr(documentType);
            return r != null ? r : objectMapper.readTree("{}");
        } catch (Exception e) {
            log.error("Failed to process OCR for file: {}", fileUrl, e);
            return null;
        }
    }
}
