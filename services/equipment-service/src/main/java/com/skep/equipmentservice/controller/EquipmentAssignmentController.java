package com.skep.equipmentservice.controller;

import com.skep.equipmentservice.domain.dto.EquipmentAssignmentRequest;
import com.skep.equipmentservice.domain.dto.EquipmentAssignmentResponse;
import com.skep.equipmentservice.service.EquipmentAssignmentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/equipment")
@RequiredArgsConstructor
public class EquipmentAssignmentController {

    private final EquipmentAssignmentService equipmentAssignmentService;

    @PostMapping("/{id}/assign")
    public ResponseEntity<EquipmentAssignmentResponse> assignEquipment(
            @PathVariable UUID id,
            @RequestBody EquipmentAssignmentRequest request) {

        request = EquipmentAssignmentRequest.builder()
                .equipmentId(id)
                .driverId(request.getDriverId())
                .guideIds(request.getGuideIds())
                .assignedFrom(request.getAssignedFrom())
                .assignedUntil(request.getAssignedUntil())
                .build();

        EquipmentAssignmentResponse response = equipmentAssignmentService.assignEquipmentToDriver(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}/current-assignment")
    public ResponseEntity<EquipmentAssignmentResponse> getCurrentAssignment(@PathVariable UUID id) {
        EquipmentAssignmentResponse response = equipmentAssignmentService.getCurrentAssignment(id);
        return ResponseEntity.ok(response);
    }
}
