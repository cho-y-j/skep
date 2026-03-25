package com.skep.documentservice.controller;

import com.skep.documentservice.domain.dto.DocumentResponse;
import com.skep.documentservice.domain.dto.DocumentTypeResponse;
import com.skep.documentservice.domain.entity.Document;
import com.skep.documentservice.service.DocumentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/documents")
@RequiredArgsConstructor
public class DocumentController {

    private final DocumentService documentService;

    @PostMapping("/upload")
    public ResponseEntity<DocumentResponse> uploadDocument(
            @RequestParam("owner_id") UUID ownerId,
            @RequestParam("owner_type") String ownerType,
            @RequestParam(value = "document_type_id", required = false) UUID documentTypeId,
            @RequestParam(value = "document_type", required = false) String documentTypeName,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "uploaded_by", defaultValue = "00000000-0000-0000-0000-000000000000") UUID uploadedBy) throws IOException {

        Document.OwnerType type = Document.OwnerType.valueOf(ownerType.toUpperCase());

        // document_type_id가 없으면 document_type(이름)으로 조회
        UUID resolvedTypeId = documentTypeId;
        if (resolvedTypeId == null && documentTypeName != null) {
            var docType = documentService.findDocumentTypeByName(documentTypeName);
            if (docType != null) {
                resolvedTypeId = docType.getId();
            } else {
                // 타입이 없으면 기본 UUID 사용
                resolvedTypeId = UUID.fromString("00000000-0000-0000-0000-000000000000");
            }
        }
        if (resolvedTypeId == null) {
            resolvedTypeId = UUID.fromString("00000000-0000-0000-0000-000000000000");
        }

        DocumentResponse response = documentService.uploadDocument(ownerId, type, resolvedTypeId, file, uploadedBy);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/expiring")
    public ResponseEntity<List<DocumentResponse>> getExpiringDocuments(
            @RequestParam(value = "days", defaultValue = "30") int daysThreshold) {

        List<DocumentResponse> expiringDocuments = documentService.getExpiringDocuments(daysThreshold);
        return ResponseEntity.ok(expiringDocuments);
    }

    @GetMapping("/types")
    public ResponseEntity<List<DocumentTypeResponse>> getDocumentTypes() {
        List<DocumentTypeResponse> types = documentService.getDocumentTypes();
        return ResponseEntity.ok(types);
    }

    @GetMapping("/{ownerId}/{ownerType}")
    public ResponseEntity<List<DocumentResponse>> getDocumentsByOwner(
            @PathVariable UUID ownerId,
            @PathVariable String ownerType) {

        Document.OwnerType type = Document.OwnerType.valueOf(ownerType.toUpperCase());
        List<DocumentResponse> documents = documentService.getDocumentsByOwner(ownerId, type);

        return ResponseEntity.ok(documents);
    }

    @GetMapping("/{id}")
    public ResponseEntity<DocumentResponse> getDocument(@PathVariable UUID id) {
        DocumentResponse document = documentService.getDocument(id);
        return ResponseEntity.ok(document);
    }

    @PostMapping("/{id}/verify")
    public ResponseEntity<DocumentResponse> verifyDocument(@PathVariable UUID id) {
        DocumentResponse document = documentService.verifyDocument(id);
        return ResponseEntity.ok(document);
    }

    @GetMapping("/{id}/file")
    public ResponseEntity<Resource> getDocumentFile(@PathVariable UUID id) throws MalformedURLException {
        DocumentResponse doc = documentService.getDocument(id);
        String fileUrl = doc.getFileUrl();

        if (fileUrl == null || !fileUrl.startsWith("/uploads/")) {
            return ResponseEntity.notFound().build();
        }

        String filename = fileUrl.replace("/uploads/", "");
        Path filePath = Paths.get("/tmp/skep-uploads", filename);

        if (!Files.exists(filePath)) {
            return ResponseEntity.notFound().build();
        }

        Resource resource = new UrlResource(filePath.toUri());
        String contentType;
        try {
            contentType = Files.probeContentType(filePath);
        } catch (IOException e) {
            contentType = "application/octet-stream";
        }
        if (contentType == null) contentType = "application/octet-stream";

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + doc.getOriginalFilename() + "\"")
                .body(resource);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteDocument(@PathVariable UUID id) {
        documentService.deleteDocument(id);
        return ResponseEntity.noContent().build();
    }
}
