package com.skep.dispatch.controller;

import com.skep.dispatch.domain.DailyRoster;
import com.skep.dispatch.domain.DeploymentPlan;
import com.skep.dispatch.domain.WorkRecord;
import com.skep.dispatch.dto.ClockInRequest;
import com.skep.dispatch.dto.CreateDailyRosterRequest;
import com.skep.dispatch.dto.CreateDeploymentPlanRequest;
import com.skep.dispatch.dto.RosterApprovalRequest;
import com.skep.dispatch.dto.WorkRecordRequest;
import com.skep.dispatch.service.DailyRosterService;
import com.skep.dispatch.service.DeploymentPlanService;
import com.skep.dispatch.service.WorkRecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/dispatch")
@RequiredArgsConstructor
public class DispatchController {

    private final DeploymentPlanService deploymentPlanService;
    private final DailyRosterService dailyRosterService;
    private final WorkRecordService workRecordService;

    // ===== Deployment Plans =====
    @PostMapping("/plans")
    public ResponseEntity<DeploymentPlan> createPlan(@RequestBody CreateDeploymentPlanRequest request) {
        DeploymentPlan plan = deploymentPlanService.createPlan(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(plan);
    }

    @GetMapping("/plans")
    public ResponseEntity<List<DeploymentPlan>> getAllPlans() {
        List<DeploymentPlan> plans = deploymentPlanService.getAllPlans();
        return ResponseEntity.ok(plans);
    }

    @GetMapping("/plans/{id}")
    public ResponseEntity<DeploymentPlan> getPlan(@PathVariable UUID id) {
        DeploymentPlan plan = deploymentPlanService.getPlanById(id);
        return ResponseEntity.ok(plan);
    }

    @PutMapping("/plans/{id}")
    public ResponseEntity<DeploymentPlan> updatePlan(
        @PathVariable UUID id,
        @RequestBody CreateDeploymentPlanRequest request
    ) {
        DeploymentPlan plan = deploymentPlanService.getPlanById(id);
        if (request.getNotes() != null) {
            plan = deploymentPlanService.updatePlanNotes(id, request.getNotes());
        }
        return ResponseEntity.ok(plan);
    }

    @GetMapping("/plans/supplier/{supplierId}")
    public ResponseEntity<List<DeploymentPlan>> getPlansBySupplier(@PathVariable UUID supplierId) {
        List<DeploymentPlan> plans = deploymentPlanService.getPlansBySupplier(supplierId);
        return ResponseEntity.ok(plans);
    }

    // ===== Daily Rosters =====
    @PostMapping("/rosters")
    public ResponseEntity<DailyRoster> submitRoster(@RequestBody CreateDailyRosterRequest request) {
        DailyRoster roster = dailyRosterService.submitRoster(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(roster);
    }

    @GetMapping("/rosters")
    public ResponseEntity<List<DailyRoster>> getRosters(
        @RequestParam(required = false) LocalDate date,
        @RequestParam(required = false) UUID planId
    ) {
        List<DailyRoster> rosters;
        if (date != null && planId != null) {
            rosters = dailyRosterService.getRostersByPlanAndDate(planId, date);
        } else if (planId != null) {
            rosters = dailyRosterService.getRostersByPlan(planId);
        } else if (date != null) {
            rosters = dailyRosterService.getRostersByDate(date);
        } else {
            rosters = dailyRosterService.getRostersByStatus("PENDING");
        }
        return ResponseEntity.ok(rosters);
    }

    @GetMapping("/rosters/{id}")
    public ResponseEntity<DailyRoster> getRoster(@PathVariable UUID id) {
        DailyRoster roster = dailyRosterService.getRosterById(id);
        return ResponseEntity.ok(roster);
    }

    @PutMapping("/rosters/{id}/approve")
    public ResponseEntity<DailyRoster> approveRoster(
        @PathVariable UUID id,
        @RequestBody RosterApprovalRequest request
    ) {
        DailyRoster roster = dailyRosterService.approveRoster(id, request.getApprovedBy(), request.getNotes());
        return ResponseEntity.ok(roster);
    }

    @PutMapping("/rosters/{id}/reject")
    public ResponseEntity<DailyRoster> rejectRoster(
        @PathVariable UUID id,
        @RequestBody RosterApprovalRequest request
    ) {
        DailyRoster roster = dailyRosterService.rejectRoster(id, request.getNotes());
        return ResponseEntity.ok(roster);
    }

    // ===== Work Records =====
    @PostMapping("/work-records/clock-in")
    public ResponseEntity<WorkRecord> clockIn(@RequestBody ClockInRequest request) {
        WorkRecord record = workRecordService.clockIn(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(record);
    }

    @PostMapping("/work-records/{id}/start")
    public ResponseEntity<WorkRecord> startWork(
        @PathVariable UUID id,
        @RequestBody WorkRecordRequest request
    ) {
        WorkRecord record = workRecordService.startWork(id, request);
        return ResponseEntity.ok(record);
    }

    @PostMapping("/work-records/{id}/end")
    public ResponseEntity<WorkRecord> endWork(@PathVariable UUID id) {
        WorkRecord record = workRecordService.endWork(id);
        return ResponseEntity.ok(record);
    }

    @GetMapping("/work-records/worker/{workerId}/today")
    public ResponseEntity<List<WorkRecord>> getTodayWorkRecords(@PathVariable UUID workerId) {
        List<WorkRecord> records = workRecordService.getTodayWorkRecords(workerId);
        return ResponseEntity.ok(records);
    }

    @GetMapping("/work-records/{id}")
    public ResponseEntity<WorkRecord> getWorkRecord(@PathVariable UUID id) {
        WorkRecord record = workRecordService.getWorkRecordById(id);
        return ResponseEntity.ok(record);
    }

    @GetMapping("/work-records/roster/{rosterId}")
    public ResponseEntity<List<WorkRecord>> getWorkRecordsByRoster(@PathVariable UUID rosterId) {
        List<WorkRecord> records = workRecordService.getWorkRecordsByRoster(rosterId);
        return ResponseEntity.ok(records);
    }
}
