package com.skep.location.entity;

import lombok.*;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "location_records")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LocationRecord {

    @Id
    @Column(name = "id", columnDefinition = "UUID")
    private UUID id;

    @Column(name = "worker_id", nullable = false, columnDefinition = "UUID")
    private UUID workerId;

    @Column(name = "equipment_id", columnDefinition = "UUID")
    private UUID equipmentId;

    @Column(name = "latitude", precision = 10, scale = 8, nullable = false)
    private BigDecimal latitude;

    @Column(name = "longitude", precision = 11, scale = 8, nullable = false)
    private BigDecimal longitude;

    @Column(name = "accuracy", precision = 6, scale = 2)
    private BigDecimal accuracy;

    @Column(name = "recorded_at")
    private LocalDateTime recordedAt;

    @PrePersist
    protected void onCreate() {
        this.id = UUID.randomUUID();
        this.recordedAt = LocalDateTime.now();
    }

}
