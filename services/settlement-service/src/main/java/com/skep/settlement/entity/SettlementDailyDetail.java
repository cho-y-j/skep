package com.skep.settlement.entity;

import lombok.*;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "settlement_daily_details")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SettlementDailyDetail {

    @Id
    @Column(name = "id", columnDefinition = "UUID")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "settlement_id", nullable = false)
    private Settlement settlement;

    @Column(name = "work_date")
    private LocalDate workDate;

    @Column(name = "is_daily_work")
    private Boolean isDailyWork;

    @Column(name = "daily_amount", precision = 12, scale = 2)
    private BigDecimal dailyAmount;

    @Column(name = "overtime_hours", precision = 4, scale = 2)
    private BigDecimal overtimeHours;

    @Column(name = "overtime_amount", precision = 12, scale = 2)
    private BigDecimal overtimeAmount;

    @Column(name = "early_morning_count")
    private Integer earlyMorningCount;

    @Column(name = "early_morning_amount", precision = 12, scale = 2)
    private BigDecimal earlyMorningAmount;

    @Column(name = "night_hours", precision = 4, scale = 2)
    private BigDecimal nightHours;

    @Column(name = "night_amount", precision = 12, scale = 2)
    private BigDecimal nightAmount;

    @Column(name = "is_overnight")
    private Boolean isOvernight;

    @Column(name = "overnight_amount", precision = 12, scale = 2)
    private BigDecimal overnightAmount;

    @Column(name = "day_total", precision = 12, scale = 2)
    private BigDecimal dayTotal;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.id = UUID.randomUUID();
        this.createdAt = LocalDateTime.now();
        this.isDailyWork = this.isDailyWork != null && this.isDailyWork;
        this.isOvernight = this.isOvernight != null && this.isOvernight;
        this.dailyAmount = this.dailyAmount != null ? this.dailyAmount : BigDecimal.ZERO;
        this.overtimeHours = this.overtimeHours != null ? this.overtimeHours : BigDecimal.ZERO;
        this.overtimeAmount = this.overtimeAmount != null ? this.overtimeAmount : BigDecimal.ZERO;
        this.earlyMorningCount = this.earlyMorningCount != null ? this.earlyMorningCount : 0;
        this.earlyMorningAmount = this.earlyMorningAmount != null ? this.earlyMorningAmount : BigDecimal.ZERO;
        this.nightHours = this.nightHours != null ? this.nightHours : BigDecimal.ZERO;
        this.nightAmount = this.nightAmount != null ? this.nightAmount : BigDecimal.ZERO;
        this.overnightAmount = this.overnightAmount != null ? this.overnightAmount : BigDecimal.ZERO;
        calculateDayTotal();
    }

    public void calculateDayTotal() {
        BigDecimal total = BigDecimal.ZERO;
        if (this.dailyAmount != null) total = total.add(this.dailyAmount);
        if (this.overtimeAmount != null) total = total.add(this.overtimeAmount);
        if (this.earlyMorningAmount != null) total = total.add(this.earlyMorningAmount);
        if (this.nightAmount != null) total = total.add(this.nightAmount);
        if (this.overnightAmount != null) total = total.add(this.overnightAmount);
        this.dayTotal = total;
    }

}
