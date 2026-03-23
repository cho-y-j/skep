package com.skep.inspection.controller;

import com.skep.inspection.domain.MaintenanceInspection;
import com.skep.inspection.dto.CreateMaintenanceInspectionRequest;
import com.skep.inspection.service.MaintenanceInspectionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/inspection/maintenance")
@RequiredArgsConstructor
public class MaintenanceInspectionController {

    private final MaintenanceInspectionService maintenanceInspectionService;

    @PostMapping
    public ResponseEntity<MaintenanceInspection> createInspection(@RequestBody CreateMaintenanceInspectionRequest request) {
        MaintenanceInspection inspection = maintenanceInspectionService.createInspection(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(inspection);
    }

    @GetMapping("/{id}")
    public ResponseEntity<MaintenanceInspection> getInspection(@PathVariable UUID id) {
        MaintenanceInspection inspection = maintenanceInspectionService.getInspectionById(id);
        return ResponseEntity.ok(inspection);
    }

    @GetMapping("/equipment/{equipmentId}")
    public ResponseEntity<List<MaintenanceInspection>> getInspectionsByEquipment(@PathVariable UUID equipmentId) {
        List<MaintenanceInspection> inspections = maintenanceInspectionService.getInspectionsByEquipment(equipmentId);
        return ResponseEntity.ok(inspections);
    }

    @GetMapping("/driver/{driverId}")
    public ResponseEntity<List<MaintenanceInspection>> getInspectionsByDriver(@PathVariable UUID driverId) {
        List<MaintenanceInspection> inspections = maintenanceInspectionService.getInspectionsByDriver(driverId);
        return ResponseEntity.ok(inspections);
    }

    @PutMapping("/{id}")
    public ResponseEntity<MaintenanceInspection> updateInspection(
        @PathVariable UUID id,
        @RequestBody CreateMaintenanceInspectionRequest request
    ) {
        MaintenanceInspection inspection = maintenanceInspectionService.updateInspection(id, request);
        return ResponseEntity.ok(inspection);
    }
}
