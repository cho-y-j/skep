package com.skep.dispatch.domain;

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
@Table(name = "deployment_checklists", indexes = {
    @Index(name = "idx_checklist_plan", columnList = "deployment_plan_id"),
    @Index(name = "idx_checklist_status", columnList = "overall_status")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeploymentChecklist implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private UUID deploymentPlanId;

    // 각 항목 통과 여부
    @Builder.Default
    private Boolean quotationConfirmed = false;

    @Builder.Default
    private Boolean documentsVerified = false;

    @Builder.Default
    private Boolean licenseVerified = false;

    @Builder.Default
    private Boolean safetyInspectionPassed = false;

    @Builder.Default
    private Boolean healthCheckCompleted = false;

    @Builder.Default
    private Boolean personnelAssigned = false;

    @Builder.Default
    private Boolean equipmentAssigned = false;

    // 전체 상태
    @Column(length = 20)
    @Builder.Default
    private String overallStatus = "PENDING"; // PENDING, PASSED, OVERRIDDEN, FAILED

    // 오버라이드 정보
    private UUID overriddenBy;
    private LocalDateTime overriddenAt;

    @Column(columnDefinition = "TEXT")
    private String overrideReason;

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}
