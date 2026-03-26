package com.skep.dispatch.service;

import com.skep.dispatch.domain.WorkRecord;
import com.skep.dispatch.dto.ClockInRequest;
import com.skep.dispatch.dto.WorkRecordRequest;
import com.skep.dispatch.repository.WorkRecordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class WorkRecordService {

    private final WorkRecordRepository workRecordRepository;
    public WorkRecord clockIn(ClockInRequest request) {
        String location = null;
        if (request.getGpsLat() != null && request.getGpsLng() != null) {
            location = request.getGpsLat() + "," + request.getGpsLng();
        }

        WorkRecord record = WorkRecord.builder()
            .dailyRosterId(request.getDailyRosterId())
            .workerId(request.getWorkerId())
            .workerType(request.getWorkerType() != null ? request.getWorkerType() : "DRIVER")
            .clockInAt(LocalDateTime.now())
            .clockInLocation(location)
            .clockInVerified(location != null)
            .build();

        return workRecordRepository.save(record);
    }

    public WorkRecord startWork(UUID recordId, WorkRecordRequest request) {
        WorkRecord record = getWorkRecordById(recordId);
        record.setWorkStartAt(LocalDateTime.now());
        record.setWorkType(request.getWorkType());
        record.setWorkContent(request.getWorkContent());
        record.setWorkLocation(request.getWorkLocation());
        return workRecordRepository.save(record);
    }

    public WorkRecord endWork(UUID recordId) {
        WorkRecord record = getWorkRecordById(recordId);
        record.setWorkEndAt(LocalDateTime.now());
        return workRecordRepository.save(record);
    }

    @Transactional(readOnly = true)
    public WorkRecord getWorkRecordById(UUID id) {
        return workRecordRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Work record not found: " + id));
    }

    @Transactional(readOnly = true)
    public List<WorkRecord> getWorkRecordsByRoster(UUID rosterId) {
        return workRecordRepository.findByDailyRosterId(rosterId);
    }

    @Transactional(readOnly = true)
    public List<WorkRecord> getTodayWorkRecords(UUID workerId) {
        LocalDate today = LocalDate.now();
        return workRecordRepository.findByWorkerAndDate(workerId, today);
    }

    @Transactional(readOnly = true)
    public List<WorkRecord> getWorkRecordsByWorker(UUID workerId) {
        return workRecordRepository.findByWorkerId(workerId);
    }

    @Transactional(readOnly = true)
    public List<WorkRecord> getWorkRecordsByRosterAndWorker(UUID rosterId, UUID workerId) {
        return workRecordRepository.findByRosterAndWorker(rosterId, workerId);
    }
}
