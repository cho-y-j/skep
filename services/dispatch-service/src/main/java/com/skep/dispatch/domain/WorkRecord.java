package com.skep.dispatch.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
// Point type replaced with String for web compatibility

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "work_records", indexes = {
    @Index(name = "idx_work_records_roster", columnList = "daily_roster_id"),
    @Index(name = "idx_work_records_worker", columnList = "worker_id"),
    @Index(name = "idx_work_records_created", columnList = "created_at")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkRecord implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = true)
    private UUID dailyRosterId;

    @Column(nullable = true)
    private UUID workerId;

    @Column(length = 20)
    private String workerType; // DRIVER, GUIDE

    private LocalDateTime clockInAt;

    @Column(length = 100)
    private String clockInLocation; // "lat,lng" format

    @Builder.Default
    private Boolean clockInVerified = false;

    private LocalDateTime workStartAt;
    private LocalDateTime workEndAt;

    @Column(length = 20)
    private String workType; // DAILY, MONTHLY, OVERTIME, NIGHT, OVERNIGHT, EARLY_MORNING

    @Column(columnDefinition = "TEXT")
    private String workContent;

    @Column(length = 200)
    private String workLocation;

    @CreationTimestamp
    @Column(nullable = true, updatable = false)
    private LocalDateTime createdAt;
}
