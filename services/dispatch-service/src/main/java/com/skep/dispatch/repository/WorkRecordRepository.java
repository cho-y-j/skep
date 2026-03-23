package com.skep.dispatch.repository;

import com.skep.dispatch.domain.WorkRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface WorkRecordRepository extends JpaRepository<WorkRecord, UUID> {
    List<WorkRecord> findByDailyRosterId(UUID dailyRosterId);
    List<WorkRecord> findByWorkerId(UUID workerId);

    @Query("SELECT w FROM WorkRecord w WHERE w.workerId = :workerId AND DATE(w.createdAt) = :date")
    List<WorkRecord> findByWorkerAndDate(@Param("workerId") UUID workerId, @Param("date") LocalDate date);

    @Query("SELECT w FROM WorkRecord w WHERE w.dailyRosterId = :rosterId AND w.workerId = :workerId")
    List<WorkRecord> findByRosterAndWorker(@Param("rosterId") UUID rosterId, @Param("workerId") UUID workerId);

    @Query("SELECT w FROM WorkRecord w WHERE w.workerId = :workerId AND w.workStartAt BETWEEN :startTime AND :endTime")
    List<WorkRecord> findByWorkerAndTimeRange(@Param("workerId") UUID workerId, @Param("startTime") LocalDateTime startTime, @Param("endTime") LocalDateTime endTime);
}
