package com.skep.documentservice.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.skep.documentservice.domain.dto.DocumentResponse;
import com.skep.documentservice.domain.dto.DocumentTypeResponse;
import com.skep.documentservice.domain.entity.Document;
import com.skep.documentservice.domain.entity.DocumentType;
import com.skep.documentservice.exception.DocumentException;
import com.skep.documentservice.repository.DocumentRepository;
import com.skep.documentservice.repository.DocumentTypeRepository;
import com.skep.documentservice.util.S3FileUploader;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class DocumentService {

    private final DocumentRepository documentRepository;
    private final DocumentTypeRepository documentTypeRepository;
    private final S3FileUploader s3FileUploader;
    private final OcrService ocrService;
    private final VerificationService verificationService;
    private final ObjectMapper objectMapper;

    public com.skep.documentservice.domain.entity.DocumentType findDocumentTypeByName(String name) {
        return documentTypeRepository.findByName(name).orElse(null);
    }

    @Transactional
    public DocumentResponse uploadDocument(
            UUID ownerId,
            Document.OwnerType ownerType,
            UUID documentTypeId,
            MultipartFile file,
            UUID uploadedBy) throws IOException {

        if (file == null || file.isEmpty()) {
            throw new DocumentException("File is required");
        }

        DocumentType documentType = documentTypeRepository.findById(documentTypeId)
                .orElseThrow(() -> new DocumentException("Document type not found"));

        String fileUrl = s3FileUploader.uploadFile(file);

        Document document = Document.builder()
                .ownerId(ownerId)
                .ownerType(ownerType)
                .documentType(documentType)
                .fileUrl(fileUrl)
                .originalFilename(file.getOriginalFilename())
                .verified(false)
                .status(Document.DocumentStatus.PENDING)
                .uploadedBy(uploadedBy)
                .build();

        // Process OCR if required
        if (documentType.getRequiresOcr()) {
            JsonNode ocrResult = ocrService.processOcr(fileUrl, documentType.getName());
            if (ocrResult != null) {
                document = Document.builder()
                        .id(document.getId())
                        .ownerId(document.getOwnerId())
                        .ownerType(document.getOwnerType())
                        .documentType(document.getDocumentType())
                        .fileUrl(document.getFileUrl())
                        .originalFilename(document.getOriginalFilename())
                        .ocrResult(ocrResult)
                        .verified(false)
                        .status(Document.DocumentStatus.PENDING)
                        .uploadedBy(document.getUploadedBy())
                        .build();

                // Extract dates from OCR result if available
                try {
                    if (ocrResult.has("issue_date")) {
                        document = Document.builder()
                                .id(document.getId())
                                .ownerId(document.getOwnerId())
                                .ownerType(document.getOwnerType())
                                .documentType(document.getDocumentType())
                                .fileUrl(document.getFileUrl())
                                .originalFilename(document.getOriginalFilename())
                                .ocrResult(ocrResult)
                                .issueDate(LocalDate.parse(ocrResult.get("issue_date").asText()))
                                .verified(false)
                                .status(Document.DocumentStatus.PENDING)
                                .uploadedBy(document.getUploadedBy())
                                .build();
                    }
                    if (ocrResult.has("expiry_date")) {
                        document = Document.builder()
                                .id(document.getId())
                                .ownerId(document.getOwnerId())
                                .ownerType(document.getOwnerType())
                                .documentType(document.getDocumentType())
                                .fileUrl(document.getFileUrl())
                                .originalFilename(document.getOriginalFilename())
                                .ocrResult(ocrResult)
                                .issueDate(document.getIssueDate())
                                .expiryDate(LocalDate.parse(ocrResult.get("expiry_date").asText()))
                                .verified(false)
                                .status(Document.DocumentStatus.PENDING)
                                .uploadedBy(document.getUploadedBy())
                                .build();
                    }
                } catch (Exception e) {
                    log.warn("Failed to parse dates from OCR result", e);
                }
            }
        }

        // Process verification if required
        if (documentType.getRequiresVerification()) {
            String documentNumber = extractDocumentNumber(document.getOcrResult());
            if (documentNumber != null) {
                JsonNode verificationResult = verificationService.verifyDocument(
                        documentType.getName(), documentNumber);
                if (verificationResult != null) {
                    document = Document.builder()
                            .id(document.getId())
                            .ownerId(document.getOwnerId())
                            .ownerType(document.getOwnerType())
                            .documentType(document.getDocumentType())
                            .fileUrl(document.getFileUrl())
                            .originalFilename(document.getOriginalFilename())
                            .ocrResult(document.getOcrResult())
                            .issueDate(document.getIssueDate())
                            .expiryDate(document.getExpiryDate())
                            .verified(verificationResult.has("verified") && verificationResult.get("verified").asBoolean())
                            .verificationResult(verificationResult)
                            .status(document.getVerified() ? Document.DocumentStatus.VERIFIED : Document.DocumentStatus.FAILED)
                            .uploadedBy(document.getUploadedBy())
                            .build();
                }
            }
        }

        Document savedDocument = documentRepository.save(document);
        log.info("Document uploaded successfully: id={}, owner={}, type={}", savedDocument.getId(), ownerId, documentTypeId);

        return mapToResponse(savedDocument);
    }

    @Transactional(readOnly = true)
    public List<DocumentResponse> getDocumentsByOwner(UUID ownerId, Document.OwnerType ownerType) {
        return documentRepository.findByOwnerIdAndOwnerType(ownerId, ownerType)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public DocumentResponse getDocument(UUID documentId) {
        Document document = documentRepository.findById(documentId)
                .orElseThrow(() -> new DocumentException("Document not found"));
        return mapToResponse(document);
    }

    @Transactional
    public DocumentResponse verifyDocument(UUID documentId) {
        Document document = documentRepository.findById(documentId)
                .orElseThrow(() -> new DocumentException("Document not found"));

        String documentNumber = extractDocumentNumber(document.getOcrResult());
        if (documentNumber == null) {
            throw new DocumentException("Cannot extract document number for verification");
        }

        JsonNode verificationResult = verificationService.verifyDocument(
                document.getDocumentType().getName(), documentNumber);

        boolean isVerified = verificationResult != null && verificationResult.has("verified") && verificationResult.get("verified").asBoolean();
        Document updatedDocument = Document.builder()
                .id(document.getId())
                .ownerId(document.getOwnerId())
                .ownerType(document.getOwnerType())
                .documentType(document.getDocumentType())
                .fileUrl(document.getFileUrl())
                .originalFilename(document.getOriginalFilename())
                .ocrResult(document.getOcrResult())
                .issueDate(document.getIssueDate())
                .expiryDate(document.getExpiryDate())
                .verified(isVerified)
                .verificationResult(verificationResult)
                .status(isVerified ? Document.DocumentStatus.VERIFIED : Document.DocumentStatus.FAILED)
                .uploadedBy(document.getUploadedBy())
                .build();

        Document savedDocument = documentRepository.save(updatedDocument);
        log.info("Document verified: id={}, verified={}", documentId, savedDocument.getVerified());

        return mapToResponse(savedDocument);
    }

    @Transactional(readOnly = true)
    public List<DocumentResponse> getExpiringDocuments(int daysThreshold) {
        LocalDate targetDate = LocalDate.now().plusDays(daysThreshold);
        return documentRepository.findExpiringDocuments(targetDate)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<DocumentTypeResponse> getDocumentTypes() {
        return documentTypeRepository.findAll()
                .stream()
                .map(this::mapTypeToResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public void deleteDocument(UUID documentId) {
        Document document = documentRepository.findById(documentId)
                .orElseThrow(() -> new DocumentException("Document not found"));

        s3FileUploader.deleteFile(document.getFileUrl());
        documentRepository.deleteById(documentId);
        log.info("Document deleted: id={}", documentId);
    }

    private DocumentResponse mapToResponse(Document document) {
        Integer daysUntilExpiry = null;
        if (document.getExpiryDate() != null) {
            daysUntilExpiry = (int) ChronoUnit.DAYS.between(LocalDate.now(), document.getExpiryDate());
        }

        return DocumentResponse.builder()
                .id(document.getId())
                .ownerId(document.getOwnerId())
                .ownerType(document.getOwnerType().toString())
                .documentTypeId(document.getDocumentType().getId())
                .documentTypeName(document.getDocumentType().getName())
                .fileUrl(document.getFileUrl())
                .originalFilename(document.getOriginalFilename())
                .ocrResult(document.getOcrResult())
                .verified(document.getVerified())
                .verificationResult(document.getVerificationResult())
                .issueDate(document.getIssueDate())
                .expiryDate(document.getExpiryDate())
                .status(document.getStatus().toString())
                .uploadedBy(document.getUploadedBy())
                .createdAt(document.getCreatedAt())
                .updatedAt(document.getUpdatedAt())
                .daysUntilExpiry(daysUntilExpiry)
                .build();
    }

    private DocumentTypeResponse mapTypeToResponse(DocumentType type) {
        return DocumentTypeResponse.builder()
                .id(type.getId())
                .name(type.getName())
                .description(type.getDescription())
                .requiresOcr(type.getRequiresOcr())
                .requiresVerification(type.getRequiresVerification())
                .hasExpiry(type.getHasExpiry())
                .build();
    }

    private String extractDocumentNumber(JsonNode ocrResult) {
        if (ocrResult == null) {
            return null;
        }
        if (ocrResult.has("document_number")) {
            return ocrResult.get("document_number").asText();
        }
        if (ocrResult.has("registration_number")) {
            return ocrResult.get("registration_number").asText();
        }
        return null;
    }
}
