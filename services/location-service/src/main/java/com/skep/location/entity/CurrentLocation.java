package com.skep.location.entity;

import lombok.*;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "current_locations")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CurrentLocation {

    @Id
    @Column(name = "worker_id", columnDefinition = "UUID")
    private UUID workerId;

    @Column(name = "equipment_id", columnDefinition = "UUID")
    private UUID equipmentId;

    @Column(name = "site_id", columnDefinition = "UUID")
    private UUID siteId;

    @Column(name = "worker_name")
    private String workerName;

    @Column(name = "equipment_name")
    private String equipmentName;

    @Column(name = "vehicle_number")
    private String vehicleNumber;

    @Column(name = "site_name")
    private String siteName;

    @Column(name = "latitude", precision = 10, scale = 8)
    private BigDecimal latitude;

    @Column(name = "longitude", precision = 11, scale = 8)
    private BigDecimal longitude;

    @Column(name = "last_updated")
    private LocalDateTime lastUpdated;

    @PrePersist
    @PreUpdate
    protected void onUpdate() {
        this.lastUpdated = LocalDateTime.now();
    }

}
