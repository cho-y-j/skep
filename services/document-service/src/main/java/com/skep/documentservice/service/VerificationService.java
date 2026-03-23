package com.skep.documentservice.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
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

import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class VerificationService {

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    @Value("${verify.server-url:${VERIFY_SERVER_URL:http://verify-main-api:8080}}")
    private String verifyServerUrl;

    @Value("${verify.api-key:${VERIFY_API_KEY:}}")
    private String verifyApiKey;

    @Value("${verify.timeout:30000}")
    private long verifyTimeout;

    /**
     * Route verification to the correct verify-server endpoint based on document type.
     */
    public JsonNode verifyDocument(String documentType, String documentNumber) {
        return verifyDocument(documentType, documentNumber, null);
    }

    /**
     * Verify a document with additional metadata.
     */
    public JsonNode verifyDocument(String documentType, String documentNumber, Map<String, String> additionalParams) {
        try {
            String endpoint = resolveEndpoint(documentType);
            if (endpoint == null) {
                log.warn("Unknown document type for verification: {}", documentType);
                return buildErrorResponse("UNSUPPORTED_TYPE", "Unsupported document type: " + documentType);
            }

            ObjectNode requestBody = buildRequestBody(documentType, documentNumber, additionalParams);

            String response = webClient.post()
                    .uri(verifyServerUrl + endpoint)
                    .header("X-API-KEY", verifyApiKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(requestBody)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(java.time.Duration.ofMillis(verifyTimeout))
                    .onErrorResume(e -> {
                        log.warn("Verify-server call failed for {}: {}", documentType, e.getMessage());
                        return Mono.just("{\"verified\": false, \"result\": \"UNKNOWN\", \"reason\": \"Service unavailable\"}");
                    })
                    .block();

            return objectMapper.readTree(response != null ? response : "{}");
        } catch (Exception e) {
            log.error("Failed to verify document: type={}, number={}", documentType, documentNumber, e);
            return buildErrorResponse("INTERNAL_ERROR", "Verification failed: " + e.getMessage());
        }
    }

    /**
     * Verify KOSHA education certificate via image upload (multipart).
     */
    public JsonNode verifyKoshaCertificate(byte[] imageBytes, String filename) {
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
                        return Mono.just("{\"verified\": false, \"result\": \"UNKNOWN\", \"reason\": \"Service unavailable\"}");
                    })
                    .block();

            return objectMapper.readTree(response != null ? response : "{}");
        } catch (Exception e) {
            log.error("Failed to verify KOSHA certificate: {}", filename, e);
            return buildErrorResponse("INTERNAL_ERROR", "KOSHA verification failed: " + e.getMessage());
        }
    }

    /**
     * Resolve the verify-server API endpoint based on document type.
     */
    private String resolveEndpoint(String documentType) {
        if (documentType == null) return null;
        return switch (documentType.toUpperCase()) {
            case "BUSINESS_LICENSE", "BUSINESS_REGISTRATION" -> "/api/verify/biz";
            case "DRIVER_LICENSE" -> "/api/verify/rims/license";
            case "CARGO_LICENSE", "CARGO_CERTIFICATE" -> "/api/verify/cargo";
            case "KOSHA_CERTIFICATE", "SAFETY_TRAINING" -> "/api/verify/kosha";
            default -> null;
        };
    }

    /**
     * Build the JSON request body based on document type.
     */
    private ObjectNode buildRequestBody(String documentType, String documentNumber, Map<String, String> additionalParams) {
        ObjectNode body = objectMapper.createObjectNode();
        body.put("documentNumber", documentNumber);

        if (additionalParams != null) {
            additionalParams.forEach(body::put);
        }

        // Map fields to what the verify-server expects
        switch (documentType.toUpperCase()) {
            case "BUSINESS_LICENSE", "BUSINESS_REGISTRATION" -> {
                body.put("bizNo", documentNumber);
                if (additionalParams != null) {
                    if (additionalParams.containsKey("representativeName")) {
                        body.put("representativeName", additionalParams.get("representativeName"));
                    }
                    if (additionalParams.containsKey("openDate")) {
                        body.put("openDate", additionalParams.get("openDate"));
                    }
                }
            }
            case "DRIVER_LICENSE" -> {
                body.put("licenseNo", documentNumber);
            }
            case "CARGO_LICENSE", "CARGO_CERTIFICATE" -> {
                body.put("certificateNo", documentNumber);
            }
            default -> {
                // Use generic fields
            }
        }

        return body;
    }

    private JsonNode buildErrorResponse(String reasonCode, String message) {
        try {
            ObjectNode error = objectMapper.createObjectNode();
            error.put("verified", false);
            error.put("result", "UNKNOWN");
            error.put("reasonCode", reasonCode);
            error.put("message", message);
            return error;
        } catch (Exception e) {
            return null;
        }
    }
}
