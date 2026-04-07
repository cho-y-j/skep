package com.skep.inspection.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "maintenance_inspections", indexes = {
    @Index(name = "idx_maintenance_inspections_equipment", columnList = "equipment_id"),
    @Index(name = "idx_maintenance_inspections_driver", columnList = "driver_id"),
    @Index(name = "idx_maintenance_inspections_date", columnList = "inspection_date")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MaintenanceInspection implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = true)
    private UUID equipmentId;

    @Column(nullable = true)
    private UUID driverId;

    @Column(nullable = true)
    private LocalDate inspectionDate;

    private Integer mileage;

    @Column(length = 20)
    private String engineOil; // NORMAL, NEED_REFILL, NEED_REPLACE

    @Column(length = 20)
    private String hydraulicOil;

    @Column(length = 20)
    private String coolant;

    private Integer fuelLevel; // percentage

    @Column(columnDefinition = "TEXT")
    private String notes;

    @CreationTimestamp
    @Column(nullable = true, updatable = false)
    private LocalDateTime recordedAt;
}
