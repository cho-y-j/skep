package com.skep.dispatch.domain;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import io.hypersistence.utils.hibernate.type.json.JsonType;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "daily_rosters", indexes = {
    @Index(name = "idx_daily_rosters_plan", columnList = "deployment_plan_id"),
    @Index(name = "idx_daily_rosters_date", columnList = "work_date"),
    @Index(name = "idx_daily_rosters_status", columnList = "status")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyRoster implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = true)
    private UUID deploymentPlanId;

    @Column(nullable = true)
    private LocalDate workDate;

    @Column(nullable = true)
    private UUID driverId;

    @org.hibernate.annotations.Type(JsonType.class)
    @Column(columnDefinition = "jsonb")
    private JsonNode guideIds;

    private UUID submittedBy;
    private LocalDateTime submittedAt;

    private UUID approvedBy;
    private LocalDateTime approvedAt;

    @Column(length = 20)
    @Builder.Default
    private String status = "PENDING";

    @Column(columnDefinition = "TEXT")
    private String notes;

    @CreationTimestamp
    @Column(nullable = true, updatable = false)
    private LocalDateTime createdAt;
}
