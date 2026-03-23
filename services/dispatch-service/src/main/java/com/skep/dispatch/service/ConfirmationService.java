package com.skep.dispatch.service;

import com.skep.dispatch.domain.DailyWorkConfirmation;
import com.skep.dispatch.domain.MonthlyWorkConfirmation;
import com.skep.dispatch.domain.WorkRecord;
import com.skep.dispatch.dto.SignConfirmationRequest;
import com.skep.dispatch.repository.DailyWorkConfirmationRepository;
import com.skep.dispatch.repository.MonthlyWorkConfirmationRepository;
import com.skep.dispatch.repository.WorkRecordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class ConfirmationService {

    private final DailyWorkConfirmationRepository dailyWorkConfirmationRepository;
    private final MonthlyWorkConfirmationRepository monthlyWorkConfirmationRepository;
    private final WorkRecordRepository workRecordRepository;

    public DailyWorkConfirmation generateDailyConfirmation(UUID workRecordId) {
        WorkRecord record = workRecordRepository.findById(workRecordId)
            .orElseThrow(() -> new RuntimeException("Work record not found: " + workRecordId));

        DailyWorkConfirmation confirmation = DailyWorkConfirmation.builder()
            .workRecordId(workRecordId)
            .siteName(record.getWorkLocation())
            .driverName("")
            .equipmentName("")
            .workContent(record.getWorkContent())
            .workLocation(record.getWorkLocation())
            .workType(record.getWorkType())
            .workStartTime(record.getWorkStartAt() != null ? record.getWorkStartAt().toLocalTime() : null)
            .workEndTime(record.getWorkEndAt() != null ? record.getWorkEndAt().toLocalTime() : null)
            .status("PENDING_SIGNATURE")
            .build();

        return dailyWorkConfirmationRepository.save(confirmation);
    }

    public DailyWorkConfirmation signDailyConfirmation(UUID confirmationId, SignConfirmationRequest request) {
        DailyWorkConfirmation confirmation = dailyWorkConfirmationRepository.findById(confirmationId)
            .orElseThrow(() -> new RuntimeException("Daily confirmation not found: " + confirmationId));

        confirmation.setBpSignedBy(request.getSignedBy());
        confirmation.setBpSignedAt(LocalDateTime.now());
        confirmation.setStatus("SIGNED");

        return dailyWorkConfirmationRepository.save(confirmation);
    }

    public MonthlyWorkConfirmation generateMonthlyConfirmation(UUID planId, String yearMonth) {
        MonthlyWorkConfirmation confirmation = MonthlyWorkConfirmation.builder()
            .deploymentPlanId(planId)
            .yearMonth(yearMonth)
            .status("DRAFT")
            .build();

        return monthlyWorkConfirmationRepository.save(confirmation);
    }

    @Transactional(readOnly = true)
    public MonthlyWorkConfirmation getMonthlyConfirmation(UUID planId, String yearMonth) {
        return monthlyWorkConfirmationRepository.findByPlanAndYearMonth(planId, yearMonth)
            .orElseThrow(() -> new RuntimeException("Monthly confirmation not found for plan: " + planId + ", period: " + yearMonth));
    }

    public MonthlyWorkConfirmation signMonthlyConfirmation(UUID confirmationId, SignConfirmationRequest request) {
        MonthlyWorkConfirmation confirmation = monthlyWorkConfirmationRepository.findById(confirmationId)
            .orElseThrow(() -> new RuntimeException("Monthly confirmation not found: " + confirmationId));

        confirmation.setBpSignedBy(request.getSignedBy());
        confirmation.setBpSignedAt(LocalDateTime.now());
        confirmation.setStatus("SIGNED");

        return monthlyWorkConfirmationRepository.save(confirmation);
    }

    public MonthlyWorkConfirmation markAsSent(UUID confirmationId) {
        MonthlyWorkConfirmation confirmation = monthlyWorkConfirmationRepository.findById(confirmationId)
            .orElseThrow(() -> new RuntimeException("Monthly confirmation not found: " + confirmationId));

        confirmation.setSiteOwnerSentAt(LocalDateTime.now());
        confirmation.setStatus("SENT");

        return monthlyWorkConfirmationRepository.save(confirmation);
    }

    @Transactional(readOnly = true)
    public List<DailyWorkConfirmation> getDailyConfirmationsByStatus(String status) {
        return dailyWorkConfirmationRepository.findByStatus(status);
    }

    @Transactional(readOnly = true)
    public List<MonthlyWorkConfirmation> getMonthlyConfirmationsByPlan(UUID planId) {
        return monthlyWorkConfirmationRepository.findByDeploymentPlanId(planId);
    }

    @Transactional(readOnly = true)
    public DailyWorkConfirmation getDailyConfirmation(UUID id) {
        return dailyWorkConfirmationRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Daily confirmation not found: " + id));
    }
}
