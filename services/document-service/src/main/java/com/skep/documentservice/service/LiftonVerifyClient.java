package com.skep.documentservice.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.http.client.MultipartBodyBuilder;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;

import jakarta.annotation.PostConstruct;
import java.time.Duration;
import java.util.Map;

/**
 * verify-server(main-api) 기반 실제 정부 API 검증 클라이언트.
 * - 사업자등록: 국세청 NTS_API
 * - 운전면허:   도로교통공단 RIMS
 * - 화물운송:   국토교통부 공공데이터
 * - 안전보건교육: KOSHA
 * - OCR 추출:   Google Vision (verify-api:8081)
 *
 * 호출 경로:
 *  skep-document-service  →  main-api:8080/api/verify/*  →  verify-api:8081
 *                        (X-API-KEY 헤더 인증)
 *  skep-document-service  →  verify-api:8081/verify/ocr/extract/{type}  (직접)
 */
@Slf4j
@Component
public class LiftonVerifyClient {

    @Value("${verify.main-api.url:${VERIFY_MAIN_API_URL:http://main-api:8080}}")
    private String mainApiUrl;

    @Value("${verify.inner-api.url:${VERIFY_INNER_API_URL:http://verify-api:8081}}")
    private String innerApiUrl;

    @Value("${verify.api-key:${VERIFY_API_KEY:your-secure-api-key-here}}")
    private String apiKey;

    private WebClient webClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @PostConstruct
    public void init() {
        this.webClient = WebClient.builder().build();
        log.info("Verify client init: main={} inner={} apiKey={}***", mainApiUrl, innerApiUrl,
                apiKey == null || apiKey.isBlank() ? "(empty)" : apiKey.substring(0, Math.min(4, apiKey.length())));
    }

    // ─── 사업자등록 ─────────────────────────────────────────────
    // main-api /api/verify/biz  — body: {bizNo, startDate(yyyyMMdd), ownerName}
    public JsonNode verifyBusinessRegistration(String bizNo, String startDate, String ownerName) {
        return callJson(mainApiUrl + "/api/verify/biz",
                Map.of(
                        "bizNo", safe(bizNo),
                        "startDate", safe(startDate),
                        "ownerName", safe(ownerName)
                ));
    }

    // backward compat (기존 시그니처)
    public JsonNode verifyBusinessRegistration(String businessNumber) {
        return verifyBusinessRegistration(businessNumber, "", "");
    }

    // ─── 운전면허 (RIMS) ──────────────────────────────────────
    // main-api /api/verify/rims/license  — body: f_license_no, f_resident_name (snake_case with f_ prefix)
    public JsonNode verifyDriverLicense(String licenseNo, String name, String birthDate) {
        return verifyDriverLicense(licenseNo, name, birthDate, null);
    }

    public JsonNode verifyDriverLicense(String licenseNo, String name, String birthDate, String licenseConditionCode) {
        java.util.Map<String, Object> body = new java.util.HashMap<>();
        body.put("f_license_no", safe(licenseNo));
        body.put("f_resident_name", safe(name));
        // OCR에서 추출한 면허종별코드 우선 사용. 없으면 01(1종 보통) 기본
        String code = licenseConditionCode != null && !licenseConditionCode.isBlank() ? licenseConditionCode : "01";
        body.put("f_licn_con_code", code);
        return callJson(mainApiUrl + "/api/verify/rims/license", body);
    }

    public JsonNode verifyDriverLicense(String licenseNumber, String name) {
        return verifyDriverLicense(licenseNumber, name, "");
    }

    // ─── 화물운송자격증 ─────────────────────────────────────
    // main-api /api/verify/cargo — body: {name, birth(yyyyMMdd), lcnsNo}
    public JsonNode verifyCargo(String name, String birth, String lcnsNo) {
        return callJson(mainApiUrl + "/api/verify/cargo",
                Map.of(
                        "name", safe(name),
                        "birth", safe(birth),
                        "lcnsNo", safe(lcnsNo)
                ));
    }

    // ─── KOSHA 교육이수 (multipart image) ──────────────────
    public JsonNode verifyKosha(byte[] fileBytes, String filename) {
        return callMultipart(mainApiUrl + "/api/verify/kosha", fileBytes, filename, "file");
    }

    // ─── 범용 OCR 추출 (verify-api 직접) ──────────────────────
    // POST /verify/ocr/extract/{type}  — multipart field "image"
    // type: DRIVER_LICENSE / BUSINESS_REGISTRATION / CARGO / KOSHA 등
    public JsonNode extractOcr(String type, byte[] fileBytes, String filename) {
        // verify-api OcrExtract 지원 타입: LICENSE, BUSINESS, CARGO, EQUIPMENT_REGISTRATION, KOSHA
        String t = type == null ? "" : type.toUpperCase();
        String mapped = switch (t) {
            case "DRIVER_LICENSE", "LICENSE" -> "LICENSE";
            case "BUSINESS_REGISTRATION", "BUSINESS" -> "BUSINESS";
            case "CARGO", "CARGO_LICENSE" -> "CARGO";
            case "VEHICLE_LICENSE", "EQUIPMENT_REGISTRATION" -> "EQUIPMENT_REGISTRATION";
            case "KOSHA", "KOSHA_CERTIFICATE", "SAFETY_TRAINING" -> "KOSHA";
            default -> "LICENSE"; // fallback
        };
        return callMultipart(innerApiUrl + "/verify/ocr/extract/" + mapped, fileBytes, filename, "image");
    }

    // ─── 공통 호출 헬퍼 ────────────────────────────────────
    private JsonNode callJson(String url, java.util.Map<String, ?> body) {
        try {
            String response = webClient.post()
                    .uri(url)
                    .header("X-API-KEY", apiKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(30))
                    .block();
            return objectMapper.readTree(response != null ? response : "{}");
        } catch (Exception e) {
            log.warn("verify call failed: {} {}", url, e.getMessage());
            try {
                return objectMapper.readTree(String.format(
                        "{\"result\":\"UNKNOWN\",\"reasonCode\":\"UPSTREAM_ERROR\",\"message\":%s,\"valid\":false}",
                        objectMapper.writeValueAsString(e.getMessage())));
            } catch (Exception ex) {
                return null;
            }
        }
    }

    private JsonNode callMultipart(String url, byte[] fileBytes, String filename, String fieldName) {
        try {
            MultipartBodyBuilder builder = new MultipartBodyBuilder();
            builder.part(fieldName, new ByteArrayResource(fileBytes) {
                @Override public String getFilename() { return filename; }
            }).contentType(MediaType.APPLICATION_OCTET_STREAM);

            String response = webClient.post()
                    .uri(url)
                    .header("X-API-KEY", apiKey)
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(BodyInserters.fromMultipartData(builder.build()))
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(60))
                    .block();
            return objectMapper.readTree(response != null ? response : "{}");
        } catch (Exception e) {
            log.warn("multipart verify call failed: {} {}", url, e.getMessage());
            return null;
        }
    }

    private static String safe(String s) { return s == null ? "" : s; }
}
