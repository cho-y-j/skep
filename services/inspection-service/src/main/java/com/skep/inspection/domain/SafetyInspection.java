package com.skep.inspection.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "safety_inspections", indexes = {
    @Index(name = "idx_safety_inspections_equipment", columnList = "equipment_id"),
    @Index(name = "idx_safety_inspections_inspector", columnList = "inspector_id"),
    @Index(name = "idx_safety_inspections_date", columnList = "inspection_date"),
    @Index(name = "idx_safety_inspections_status", columnList = "status")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SafetyInspection implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = true)
    private UUID equipmentId;

    @Column(nullable = true)
    private UUID inspectorId;

    @Column(nullable = true)
    private LocalDate inspectionDate;

    private LocalDateTime startedAt;
    private LocalDateTime completedAt;

    @Column(precision = 10, scale = 8)
    private BigDecimal inspectorGpsLat;

    @Column(precision = 11, scale = 8)
    private BigDecimal inspectorGpsLng;

    @Column(precision = 10, scale = 8)
    private BigDecimal equipmentGpsLat;

    @Column(precision = 11, scale = 8)
    private BigDecimal equipmentGpsLng;

    @Column(precision = 8, scale = 2)
    private BigDecimal distanceMeters;

    @Column(length = 20)
    @Builder.Default
    private String status = "IN_PROGRESS"; // IN_PROGRESS, COMPLETED, FAILED

    @Column(columnDefinition = "TEXT")
    private String notes;

    @CreationTimestamp
    @Column(nullable = true, updatable = false)
    private LocalDateTime createdAt;
}
