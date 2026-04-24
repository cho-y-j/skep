package com.skep.dispatch.service;

import com.skep.dispatch.domain.DeploymentPlan;
import com.skep.dispatch.dto.CreateDeploymentPlanRequest;
import com.skep.dispatch.repository.DeploymentPlanRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class DeploymentPlanService {

    private final DeploymentPlanRepository deploymentPlanRepository;

    public DeploymentPlan createPlan(CreateDeploymentPlanRequest request) {
        DeploymentPlan plan = DeploymentPlan.builder()
            .supplierId(request.getSupplierId())
            .bpCompanyId(request.getBpCompanyId())
            .siteName(request.getSiteName())
            .equipmentId(request.getEquipmentId())
            .startDate(request.getStartDate())
            .startTime(request.getStartTime())
            .endDate(request.getEndDate())
            .endTime(request.getEndTime())
            .rateDaily(request.getRateDaily())
            .rateOvertime(request.getRateOvertime())
            .rateEarlyMorning(request.getRateEarlyMorning())
            .rateNight(request.getRateNight())
            .rateOvernight(request.getRateOvernight())
            .rateMonthly(request.getRateMonthly())
            .notes(request.getNotes())
            .status("ACTIVE")
            .build();
        return deploymentPlanRepository.save(plan);
    }

    @Transactional(readOnly = true)
    public List<DeploymentPlan> getAllPlans() {
        return deploymentPlanRepository.findAll();
    }

    @Transactional(readOnly = true)
    public DeploymentPlan getPlanById(UUID id) {
        return deploymentPlanRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Deployment plan not found: " + id));
    }

    @Transactional(readOnly = true)
    public List<DeploymentPlan> getPlansBySupplier(UUID supplierId) {
        return deploymentPlanRepository.findBySupplierId(supplierId);
    }

    @Transactional(readOnly = true)
    public List<DeploymentPlan> getPlansByStatus(String status) {
        return deploymentPlanRepository.findByStatus(status);
    }

    public DeploymentPlan updatePlanStatus(UUID id, String newStatus) {
        DeploymentPlan plan = getPlanById(id);
        plan.setStatus(newStatus);
        return deploymentPlanRepository.save(plan);
    }

    public DeploymentPlan updatePlanNotes(UUID id, String notes) {
        DeploymentPlan plan = getPlanById(id);
        plan.setNotes(notes);
        return deploymentPlanRepository.save(plan);
    }

    public void deletePlan(UUID id) {
        DeploymentPlan plan = getPlanById(id); // 없으면 EntityNotFoundException
        deploymentPlanRepository.delete(plan);
    }
}
