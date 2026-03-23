package com.skep.dispatch.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "monthly_work_confirmations", indexes = {
    @Index(name = "idx_monthly_confirmations_plan", columnList = "deployment_plan_id"),
    @Index(name = "idx_monthly_confirmations_period", columnList = "year_month")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MonthlyWorkConfirmation implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = true)
    private UUID deploymentPlanId;

    @Column(length = 7)
    private String yearMonth; // 2026-01

    private BigDecimal totalDailyHours;
    private BigDecimal totalOvertimeHours;
    private Integer totalEarlyMorningCount;
    private BigDecimal totalNightHours;
    private Integer totalOvernightCount;
    private BigDecimal totalAmount;

    private UUID bpSignedBy;
    private LocalDateTime bpSignedAt;
    private LocalDateTime siteOwnerSentAt;

    @Column(length = 20)
    @Builder.Default
    private String status = "DRAFT"; // DRAFT, SIGNED, SENT

    @CreationTimestamp
    @Column(nullable = true, updatable = false)
    private LocalDateTime createdAt;
}
