package com.skep.inspection.service;

import com.skep.inspection.domain.MaintenanceInspection;
import com.skep.inspection.dto.CreateMaintenanceInspectionRequest;
import com.skep.inspection.repository.MaintenanceInspectionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class MaintenanceInspectionService {

    private final MaintenanceInspectionRepository maintenanceInspectionRepository;

    public MaintenanceInspection createInspection(CreateMaintenanceInspectionRequest request) {
        MaintenanceInspection inspection = MaintenanceInspection.builder()
            .equipmentId(request.getEquipmentId())
            .driverId(request.getDriverId())
            .inspectionDate(request.getInspectionDate())
            .mileage(request.getMileage())
            .engineOil(request.getEngineOil())
            .hydraulicOil(request.getHydraulicOil())
            .coolant(request.getCoolant())
            .fuelLevel(request.getFuelLevel())
            .notes(request.getNotes())
            .build();

        return maintenanceInspectionRepository.save(inspection);
    }

    @Transactional(readOnly = true)
    public MaintenanceInspection getInspectionById(UUID id) {
        return maintenanceInspectionRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Maintenance inspection not found: " + id));
    }

    @Transactional(readOnly = true)
    public List<MaintenanceInspection> getInspectionsByEquipment(UUID equipmentId) {
        return maintenanceInspectionRepository.findByEquipmentIdOrderByDate(equipmentId);
    }

    @Transactional(readOnly = true)
    public List<MaintenanceInspection> getInspectionsByDriver(UUID driverId) {
        return maintenanceInspectionRepository.findByDriverIdOrderByDate(driverId);
    }

    public MaintenanceInspection updateInspection(UUID id, CreateMaintenanceInspectionRequest request) {
        MaintenanceInspection inspection = getInspectionById(id);
        inspection.setMileage(request.getMileage());
        inspection.setEngineOil(request.getEngineOil());
        inspection.setHydraulicOil(request.getHydraulicOil());
        inspection.setCoolant(request.getCoolant());
        inspection.setFuelLevel(request.getFuelLevel());
        inspection.setNotes(request.getNotes());
        return maintenanceInspectionRepository.save(inspection);
    }
}
