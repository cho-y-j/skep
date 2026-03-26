package com.skep.equipmentservice.domain.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "equipment")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Equipment {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = true)
    private UUID supplierId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "equipment_type_id", nullable = false)
    private EquipmentType equipmentType;

    @Column(nullable = false, unique = true)
    private String vehicleNumber;

    @Column
    private String modelName;

    @Column
    private Integer manufactureYear;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EquipmentStatus status;

    @Column(unique = true)
    private String nfcTagId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PreInspectionStatus preInspectionStatus;

    @Column
    private LocalDate preInspectionDate;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;

    public enum EquipmentStatus {
        ACTIVE, MAINTENANCE, INACTIVE
    }

    public enum PreInspectionStatus {
        PENDING, PASSED, FAILED
    }
}
