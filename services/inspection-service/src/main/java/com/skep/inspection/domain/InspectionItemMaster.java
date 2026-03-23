package com.skep.inspection.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "inspection_item_masters", indexes = {
    @Index(name = "idx_inspection_item_masters_equipment_type", columnList = "equipment_type_id")
}, uniqueConstraints = {
    @UniqueConstraint(name = "idx_inspection_items_unique", columnNames = {"equipment_type_id", "item_number"})
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InspectionItemMaster implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = true)
    private UUID equipmentTypeId;

    @Column(nullable = true)
    private Integer itemNumber;

    @Column(nullable = true, length = 200)
    private String itemName;

    @Column(nullable = true, columnDefinition = "TEXT")
    private String inspectionMethod;

    @Builder.Default
    private Boolean requiresPhoto = true;

    @Builder.Default
    private Boolean isActive = true;

    private Integer sortOrder;

    @CreationTimestamp
    @Column(nullable = true, updatable = false)
    private LocalDateTime createdAt;
}
