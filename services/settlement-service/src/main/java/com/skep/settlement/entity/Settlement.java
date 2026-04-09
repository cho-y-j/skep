package com.skep.settlement.entity;

import lombok.*;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "settlements")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Settlement {

    @Id
    @Column(name = "id", columnDefinition = "UUID")
    private UUID id;

    @Column(name = "deployment_plan_id", nullable = false, columnDefinition = "UUID")
    private UUID deploymentPlanId;

    @Column(name = "supplier_id", nullable = false, columnDefinition = "UUID")
    private UUID supplierId;

    @Column(name = "bp_company_id", nullable = false, columnDefinition = "UUID")
    private UUID bpCompanyId;

    @Column(name = "year_month")
    private String yearMonth;

    @Column(name = "total_daily_amount", precision = 15, scale = 2)
    private BigDecimal totalDailyAmount;

    @Column(name = "total_overtime_amount", precision = 15, scale = 2)
    private BigDecimal totalOvertimeAmount;

    @Column(name = "total_early_morning_amount", precision = 15, scale = 2)
    private BigDecimal totalEarlyMorningAmount;

    @Column(name = "total_night_amount", precision = 15, scale = 2)
    private BigDecimal totalNightAmount;

    @Column(name = "total_overnight_amount", precision = 15, scale = 2)
    private BigDecimal totalOvernightAmount;

    @Column(name = "supply_amount", precision = 15, scale = 2)
    private BigDecimal supplyAmount;

    @Column(name = "tax_amount", precision = 15, scale = 2)
    private BigDecimal taxAmount;

    @Column(name = "total_amount", precision = 15, scale = 2)
    private BigDecimal totalAmount;

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private SettlementStatus status;

    @Column(name = "sent_at")
    private LocalDateTime sentAt;

    @Column(name = "paid_at")
    private LocalDateTime paidAt;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "settlement", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<SettlementDailyDetail> dailyDetails = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        this.id = UUID.randomUUID();
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        this.status = SettlementStatus.DRAFT;
        this.totalDailyAmount = BigDecimal.ZERO;
        this.totalOvertimeAmount = BigDecimal.ZERO;
        this.totalEarlyMorningAmount = BigDecimal.ZERO;
        this.totalNightAmount = BigDecimal.ZERO;
        this.totalOvernightAmount = BigDecimal.ZERO;
        this.supplyAmount = BigDecimal.ZERO;
        this.taxAmount = BigDecimal.ZERO;
        this.totalAmount = BigDecimal.ZERO;
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public enum SettlementStatus {
        DRAFT, SENT, PAID
    }

}
