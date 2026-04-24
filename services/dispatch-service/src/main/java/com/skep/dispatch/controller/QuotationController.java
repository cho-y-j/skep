package com.skep.dispatch.controller;

import com.skep.dispatch.domain.Quotation;
import com.skep.dispatch.domain.QuotationRequest;
import com.skep.dispatch.service.QuotationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/dispatch/quotations")
@RequiredArgsConstructor
public class QuotationController {

    private final QuotationService quotationService;

    // ===== Quotation Requests =====

    @PostMapping("/requests")
    public ResponseEntity<QuotationRequest> createRequest(@RequestBody QuotationRequest request) {
        QuotationRequest created = quotationService.createRequest(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @GetMapping("/requests")
    public ResponseEntity<List<QuotationRequest>> getRequests() {
        List<QuotationRequest> requests = quotationService.getRequests();
        return ResponseEntity.ok(requests);
    }

    @GetMapping("/requests/{id}")
    public ResponseEntity<QuotationRequest> getRequest(@PathVariable UUID id) {
        QuotationRequest request = quotationService.getRequestById(id);
        return ResponseEntity.ok(request);
    }

    @GetMapping("/requests/bp/{bpCompanyId}")
    public ResponseEntity<List<QuotationRequest>> getRequestsByBpCompany(@PathVariable UUID bpCompanyId) {
        List<QuotationRequest> requests = quotationService.getRequestsByBpCompany(bpCompanyId);
        return ResponseEntity.ok(requests);
    }

    // ===== Quotations =====

    @GetMapping
    public ResponseEntity<List<Quotation>> getAllQuotations() {
        return ResponseEntity.ok(quotationService.getAllQuotations());
    }

    @PostMapping
    public ResponseEntity<Quotation> createQuotation(@RequestBody Quotation quotation) {
        Quotation created = quotationService.createQuotation(quotation);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @GetMapping("/request/{requestId}")
    public ResponseEntity<List<Quotation>> getQuotationsByRequest(@PathVariable UUID requestId) {
        List<Quotation> quotations = quotationService.getQuotationsByRequest(requestId);
        return ResponseEntity.ok(quotations);
    }

    @PutMapping("/{id}/submit")
    public ResponseEntity<Quotation> submitQuotation(@PathVariable UUID id) {
        Quotation quotation = quotationService.submitQuotation(id);
        return ResponseEntity.ok(quotation);
    }

    @PutMapping("/{id}/accept")
    public ResponseEntity<Quotation> acceptQuotation(@PathVariable UUID id) {
        Quotation quotation = quotationService.acceptQuotation(id);
        return ResponseEntity.ok(quotation);
    }

    @PutMapping("/{id}/reject")
    public ResponseEntity<Quotation> rejectQuotation(@PathVariable UUID id) {
        Quotation quotation = quotationService.rejectQuotation(id);
        return ResponseEntity.ok(quotation);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Quotation> getQuotation(@PathVariable UUID id) {
        Quotation q = quotationService.getQuotationById(id);
        return ResponseEntity.ok(q);
    }

    // 견적 일반 수정 (DRAFT 상태일 때만)
    @PutMapping("/{id}")
    public ResponseEntity<Quotation> updateQuotation(
        @PathVariable UUID id,
        @RequestBody Quotation quotation
    ) {
        Quotation updated = quotationService.updateQuotation(id, quotation);
        return ResponseEntity.ok(updated);
    }
}
