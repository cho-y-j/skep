package com.skep.documentservice.controller;

import com.skep.documentservice.domain.entity.DocumentType;
import com.skep.documentservice.repository.DocumentTypeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/documents/types")
@RequiredArgsConstructor
public class DocumentTypeController {

    private final DocumentTypeRepository repository;

    @PostMapping
    public ResponseEntity<DocumentType> create(@RequestBody Map<String, Object> body) {
        DocumentType type = DocumentType.builder()
                .name((String) body.get("name"))
                .description((String) body.getOrDefault("description", ""))
                .requiresOcr((Boolean) body.getOrDefault("requiresOcr", false))
                .requiresVerification((Boolean) body.getOrDefault("requiresVerification", false))
                .hasExpiry((Boolean) body.getOrDefault("hasExpiry", false))
                .build();
        return ResponseEntity.status(HttpStatus.CREATED).body(repository.save(type));
    }

    @PutMapping("/{id}")
    public ResponseEntity<DocumentType> update(@PathVariable UUID id, @RequestBody Map<String, Object> body) {
        return repository.findById(id).map(existing -> {
            DocumentType updated = DocumentType.builder()
                    .id(existing.getId())
                    .name((String) body.getOrDefault("name", existing.getName()))
                    .description((String) body.getOrDefault("description", existing.getDescription()))
                    .requiresOcr((Boolean) body.getOrDefault("requiresOcr", existing.getRequiresOcr()))
                    .requiresVerification((Boolean) body.getOrDefault("requiresVerification", existing.getRequiresVerification()))
                    .hasExpiry((Boolean) body.getOrDefault("hasExpiry", existing.getHasExpiry()))
                    .createdAt(existing.getCreatedAt())
                    .build();
            return ResponseEntity.ok(repository.save(updated));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        if (repository.existsById(id)) {
            repository.deleteById(id);
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }
}
