package com.skep.dispatch.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.UUID;

@Entity
@Table(name = "daily_work_confirmations", indexes = {
    @Index(name = "idx_daily_confirmations_record", columnList = "work_record_id"),
    @Index(name = "idx_daily_confirmations_status", columnList = "status")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyWorkConfirmation implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = true)
    private UUID workRecordId;

    @Column(length = 200)
    private String siteName;

    @Column(length = 200)
    private String companyName;

    @Column(length = 50)
    private String vehicleNumber;

    @Column(length = 100)
    private String driverName;

    @Column(length = 200)
    private String equipmentName;

    @Column(columnDefinition = "TEXT")
    private String workContent;

    @Column(length = 200)
    private String workLocation;

    @Column(length = 100)
    private String specification;

    @Column(length = 20)
    private String workType;

    private LocalTime workStartTime;
    private LocalTime workEndTime;

    private BigDecimal overtimeHours;
    private BigDecimal overnightHours;

    @Column(columnDefinition = "TEXT")
    private String extensionNotes;

    private UUID bpSignedBy;
    private LocalDateTime bpSignedAt;

    @Column(length = 20)
    @Builder.Default
    private String status = "PENDING_SIGNATURE";

    @CreationTimestamp
    @Column(nullable = true, updatable = false)
    private LocalDateTime createdAt;
}
