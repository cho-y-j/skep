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
@Table(name = "inspection_item_results", indexes = {
    @Index(name = "idx_inspection_item_results_inspection", columnList = "inspection_id"),
    @Index(name = "idx_inspection_item_results_master", columnList = "item_master_id")
}, uniqueConstraints = {
    @UniqueConstraint(name = "idx_inspection_results_unique", columnNames = {"inspection_id", "item_number"})
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InspectionItemResult implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = true)
    private UUID inspectionId;

    @Column(nullable = true)
    private UUID itemMasterId;

    @Column(nullable = true)
    private Integer itemNumber;

    @Column(length = 10)
    private String result; // OK, NG, NA

    @Column(length = 500)
    private String photoUrl;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @CreationTimestamp
    @Column(nullable = true, updatable = false)
    private LocalDateTime recordedAt;

    private Integer sequenceNumber;
}
