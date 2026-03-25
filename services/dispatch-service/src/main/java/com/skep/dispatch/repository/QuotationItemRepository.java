package com.skep.dispatch.repository;

import com.skep.dispatch.domain.QuotationItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface QuotationItemRepository extends JpaRepository<QuotationItem, UUID> {
    List<QuotationItem> findByQuotationId(UUID quotationId);
}
