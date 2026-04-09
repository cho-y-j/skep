package com.skep.settlement.controller;

import com.skep.settlement.dto.*;
import com.skep.settlement.service.SettlementService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/settlement")
@RequiredArgsConstructor
@Slf4j
public class SettlementController {

    private final SettlementService settlementService;

    @PostMapping("/generate")
    public ResponseEntity<SettlementResponse> generateSettlement(@RequestBody SettlementRequest request) {
        log.info("Generating settlement: {}", request);
        SettlementResponse response = settlementService.generateSettlement(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<Page<SettlementResponse>> getSettlements(
            @RequestParam(required = false) UUID supplierId,
            @RequestParam(required = false) UUID bpCompanyId,
            @RequestParam(required = false) String yearMonth,
            Pageable pageable) {
        log.info("Fetching settlements - supplier: {}, bp: {}, period: {}", supplierId, bpCompanyId, yearMonth);
        Page<SettlementResponse> page = settlementService.getSettlements(supplierId, bpCompanyId, yearMonth, pageable);
        return ResponseEntity.ok(page);
    }

    @GetMapping("/{id}")
    public ResponseEntity<SettlementResponse> getSettlement(@PathVariable UUID id) {
        log.info("Fetching settlement: {}", id);
        SettlementResponse response = settlementService.getSettlement(id);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{id}/send")
    public ResponseEntity<Map<String, String>> sendSettlement(
            @PathVariable UUID id,
            @RequestParam String bpEmailAddress) {
        try {
            log.info("Sending settlement {} to {}", id, bpEmailAddress);
            settlementService.sendSettlement(id, bpEmailAddress);
            Map<String, String> response = new HashMap<>();
            response.put("message", "Settlement sent successfully");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error sending settlement", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                    Map.of("error", "Failed to send settlement: " + e.getMessage())
            );
        }
    }

    @PutMapping("/{id}/mark-paid")
    public ResponseEntity<SettlementResponse> markAsPaid(@PathVariable UUID id) {
        log.info("Marking settlement as paid: {}", id);
        settlementService.markAsPaid(id);
        SettlementResponse response = settlementService.getSettlement(id);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/statistics/supplier/{supplierId}")
    public ResponseEntity<SettlementStatisticsResponse> getSupplierStatistics(@PathVariable UUID supplierId) {
        log.info("Fetching supplier statistics: {}", supplierId);
        SettlementStatisticsResponse response = settlementService.getSupplierStatistics(supplierId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/statistics/bp/{bpId}")
    public ResponseEntity<SettlementStatisticsResponse> getBpStatistics(@PathVariable UUID bpId) {
        log.info("Fetching BP company statistics: {}", bpId);
        SettlementStatisticsResponse response = settlementService.getBpStatistics(bpId);
        return ResponseEntity.ok(response);
    }

}
