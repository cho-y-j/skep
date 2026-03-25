package com.skep.dispatch.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "quotation_requests", indexes = {
    @Index(name = "idx_qr_site", columnList = "site_id"),
    @Index(name = "idx_qr_bp_company", columnList = "bp_company_id"),
    @Index(name = "idx_qr_status", columnList = "status")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class QuotationRequest implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private UUID siteId;

    @Column(nullable = false)
    private UUID bpCompanyId;

    private UUID requestedBy;

    @Column(length = 200)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    private LocalDate desiredStartDate;
    private LocalDate desiredEndDate;

    @Column(length = 20)
    @Builder.Default
    private String status = "PENDING"; // PENDING, QUOTED, ACCEPTED, REJECTED, CANCELLED

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
