package com.skep.dispatch.controller;

import com.skep.dispatch.domain.DeploymentChecklist;
import com.skep.dispatch.repository.DeploymentChecklistRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/dispatch/checklists")
@RequiredArgsConstructor
public class ChecklistController {

    private final DeploymentChecklistRepository checklistRepository;

    @GetMapping("/plan/{planId}")
    public ResponseEntity<List<DeploymentChecklist>> getChecklistsByPlan(@PathVariable UUID planId) {
        List<DeploymentChecklist> checklists = checklistRepository.findByDeploymentPlanId(planId);
        return ResponseEntity.ok(checklists);
    }

    @PutMapping("/{id}/update")
    public ResponseEntity<DeploymentChecklist> updateChecklist(
        @PathVariable UUID id,
        @RequestBody DeploymentChecklist request
    ) {
        DeploymentChecklist checklist = checklistRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Checklist not found: " + id));

        if (request.getQuotationConfirmed() != null) checklist.setQuotationConfirmed(request.getQuotationConfirmed());
        if (request.getDocumentsVerified() != null) checklist.setDocumentsVerified(request.getDocumentsVerified());
        if (request.getLicenseVerified() != null) checklist.setLicenseVerified(request.getLicenseVerified());
        if (request.getSafetyInspectionPassed() != null) checklist.setSafetyInspectionPassed(request.getSafetyInspectionPassed());
        if (request.getHealthCheckCompleted() != null) checklist.setHealthCheckCompleted(request.getHealthCheckCompleted());
        if (request.getPersonnelAssigned() != null) checklist.setPersonnelAssigned(request.getPersonnelAssigned());
        if (request.getEquipmentAssigned() != null) checklist.setEquipmentAssigned(request.getEquipmentAssigned());

        // Auto-compute overall status
        boolean allPassed = Boolean.TRUE.equals(checklist.getQuotationConfirmed())
            && Boolean.TRUE.equals(checklist.getDocumentsVerified())
            && Boolean.TRUE.equals(checklist.getLicenseVerified())
            && Boolean.TRUE.equals(checklist.getSafetyInspectionPassed())
            && Boolean.TRUE.equals(checklist.getHealthCheckCompleted())
            && Boolean.TRUE.equals(checklist.getPersonnelAssigned())
            && Boolean.TRUE.equals(checklist.getEquipmentAssigned());

        if (allPassed) {
            checklist.setOverallStatus("PASSED");
        }

        checklist.setUpdatedAt(LocalDateTime.now());
        DeploymentChecklist saved = checklistRepository.save(checklist);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/{id}/override")
    public ResponseEntity<DeploymentChecklist> overrideChecklist(
        @PathVariable UUID id,
        @RequestBody DeploymentChecklist request
    ) {
        DeploymentChecklist checklist = checklistRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Checklist not found: " + id));

        checklist.setOverallStatus("OVERRIDDEN");
        checklist.setOverriddenBy(request.getOverriddenBy());
        checklist.setOverriddenAt(LocalDateTime.now());
        checklist.setOverrideReason(request.getOverrideReason());
        checklist.setUpdatedAt(LocalDateTime.now());

        DeploymentChecklist saved = checklistRepository.save(checklist);
        return ResponseEntity.ok(saved);
    }
}
