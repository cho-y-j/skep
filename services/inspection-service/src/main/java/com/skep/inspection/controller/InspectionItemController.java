package com.skep.inspection.controller;

import com.skep.inspection.domain.InspectionItemMaster;
import com.skep.inspection.dto.CreateInspectionItemRequest;
import com.skep.inspection.service.InspectionItemMasterService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/inspection/items")
@RequiredArgsConstructor
public class InspectionItemController {

    private final InspectionItemMasterService inspectionItemMasterService;

    @GetMapping("/equipment-type/{equipmentTypeId}")
    public ResponseEntity<List<InspectionItemMaster>> getItemsByEquipmentType(@PathVariable UUID equipmentTypeId) {
        List<InspectionItemMaster> items = inspectionItemMasterService.getItemsByEquipmentType(equipmentTypeId);
        return ResponseEntity.ok(items);
    }

    @GetMapping("/{id}")
    public ResponseEntity<InspectionItemMaster> getItem(@PathVariable UUID id) {
        InspectionItemMaster item = inspectionItemMasterService.getItemById(id);
        return ResponseEntity.ok(item);
    }

    @PostMapping("/equipment-type/{equipmentTypeId}")
    public ResponseEntity<InspectionItemMaster> createItem(
        @PathVariable UUID equipmentTypeId,
        @RequestBody CreateInspectionItemRequest request
    ) {
        InspectionItemMaster item = inspectionItemMasterService.createItem(equipmentTypeId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(item);
    }

    @PutMapping("/{id}")
    public ResponseEntity<InspectionItemMaster> updateItem(
        @PathVariable UUID id,
        @RequestBody CreateInspectionItemRequest request
    ) {
        InspectionItemMaster item = inspectionItemMasterService.updateItem(id, request);
        return ResponseEntity.ok(item);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deactivateItem(@PathVariable UUID id) {
        inspectionItemMasterService.deactivateItem(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/activate")
    public ResponseEntity<InspectionItemMaster> activateItem(@PathVariable UUID id) {
        inspectionItemMasterService.activateItem(id);
        InspectionItemMaster item = inspectionItemMasterService.getItemById(id);
        return ResponseEntity.ok(item);
    }

    @GetMapping("/all/equipment-type/{equipmentTypeId}")
    public ResponseEntity<List<InspectionItemMaster>> getAllItemsByEquipmentType(@PathVariable UUID equipmentTypeId) {
        List<InspectionItemMaster> items = inspectionItemMasterService.getAllItems(equipmentTypeId);
        return ResponseEntity.ok(items);
    }
}
