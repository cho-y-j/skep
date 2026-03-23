package com.skep.dispatch.service;

import com.skep.dispatch.domain.DailyRoster;
import com.skep.dispatch.dto.CreateDailyRosterRequest;
import com.skep.dispatch.repository.DailyRosterRepository;
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
public class DailyRosterService {

    private final DailyRosterRepository dailyRosterRepository;

    public DailyRoster submitRoster(CreateDailyRosterRequest request) {
        DailyRoster roster = DailyRoster.builder()
            .deploymentPlanId(request.getDeploymentPlanId())
            .workDate(request.getWorkDate())
            .driverId(request.getDriverId())
            .guideIds(request.getGuideIds())
            .submittedBy(request.getSubmittedBy())
            .submittedAt(LocalDateTime.now())
            .status("PENDING")
            .notes(request.getNotes())
            .build();
        return dailyRosterRepository.save(roster);
    }

    @Transactional(readOnly = true)
    public DailyRoster getRosterById(UUID id) {
        return dailyRosterRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Daily roster not found: " + id));
    }

    @Transactional(readOnly = true)
    public List<DailyRoster> getRostersByPlan(UUID planId) {
        return dailyRosterRepository.findByDeploymentPlanId(planId);
    }

    @Transactional(readOnly = true)
    public List<DailyRoster> getRostersByDate(LocalDate workDate) {
        return dailyRosterRepository.findByWorkDate(workDate);
    }

    @Transactional(readOnly = true)
    public List<DailyRoster> getRostersByPlanAndDate(UUID planId, LocalDate workDate) {
        return dailyRosterRepository.findByPlanDateAndStatus(planId, workDate, "PENDING");
    }

    public DailyRoster approveRoster(UUID id, UUID approvedBy, String notes) {
        DailyRoster roster = getRosterById(id);
        roster.setApprovedBy(approvedBy);
        roster.setApprovedAt(LocalDateTime.now());
        roster.setStatus("APPROVED");
        if (notes != null) {
            roster.setNotes(notes);
        }
        return dailyRosterRepository.save(roster);
    }

    public DailyRoster rejectRoster(UUID id, String notes) {
        DailyRoster roster = getRosterById(id);
        roster.setStatus("REJECTED");
        if (notes != null) {
            roster.setNotes(notes);
        }
        return dailyRosterRepository.save(roster);
    }

    @Transactional(readOnly = true)
    public List<DailyRoster> getRostersByStatus(String status) {
        return dailyRosterRepository.findByStatus(status);
    }
}
