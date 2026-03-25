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
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "sites", indexes = {
    @Index(name = "idx_sites_bp_company", columnList = "bp_company_id"),
    @Index(name = "idx_sites_status", columnList = "status")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Site implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(length = 500)
    private String address;

    @Column(nullable = false)
    private UUID bpCompanyId;

    private UUID createdBy;

    // 지도 범위 - 폴리곤 또는 원형
    @Column(length = 20)
    @Builder.Default
    private String boundaryType = "POLYGON"; // POLYGON or CIRCLE

    // 폴리곤: GeoJSON 형태로 저장
    @Column(columnDefinition = "TEXT")
    private String boundaryCoordinates;

    // 원형: 중심점 + 반경
    @Column(precision = 10, scale = 8)
    private BigDecimal centerLat;

    @Column(precision = 11, scale = 8)
    private BigDecimal centerLng;

    private Integer radiusMeters;

    @Column(length = 20)
    @Builder.Default
    private String status = "ACTIVE"; // ACTIVE, INACTIVE, COMPLETED

    @Column(columnDefinition = "TEXT")
    private String description;

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
