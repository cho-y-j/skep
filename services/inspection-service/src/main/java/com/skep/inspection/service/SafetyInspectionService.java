package com.skep.inspection.service;

import com.skep.inspection.domain.InspectionItemMaster;
import com.skep.inspection.domain.InspectionItemResult;
import com.skep.inspection.domain.SafetyInspection;
import com.skep.inspection.dto.RecordItemRequest;
import com.skep.inspection.dto.StartSafetyInspectionRequest;
import com.skep.inspection.repository.InspectionItemMasterRepository;
import com.skep.inspection.repository.InspectionItemResultRepository;
import com.skep.inspection.repository.SafetyInspectionRepository;
import com.skep.inspection.util.GpsUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class SafetyInspectionService {

    private final SafetyInspectionRepository safetyInspectionRepository;
    private final InspectionItemResultRepository itemResultRepository;
    private final InspectionItemMasterRepository itemMasterRepository;

    @Transactional(readOnly = true)
    public List<SafetyInspection> getAllInspections() {
        return safetyInspectionRepository.findAll();
    }

    public SafetyInspection startInspection(StartSafetyInspectionRequest request) {
        // GPS 거리 검증
        if (!GpsUtil.isWithinInspectionRange(
            request.getInspectorGpsLat(), request.getInspectorGpsLng(),
            request.getEquipmentGpsLat(), request.getEquipmentGpsLng()
        )) {
            throw new RuntimeException(
                GpsUtil.getDistanceError(
                    request.getInspectorGpsLat(), request.getInspectorGpsLng(),
                    request.getEquipmentGpsLat(), request.getEquipmentGpsLng()
                )
            );
        }

        double distance = GpsUtil.calculateDistance(
            request.getInspectorGpsLat(), request.getInspectorGpsLng(),
            request.getEquipmentGpsLat(), request.getEquipmentGpsLng()
        );

        SafetyInspection inspection = SafetyInspection.builder()
            .equipmentId(request.getEquipmentId())
            .inspectorId(request.getInspectorId())
            .inspectionDate(request.getInspectionDate())
            .startedAt(LocalDateTime.now())
            .inspectorGpsLat(request.getInspectorGpsLat())
            .inspectorGpsLng(request.getInspectorGpsLng())
            .equipmentGpsLat(request.getEquipmentGpsLat())
            .equipmentGpsLng(request.getEquipmentGpsLng())
            .distanceMeters(BigDecimal.valueOf(distance))
            .status("IN_PROGRESS")
            .build();

        return safetyInspectionRepository.save(inspection);
    }

    public InspectionItemResult recordItem(UUID inspectionId, RecordItemRequest request) {
        SafetyInspection inspection = safetyInspectionRepository.findById(inspectionId)
            .orElseThrow(() -> new RuntimeException("Inspection not found: " + inspectionId));

        if (!"IN_PROGRESS".equals(inspection.getStatus())) {
            throw new RuntimeException("Inspection is not in progress");
        }

        // 항목 순서 검증
        Integer maxSequence = itemResultRepository.findMaxSequenceNumber(inspectionId);
        int expectedSequence = (maxSequence == null ? 0 : maxSequence) + 1;

        InspectionItemResult result = InspectionItemResult.builder()
            .inspectionId(inspectionId)
            .itemNumber(request.getItemNumber())
            .result(request.getResult())
            .photoUrl(request.getPhotoUrl())
            .notes(request.getNotes())
            .sequenceNumber(expectedSequence)
            .build();

        // item_master_id 조회 (optional)
        // 필요시 equipment type을 알아야 함

        return itemResultRepository.save(result);
    }

    public SafetyInspection completeInspection(UUID inspectionId) {
        SafetyInspection inspection = safetyInspectionRepository.findById(inspectionId)
            .orElseThrow(() -> new RuntimeException("Inspection not found: " + inspectionId));

        if (!"IN_PROGRESS".equals(inspection.getStatus())) {
            throw new RuntimeException("Inspection is not in progress");
        }

        inspection.setCompletedAt(LocalDateTime.now());
        inspection.setStatus("COMPLETED");

        return safetyInspectionRepository.save(inspection);
    }

    @Transactional(readOnly = true)
    public SafetyInspection getInspectionById(UUID id) {
        return safetyInspectionRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Inspection not found: " + id));
    }

    @Transactional(readOnly = true)
    public List<SafetyInspection> getInspectionsByEquipment(UUID equipmentId) {
        return safetyInspectionRepository.findByEquipmentIdOrderByDate(equipmentId);
    }

    @Transactional(readOnly = true)
    public List<InspectionItemResult> getInspectionItems(UUID inspectionId) {
        return itemResultRepository.findByInspectionIdOrderBySequence(inspectionId);
    }

    public SafetyInspection failInspection(UUID inspectionId, String notes) {
        SafetyInspection inspection = getInspectionById(inspectionId);
        inspection.setStatus("FAILED");
        inspection.setNotes(notes);
        inspection.setCompletedAt(LocalDateTime.now());
        return safetyInspectionRepository.save(inspection);
    }
}
