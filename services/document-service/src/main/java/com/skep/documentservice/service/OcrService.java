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
            // For KOSHA type documents, we need multipart upload - caller should use processKoshaOcr instead.
            // For other types, use the legacy flow or return empty.
            log.info("Processing OCR for documentType={}, fileUrl={}", documentType, fileUrl);

            if ("KOSHA_CERTIFICATE".equalsIgnoreCase(documentType) || "SAFETY_TRAINING".equalsIgnoreCase(documentType)) {
                log.warn("KOSHA OCR requires image bytes - use processKoshaOcr() instead");
                return objectMapper.readTree("{}");
            }

            // For non-KOSHA documents, return empty (no generic OCR endpoint on verify-server)
            return objectMapper.readTree("{}");
        } catch (Exception e) {
            log.error("Failed to process OCR for file: {}", fileUrl, e);
            return null;
        }
    }
}
