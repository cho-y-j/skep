package com.skep.dispatch.repository;

import com.skep.dispatch.domain.QuotationRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface QuotationRequestRepository extends JpaRepository<QuotationRequest, UUID> {
    List<QuotationRequest> findBySiteId(UUID siteId);
    List<QuotationRequest> findByBpCompanyId(UUID bpCompanyId);
    List<QuotationRequest> findByStatus(String status);
}
