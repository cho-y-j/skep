package com.skep.dispatch.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.UUID;

@Entity
@Table(name = "deployment_plans", indexes = {
    @Index(name = "idx_deployment_plans_supplier", columnList = "supplier_id"),
    @Index(name = "idx_deployment_plans_equipment", columnList = "equipment_id"),
    @Index(name = "idx_deployment_plans_status", columnList = "status")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeploymentPlan implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = true)
    private UUID supplierId;

    @Column(nullable = true)
    private UUID bpCompanyId;

    @Column(nullable = true, length = 200)
    private String siteName;

    @Column(nullable = true)
    private UUID equipmentId;

    @Column(nullable = true)
    private LocalDate startDate;

    @Column(nullable = true)
    private LocalTime startTime;

    @Column(nullable = true)
    private LocalDate endDate;

    @Column(nullable = true)
    private LocalTime endTime;

    private BigDecimal rateDaily;
    private BigDecimal rateOvertime;
    private BigDecimal rateEarlyMorning;
    private BigDecimal rateNight;
    private BigDecimal rateOvernight;
    private BigDecimal rateMonthly;

    @Column(length = 20)
    @Builder.Default
    private String status = "ACTIVE";

    @Column(columnDefinition = "TEXT")
    private String notes;

    @CreationTimestamp
    @Column(nullable = true, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = true)
    private LocalDateTime updatedAt;
}
