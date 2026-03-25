package com.skep.documentservice.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;

import jakarta.annotation.PostConstruct;
import java.time.Duration;
import java.util.Map;

@Slf4j
@Component
public class LiftonVerifyClient {

    @Value("${verify.api.base-url:https://sk.on1.kr}")
    private String baseUrl;

    @Value("${verify.api.email:_skep_internal_svc_7f3a@system.local}")
    private String serviceEmail;

    @Value("${verify.api.password:Xk9mN2vRpL5wQ8jF1@@}")
    private String servicePassword;

    private WebClient webClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    private String accessToken;
    private long tokenExpiresAt = 0;

    @PostConstruct
    public void init() {
        this.webClient = WebClient.builder()
                .baseUrl(baseUrl)
                .build();
        log.info("LiftonVerifyClient initialized with base URL: {}", baseUrl);
    }

    private synchronized String getToken() {
        if (accessToken != null && System.currentTimeMillis() < tokenExpiresAt) {
            return accessToken;
        }

        try {
            String response = webClient.post()
                    .uri("/api/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(Map.of("email", serviceEmail, "password", servicePassword))
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(10))
                    .block();

            JsonNode json = objectMapper.readTree(response);
            if (json.path("success").asBoolean()) {
                accessToken = json.path("data").path("accessToken").asText();
                tokenExpiresAt = System.currentTimeMillis() + 23 * 60 * 60 * 1000; // 23시간
                log.info("Lifton verify token refreshed");
                return accessToken;
            }
            log.error("Lifton login failed: {}", json.path("message").asText());
        } catch (Exception e) {
            log.error("Failed to get lifton token: {}", e.getMessage());
        }
        return null;
    }

    public JsonNode verifyDriverLicense(String licenseNumber, String name) {
        return callVerifyApi("/api/verify/driver-license",
                MediaType.APPLICATION_FORM_URLENCODED,
                BodyInserters.fromFormData("licenseNumber", licenseNumber).with("name", name));
    }

    public JsonNode verifyBusinessRegistration(String businessNumber) {
        return callVerifyApi("/api/verify/business-registration",
                MediaType.APPLICATION_FORM_URLENCODED,
                BodyInserters.fromFormData("businessNumber", businessNumber));
    }

    public JsonNode verifyCargo(String name, String birth, String lcnsNo) {
        return callVerifyApiJson("/api/verify/cargo",
                Map.of("name", name, "birth", birth, "lcnsNo", lcnsNo));
    }

    public JsonNode verifyKosha(byte[] fileBytes, String filename) {
        return callVerifyApi("/api/verify/kosha",
                MediaType.MULTIPART_FORM_DATA,
                BodyInserters.fromMultipartData("file",
                        new org.springframework.core.io.ByteArrayResource(fileBytes) {
                            @Override
                            public String getFilename() {
                                return filename;
                            }
                        }));
    }

    private JsonNode callVerifyApiJson(String path, Map<String, String> body) {
        String token = getToken();
        if (token == null) return errorNode("인증 토큰 획득 실패");

        try {
            String response = webClient.post()
                    .uri(path)
                    .contentType(MediaType.APPLICATION_JSON)
                    .header("Authorization", "Bearer " + token)
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(30))
                    .block();
            return objectMapper.readTree(response);
        } catch (Exception e) {
            log.error("Verify API call failed [{}]: {}", path, e.getMessage());
            return errorNode(e.getMessage());
        }
    }

    private JsonNode callVerifyApi(String path, MediaType contentType,
                                   BodyInserters.FormInserter<?> body) {
        String token = getToken();
        if (token == null) return errorNode("인증 토큰 획득 실패");

        try {
            String response = webClient.post()
                    .uri(path)
                    .contentType(contentType)
                    .header("Authorization", "Bearer " + token)
                    .body(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(30))
                    .block();
            return objectMapper.readTree(response);
        } catch (Exception e) {
            log.error("Verify API call failed [{}]: {}", path, e.getMessage());
            return errorNode(e.getMessage());
        }
    }

    private JsonNode errorNode(String message) {
        return objectMapper.createObjectNode()
                .put("success", false)
                .put("message", message);
    }
}
