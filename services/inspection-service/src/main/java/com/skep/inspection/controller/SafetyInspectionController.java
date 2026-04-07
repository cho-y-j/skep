package com.skep.inspection.controller;

import com.skep.inspection.domain.InspectionItemResult;
import com.skep.inspection.domain.SafetyInspection;
import com.skep.inspection.dto.RecordItemRequest;
import com.skep.inspection.dto.StartSafetyInspectionRequest;
import com.skep.inspection.service.SafetyInspectionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/inspection/safety")
@RequiredArgsConstructor
public class SafetyInspectionController {

    private final SafetyInspectionService safetyInspectionService;

    @GetMapping
    public ResponseEntity<java.util.List<SafetyInspection>> getAllInspections() {
        return ResponseEntity.ok(safetyInspectionService.getAllInspections());
    }

    @PostMapping("/start")
    public ResponseEntity<SafetyInspection> startInspection(@RequestBody StartSafetyInspectionRequest request) {
        SafetyInspection inspection = safetyInspectionService.startInspection(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(inspection);
    }

    @PostMapping("/{id}/record-item")
    public ResponseEntity<InspectionItemResult> recordItem(
        @PathVariable UUID id,
        @RequestBody RecordItemRequest request
    ) {
        InspectionItemResult result = safetyInspectionService.recordItem(id, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(result);
    }

    @PostMapping("/{id}/complete")
    public ResponseEntity<SafetyInspection> completeInspection(@PathVariable UUID id) {
        SafetyInspection inspection = safetyInspectionService.completeInspection(id);
        return ResponseEntity.ok(inspection);
    }

    @PostMapping("/{id}/fail")
    public ResponseEntity<SafetyInspection> failInspection(
        @PathVariable UUID id,
        @RequestParam(required = false) String notes
    ) {
        SafetyInspection inspection = safetyInspectionService.failInspection(id, notes);
        return ResponseEntity.ok(inspection);
    }

    @GetMapping("/{id}")
    public ResponseEntity<SafetyInspection> getInspection(@PathVariable UUID id) {
        SafetyInspection inspection = safetyInspectionService.getInspectionById(id);
        return ResponseEntity.ok(inspection);
    }

    @GetMapping("/{id}/items")
    public ResponseEntity<List<InspectionItemResult>> getInspectionItems(@PathVariable UUID id) {
        List<InspectionItemResult> items = safetyInspectionService.getInspectionItems(id);
        return ResponseEntity.ok(items);
    }

    @GetMapping("/equipment/{equipmentId}")
    public ResponseEntity<List<SafetyInspection>> getInspectionsByEquipment(@PathVariable UUID equipmentId) {
        List<SafetyInspection> inspections = safetyInspectionService.getInspectionsByEquipment(equipmentId);
        return ResponseEntity.ok(inspections);
    }
}
