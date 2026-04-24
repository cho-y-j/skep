package com.skep.documentservice.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
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
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
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
    private final LiftonVerifyClient liftonVerifyClient;
    private final ObjectMapper objectMapper;
    private final ApplicationEventPublisher eventPublisher;

    // 트랜잭션 커밋 후 자동 OCR을 비동기로 돌리기 위한 이벤트
    public record DocumentUploadedEvent(UUID documentId) {}

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

        // NOTE: 업로드 시 자동 OCR(skep-ocr mock) 호출은 제거됨.
        //       Mock이 가짜 데이터(Jane Smith 등)를 넣는 문제. 관리자가 수동으로 필드 입력하도록 함.

        // Process OCR if required (verify-server 기반 KOSHA 등 기존 흐름)
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

        // 자동 OCR + 마스킹은 트랜잭션 커밋 후 별도 실행 (verify-api 호출이 트랜잭션을 길게 잡지 않도록)
        eventPublisher.publishEvent(new DocumentUploadedEvent(savedDocument.getId()));

        return mapToResponse(savedDocument);
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onDocumentUploaded(DocumentUploadedEvent event) {
        try {
            runOcrOnDocument(event.documentId());
        } catch (Exception e) {
            log.warn("Auto-OCR on upload failed for doc {}: {}", event.documentId(), e.getMessage());
        }
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

        // OCR 결과에서 부가 필드들을 뽑아 verify-server에 함께 전달
        java.util.Map<String, String> extra = collectVerifyFields(document.getOcrResult());
        JsonNode verificationResult = verificationService.verifyDocument(
                document.getDocumentType().getName(), documentNumber, extra);

        // UNSUPPORTED_TYPE은 여전히 OCR-only 모드로 처리 (fallback)
        boolean unsupported = verificationResult != null && (
                (verificationResult.has("reasonCode") && "UNSUPPORTED_TYPE".equals(verificationResult.get("reasonCode").asText())) ||
                (verificationResult.has("code") && "UNSUPPORTED_TYPE".equals(verificationResult.get("code").asText()))
        );
        boolean isVerified;
        if (unsupported) {
            isVerified = true;
            ObjectNode ok = objectMapper.createObjectNode();
            ok.put("verified", true);
            ok.put("source", "ocr-only");
            ok.put("documentNumber", documentNumber);
            verificationResult = ok;
        } else {
            isVerified = verificationResult != null && verificationResult.has("verified") && verificationResult.get("verified").asBoolean();
        }
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

    // 문서의 이미지 파일을 읽어 verify-api로 실제 OCR 수행 + 결과를 ocr_result에 저장
    public JsonNode runOcrOnDocument(UUID documentId) throws java.io.IOException {
        Document document = documentRepository.findById(documentId)
                .orElseThrow(() -> new DocumentException("Document not found"));
        String fileKey = document.getFileUrl().replaceAll("^/uploads/", "");
        java.nio.file.Path filePath = java.nio.file.Paths.get("/tmp/skep-uploads", fileKey);
        byte[] bytes;
        try {
            bytes = java.nio.file.Files.readAllBytes(filePath);
        } catch (java.nio.file.NoSuchFileException e) {
            throw new DocumentException("파일을 찾을 수 없습니다: " + filePath);
        }
        String docTypeName = document.getDocumentType() != null ? document.getDocumentType().getName() : "";
        String ocrType = mapToOcrType(docTypeName);
        JsonNode extracted = liftonVerifyClient.extractOcr(ocrType, bytes, document.getOriginalFilename());
        // 마스킹 이미지가 반환되면 파일을 해당 이미지로 덮어씀 (주민번호 마스킹된 이미지)
        if (extracted != null && extracted.has("maskedImageBase64")) {
            String b64 = extracted.get("maskedImageBase64").asText("");
            if (!b64.isEmpty()) {
                try {
                    byte[] maskedBytes = java.util.Base64.getDecoder().decode(b64);
                    java.nio.file.Files.write(filePath, maskedBytes);
                    log.info("Overwrote file with masked image for doc {}", documentId);
                } catch (Exception e) {
                    log.warn("Failed to write masked image: {}", e.getMessage());
                }
            }
        }
        // ocr_result에 extractedFields로 감싸 저장
        ObjectNode wrapper = objectMapper.createObjectNode();
        wrapper.put("source", "verify-api:google-vision");
        wrapper.put("docType", ocrType);
        // 대용량 masked 이미지는 DB에 저장하지 않음 (응답에만 포함)
        if (extracted != null && extracted.isObject()) {
            ObjectNode fields = objectMapper.createObjectNode();
            extracted.fieldNames().forEachRemaining(k -> {
                if (!"maskedImageBase64".equals(k)) fields.set(k, extracted.get(k));
            });
            wrapper.set("extractedFields", fields);
        }
        Document updated = Document.builder()
                .id(document.getId()).ownerId(document.getOwnerId()).ownerType(document.getOwnerType())
                .documentType(document.getDocumentType()).fileUrl(document.getFileUrl())
                .originalFilename(document.getOriginalFilename()).ocrResult(wrapper)
                .issueDate(document.getIssueDate()).expiryDate(document.getExpiryDate())
                .verified(document.getVerified()).verificationResult(document.getVerificationResult())
                .status(document.getStatus()).uploadedBy(document.getUploadedBy()).build();
        documentRepository.save(updated);
        // 클라이언트에는 (masked 이미지 포함한) 원본 반환
        return extracted;
    }

    private String mapToOcrType(String name) {
        if (name == null) return "LICENSE";
        if (name.contains("운전면허") || name.contains("조종사면허")) return "DRIVER_LICENSE";
        if (name.contains("사업자")) return "BUSINESS_REGISTRATION";
        if (name.contains("화물운송")) return "CARGO";
        if (name.contains("안전보건교육") || name.contains("조종사안전교육")) return "KOSHA";
        if (name.contains("자동차등록") || name.contains("건설기계등록")) return "VEHICLE_LICENSE";
        return "LICENSE";
    }

    // OCR 결과만 조회 (편집 UI용)
    @Transactional(readOnly = true)
    public java.util.Map<String, Object> getOcrResult(UUID documentId) {
        Document document = documentRepository.findById(documentId)
                .orElseThrow(() -> new DocumentException("Document not found"));
        java.util.Map<String, Object> result = new java.util.HashMap<>();
        result.put("id", document.getId());
        result.put("documentType", document.getDocumentType() != null ? document.getDocumentType().getName() : null);
        result.put("verified", document.getVerified());
        result.put("ocrResult", document.getOcrResult());
        return result;
    }

    // 관리자가 편집한 OCR 필드를 저장하며 검증 상태도 함께 처리
    public DocumentResponse saveOcrAndVerify(UUID documentId, JsonNode body) {
        Document document = documentRepository.findById(documentId)
                .orElseThrow(() -> new DocumentException("Document not found"));
        JsonNode newOcr = body.has("ocrResult") ? body.get("ocrResult") :
                (body.has("extractedFields") ? body : document.getOcrResult());
        boolean newVerified = body.has("verified") && body.get("verified").asBoolean();
        Document updated = Document.builder()
                .id(document.getId())
                .ownerId(document.getOwnerId())
                .ownerType(document.getOwnerType())
                .documentType(document.getDocumentType())
                .fileUrl(document.getFileUrl())
                .originalFilename(document.getOriginalFilename())
                .ocrResult(newOcr)
                .issueDate(document.getIssueDate())
                .expiryDate(document.getExpiryDate())
                .verified(newVerified)
                .verificationResult(document.getVerificationResult())
                .status(newVerified ? Document.DocumentStatus.VERIFIED : Document.DocumentStatus.PENDING)
                .uploadedBy(document.getUploadedBy())
                .build();
        Document saved = documentRepository.save(updated);
        log.info("OCR fields saved and verified={} for doc {}", newVerified, documentId);
        return mapToResponse(saved);
    }

    // 관리자 override: OCR/검증 로직 없이 verified flag만 직접 설정
    public DocumentResponse markVerified(UUID documentId, boolean value) {
        Document document = documentRepository.findById(documentId)
                .orElseThrow(() -> new DocumentException("Document not found"));
        Document updated = Document.builder()
                .id(document.getId())
                .ownerId(document.getOwnerId())
                .ownerType(document.getOwnerType())
                .documentType(document.getDocumentType())
                .fileUrl(document.getFileUrl())
                .originalFilename(document.getOriginalFilename())
                .ocrResult(document.getOcrResult())
                .issueDate(document.getIssueDate())
                .expiryDate(document.getExpiryDate())
                .verified(value)
                .verificationResult(document.getVerificationResult())
                .status(value ? Document.DocumentStatus.VERIFIED : Document.DocumentStatus.PENDING)
                .uploadedBy(document.getUploadedBy())
                .build();
        Document saved = documentRepository.save(updated);
        log.info("Document mark-verified override: id={}, verified={}", documentId, value);
        return mapToResponse(saved);
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

    // OCR 결과에서 verify-server가 요구하는 보조 필드들을 뽑아냄
    private java.util.Map<String, String> collectVerifyFields(JsonNode ocrResult) {
        java.util.Map<String, String> m = new java.util.HashMap<>();
        if (ocrResult == null) return m;
        JsonNode fields = ocrResult.has("extractedFields") ? ocrResult.get("extractedFields") : ocrResult;
        String[][] map = {
            // verify-server 필드명 ← OCR 후보 필드명들
            {"name", "name", "ownerName", "driverName", "holderName"},
            {"birthDate", "birthDate", "dateOfBirth", "birth"},
            {"representativeName", "representativeName", "representative"},
            {"openDate", "openDate", "registrationDate", "issueDate"},
            {"vehicleNumber", "vehicleNumber", "vehicleNo"},
            {"issueDate", "issueDate", "registrationDate"},
            {"expiryDate", "expiryDate"},
        };
        for (String[] row : map) {
            for (int i = 1; i < row.length; i++) {
                if (fields.has(row[i]) && !fields.get(row[i]).isNull()) {
                    m.put(row[0], fields.get(row[i]).asText());
                    break;
                }
            }
        }
        return m;
    }

    private String extractDocumentNumber(JsonNode ocrResult) {
        if (ocrResult == null) return null;
        // skep-ocr의 응답 구조: { extractedFields: { registrationNumber, licenseNumber, vehicleNumber, businessNumber } }
        JsonNode fields = ocrResult.has("extractedFields") ? ocrResult.get("extractedFields") : ocrResult;
        String[] candidates = {
            "document_number", "documentNumber",
            "registration_number", "registrationNumber",
            "license_number", "licenseNumber",
            "vehicle_number", "vehicleNumber",
            "business_number", "businessNumber",
        };
        for (String key : candidates) {
            if (fields.has(key) && !fields.get(key).isNull()) return fields.get(key).asText();
        }
        return null;
    }
}
