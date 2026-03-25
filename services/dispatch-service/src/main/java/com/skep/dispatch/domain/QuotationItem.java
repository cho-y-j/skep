package com.skep.dispatch.domain;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "quotation_items")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class QuotationItem implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "quotation_id", nullable = false)
    @JsonIgnore
    private Quotation quotation;

    @Column(length = 100)
    private String equipmentTypeName;

    private UUID equipmentTypeId;

    @Builder.Default
    private Integer quantity = 1;

    // 단가 체계 (deployment_plans와 동일)
    @Column(precision = 12, scale = 2)
    private BigDecimal rateDaily;

    @Column(precision = 12, scale = 2)
    private BigDecimal rateOvertime;

    @Column(precision = 12, scale = 2)
    private BigDecimal rateNight;

    @Column(precision = 12, scale = 2)
    private BigDecimal rateMonthly;

    // 인건비 포함/별도
    @Builder.Default
    private Boolean laborIncluded = true;

    @Column(precision = 12, scale = 2)
    private BigDecimal laborCostDaily; // 별도일 때 기사 일당

    @Column(precision = 12, scale = 2)
    private BigDecimal guideCostDaily; // 별도일 때 유도원 일당

    @Column(columnDefinition = "TEXT")
    private String notes;
}
