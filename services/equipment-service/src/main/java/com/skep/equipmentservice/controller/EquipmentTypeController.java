package com.skep.equipmentservice.controller;

import com.skep.equipmentservice.domain.entity.EquipmentType;
import com.skep.equipmentservice.repository.EquipmentTypeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/equipment/types")
@RequiredArgsConstructor
public class EquipmentTypeController {

    private final EquipmentTypeRepository repository;

    @GetMapping
    public ResponseEntity<List<EquipmentType>> getAll() {
        return ResponseEntity.ok(repository.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<EquipmentType> getById(@PathVariable UUID id) {
        return repository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<EquipmentType> create(@RequestBody Map<String, Object> body) {
        EquipmentType type = EquipmentType.builder()
                .name((String) body.get("name"))
                .description((String) body.getOrDefault("description", ""))
                .build();
        return ResponseEntity.status(HttpStatus.CREATED).body(repository.save(type));
    }

    @PutMapping("/{id}")
    public ResponseEntity<EquipmentType> update(@PathVariable UUID id, @RequestBody Map<String, Object> body) {
        return repository.findById(id).map(existing -> {
            EquipmentType updated = EquipmentType.builder()
                    .id(existing.getId())
                    .name((String) body.getOrDefault("name", existing.getName()))
                    .description((String) body.getOrDefault("description", existing.getDescription()))
                    .requiredDocuments(existing.getRequiredDocuments())
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
