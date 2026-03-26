package com.skep.dispatch.service;

import com.skep.dispatch.domain.Quotation;
import com.skep.dispatch.domain.QuotationRequest;
import com.skep.dispatch.repository.QuotationRepository;
import com.skep.dispatch.repository.QuotationRequestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class QuotationService {

    private final QuotationRequestRepository quotationRequestRepository;
    private final QuotationRepository quotationRepository;

    // ===== Quotation Requests =====

    public QuotationRequest createRequest(QuotationRequest request) {
        request.setStatus("PENDING");
        return quotationRequestRepository.save(request);
    }

    @Transactional(readOnly = true)
    public List<QuotationRequest> getRequests() {
        return quotationRequestRepository.findAll();
    }

    @Transactional(readOnly = true)
    public QuotationRequest getRequestById(UUID id) {
        return quotationRequestRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Quotation request not found: " + id));
    }

    @Transactional(readOnly = true)
    public List<QuotationRequest> getRequestsByBpCompany(UUID bpCompanyId) {
        return quotationRequestRepository.findByBpCompanyId(bpCompanyId);
    }

    // ===== Quotations =====

    public Quotation createQuotation(Quotation quotation) {
        getRequestById(quotation.getRequestId());
        quotation.setStatus("DRAFT");
        if (quotation.getItems() != null) {
            for (var item : quotation.getItems()) {
                item.setQuotation(quotation);
            }
        }
        return quotationRepository.save(quotation);
    }

    @Transactional(readOnly = true)
    public List<Quotation> getQuotationsByRequest(UUID requestId) {
        return quotationRepository.findByRequestIdWithItems(requestId);
    }

    public Quotation submitQuotation(UUID id) {
        Quotation quotation = getQuotationById(id);
        if (!"DRAFT".equals(quotation.getStatus())) {
            throw new RuntimeException("Only DRAFT quotations can be submitted. Current status: " + quotation.getStatus());
        }
        quotation.setStatus("SUBMITTED");

        // Update request status to QUOTED
        QuotationRequest request = getRequestById(quotation.getRequestId());
        request.setStatus("QUOTED");
        quotationRequestRepository.save(request);

        return quotationRepository.save(quotation);
    }

    public Quotation acceptQuotation(UUID id) {
        Quotation quotation = getQuotationById(id);
        if (!"SUBMITTED".equals(quotation.getStatus())) {
            throw new RuntimeException("Only SUBMITTED quotations can be accepted. Current status: " + quotation.getStatus());
        }
        quotation.setStatus("ACCEPTED");

        // Update request status to ACCEPTED
        QuotationRequest request = getRequestById(quotation.getRequestId());
        request.setStatus("ACCEPTED");
        quotationRequestRepository.save(request);

        return quotationRepository.save(quotation);
    }

    public Quotation rejectQuotation(UUID id) {
        Quotation quotation = getQuotationById(id);
        if (!"SUBMITTED".equals(quotation.getStatus())) {
            throw new RuntimeException("Only SUBMITTED quotations can be rejected. Current status: " + quotation.getStatus());
        }
        quotation.setStatus("REJECTED");
        return quotationRepository.save(quotation);
    }

    @Transactional(readOnly = true)
    public Quotation getQuotationById(UUID id) {
        return quotationRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Quotation not found: " + id));
    }
}
