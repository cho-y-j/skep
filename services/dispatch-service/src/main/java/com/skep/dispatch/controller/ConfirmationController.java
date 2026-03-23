package com.skep.dispatch.controller;

import com.skep.dispatch.domain.DailyWorkConfirmation;
import com.skep.dispatch.domain.MonthlyWorkConfirmation;
import com.skep.dispatch.dto.SignConfirmationRequest;
import com.skep.dispatch.service.ConfirmationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/dispatch/confirmations")
@RequiredArgsConstructor
public class ConfirmationController {

    private final ConfirmationService confirmationService;

    // ===== Daily Work Confirmations =====
    @PostMapping("/daily/generate/{workRecordId}")
    public ResponseEntity<DailyWorkConfirmation> generateDailyConfirmation(@PathVariable UUID workRecordId) {
        DailyWorkConfirmation confirmation = confirmationService.generateDailyConfirmation(workRecordId);
        return ResponseEntity.status(HttpStatus.CREATED).body(confirmation);
    }

    @PostMapping("/daily/{id}/sign")
    public ResponseEntity<DailyWorkConfirmation> signDailyConfirmation(
        @PathVariable UUID id,
        @RequestBody SignConfirmationRequest request
    ) {
        DailyWorkConfirmation confirmation = confirmationService.signDailyConfirmation(id, request);
        return ResponseEntity.ok(confirmation);
    }

    @GetMapping("/daily")
    public ResponseEntity<List<DailyWorkConfirmation>> getDailyConfirmations(
        @RequestParam(defaultValue = "PENDING_SIGNATURE") String status
    ) {
        List<DailyWorkConfirmation> confirmations = confirmationService.getDailyConfirmationsByStatus(status);
        return ResponseEntity.ok(confirmations);
    }

    @GetMapping("/daily/{id}")
    public ResponseEntity<DailyWorkConfirmation> getDailyConfirmation(@PathVariable UUID id) {
        DailyWorkConfirmation confirmation = confirmationService.getDailyConfirmation(id);
        return ResponseEntity.ok(confirmation);
    }

    // ===== Monthly Work Confirmations =====
    @PostMapping("/monthly/{planId}/{yearMonth}/generate")
    public ResponseEntity<MonthlyWorkConfirmation> generateMonthlyConfirmation(
        @PathVariable UUID planId,
        @PathVariable String yearMonth
    ) {
        MonthlyWorkConfirmation confirmation = confirmationService.generateMonthlyConfirmation(planId, yearMonth);
        return ResponseEntity.status(HttpStatus.CREATED).body(confirmation);
    }

    @GetMapping("/monthly/{planId}/{yearMonth}")
    public ResponseEntity<MonthlyWorkConfirmation> getMonthlyConfirmation(
        @PathVariable UUID planId,
        @PathVariable String yearMonth
    ) {
        MonthlyWorkConfirmation confirmation = confirmationService.getMonthlyConfirmation(planId, yearMonth);
        return ResponseEntity.ok(confirmation);
    }

    @PostMapping("/monthly/{id}/sign")
    public ResponseEntity<MonthlyWorkConfirmation> signMonthlyConfirmation(
        @PathVariable UUID id,
        @RequestBody SignConfirmationRequest request
    ) {
        MonthlyWorkConfirmation confirmation = confirmationService.signMonthlyConfirmation(id, request);
        return ResponseEntity.ok(confirmation);
    }

    @PostMapping("/monthly/{id}/send")
    public ResponseEntity<MonthlyWorkConfirmation> sendMonthlyConfirmation(@PathVariable UUID id) {
        MonthlyWorkConfirmation confirmation = confirmationService.markAsSent(id);
        return ResponseEntity.ok(confirmation);
    }

    @GetMapping("/monthly/plan/{planId}")
    public ResponseEntity<List<MonthlyWorkConfirmation>> getMonthlyConfirmationsByPlan(@PathVariable UUID planId) {
        List<MonthlyWorkConfirmation> confirmations = confirmationService.getMonthlyConfirmationsByPlan(planId);
        return ResponseEntity.ok(confirmations);
    }
}
