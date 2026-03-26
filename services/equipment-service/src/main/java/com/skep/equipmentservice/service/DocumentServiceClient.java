package com.skep.equipmentservice.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class DocumentServiceClient {

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    @Value("${document-service.url:http://localhost:8082/api/documents}")
    private String documentServiceUrl;

    @Value("${document-service.timeout:30000}")
    private long documentServiceTimeout;

    public boolean checkRequiredDocumentsValid(UUID equipmentId, String equipmentType) {
        try {
            String response = webClient.get()
                    .uri(documentServiceUrl + "/" + equipmentId + "/EQUIPMENT")
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(java.time.Duration.ofMillis(documentServiceTimeout))
                    .onErrorResume(e -> {
                        log.warn("Document service call failed: {}", e.getMessage());
                        return Mono.just("[]");
                    })
                    .block();

            if (response == null || response.equals("[]")) {
                return false;
            }

            var documents = objectMapper.readTree(response);
            LocalDate today = LocalDate.now();

            for (var doc : documents) {
                if (doc.has("expiry_date")) {
                    LocalDate expiryDate = LocalDate.parse(doc.get("expiry_date").asText());
                    if (expiryDate.isBefore(today) || expiryDate.equals(today)) {
                        return false;
                    }
                }
                if (!doc.has("verified") || !doc.get("verified").asBoolean()) {
                    return false;
                }
            }

            return true;
        } catch (Exception e) {
            log.error("Failed to check document validity: {}", equipmentId, e);
            return false;
        }
    }

    public DocumentValidationResult getDocumentValidationDetails(UUID equipmentId) {
        try {
            String response = webClient.get()
                    .uri(documentServiceUrl + "/" + equipmentId + "/EQUIPMENT")
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(java.time.Duration.ofMillis(documentServiceTimeout))
                    .onErrorResume(e -> Mono.just("[]"))
                    .block();

            var documents = objectMapper.readTree(response != null ? response : "[]");
            LocalDate today = LocalDate.now();

            Map<String, Object> details = new HashMap<>();
            details.put("total_documents", documents.size());
            details.put("verified_documents", 0);
            details.put("expired_documents", 0);
            details.put("unverified_documents", 0);

            int verified = 0;
            int expired = 0;
            int unverified = 0;

            for (var doc : documents) {
                if (doc.has("verified") && doc.get("verified").asBoolean()) {
                    verified++;
                } else {
                    unverified++;
                }

                if (doc.has("expiry_date")) {
                    LocalDate expiryDate = LocalDate.parse(doc.get("expiry_date").asText());
                    if (expiryDate.isBefore(today)) {
                        expired++;
                    }
                }
            }

            details.put("verified_documents", verified);
            details.put("expired_documents", expired);
            details.put("unverified_documents", unverified);

            return new DocumentValidationResult(true, "Documents retrieved", details);
        } catch (Exception e) {
            log.error("Failed to get document details: {}", equipmentId, e);
            return new DocumentValidationResult(false, "Failed to validate documents", new HashMap<>());
        }
    }

    public static class DocumentValidationResult {
        public final boolean valid;
        public final String message;
        public final Map<String, Object> details;

        public DocumentValidationResult(boolean valid, String message, Map<String, Object> details) {
            this.valid = valid;
            this.message = message;
            this.details = details;
        }
    }
}
