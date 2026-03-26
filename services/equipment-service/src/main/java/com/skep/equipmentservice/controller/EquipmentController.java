package com.skep.equipmentservice.controller;

import com.skep.equipmentservice.domain.dto.EquipmentRequest;
import com.skep.equipmentservice.domain.dto.EquipmentResponse;
import com.skep.equipmentservice.domain.dto.EquipmentStatusResponse;
import com.skep.equipmentservice.service.EquipmentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/equipment")
@RequiredArgsConstructor
public class EquipmentController {

    private final EquipmentService equipmentService;

    @PostMapping
    public ResponseEntity<EquipmentResponse> registerEquipment(@RequestBody EquipmentRequest request) {
        EquipmentResponse response = equipmentService.registerEquipment(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<List<EquipmentResponse>> getEquipmentList(
            @RequestParam(value = "supplier_id", required = false) UUID supplierId) {

        List<EquipmentResponse> equipments = equipmentService.getEquipmentList(supplierId);
        return ResponseEntity.ok(equipments);
    }

    @GetMapping("/{id}")
    public ResponseEntity<EquipmentResponse> getEquipmentById(@PathVariable UUID id) {
        EquipmentResponse equipment = equipmentService.getEquipmentById(id);
        return ResponseEntity.ok(equipment);
    }

    @PutMapping("/{id}")
    public ResponseEntity<EquipmentResponse> updateEquipment(
            @PathVariable UUID id,
            @RequestBody EquipmentRequest request) {

        EquipmentResponse response = equipmentService.updateEquipment(id, request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{id}/nfc")
    public ResponseEntity<Void> registerNfcTag(
            @PathVariable UUID id,
            @RequestParam("nfc_tag_id") String nfcTagId) {

        equipmentService.registerNfcTag(id, nfcTagId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/nfc/{tagId}")
    public ResponseEntity<EquipmentResponse> getEquipmentByNfcTag(@PathVariable String tagId) {
        EquipmentResponse equipment = equipmentService.getEquipmentByNfcTag(tagId);
        return ResponseEntity.ok(equipment);
    }

    @GetMapping("/{id}/status")
    public ResponseEntity<EquipmentStatusResponse> checkEquipmentStatus(@PathVariable UUID id) {
        EquipmentStatusResponse status = equipmentService.checkEquipmentStatus(id);
        return ResponseEntity.ok(status);
    }
}
