package com.skep.equipmentservice.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.skep.equipmentservice.domain.dto.*;
import com.skep.equipmentservice.domain.entity.Equipment;
import com.skep.equipmentservice.domain.entity.EquipmentType;
import com.skep.equipmentservice.domain.entity.Person;
import com.skep.equipmentservice.domain.entity.EquipmentAssignment;
import com.skep.equipmentservice.exception.EquipmentException;
import com.skep.equipmentservice.repository.EquipmentAssignmentRepository;
import com.skep.equipmentservice.repository.EquipmentRepository;
import com.skep.equipmentservice.repository.EquipmentTypeRepository;
import com.skep.equipmentservice.repository.PersonRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class EquipmentService {

    private final EquipmentRepository equipmentRepository;
    private final EquipmentTypeRepository equipmentTypeRepository;
    private final PersonRepository personRepository;
    private final DocumentServiceClient documentServiceClient;
    private final EquipmentAssignmentRepository equipmentAssignmentRepository;
    private final ObjectMapper objectMapper;

    @Transactional
    public EquipmentResponse registerEquipment(EquipmentRequest request) {
        if (equipmentRepository.findByVehicleNumber(request.getVehicleNumber()).isPresent()) {
            throw new EquipmentException("Equipment with vehicle number already exists: " + request.getVehicleNumber());
        }

        EquipmentType equipmentType;
        if (request.getEquipmentTypeId() != null) {
            equipmentType = equipmentTypeRepository.findById(request.getEquipmentTypeId())
                    .orElseThrow(() -> new EquipmentException("Equipment type not found: " + request.getEquipmentTypeId()));
        } else if (request.getEquipmentTypeName() != null && !request.getEquipmentTypeName().isBlank()) {
            equipmentType = equipmentTypeRepository.findByName(request.getEquipmentTypeName())
                    .orElseGet(() -> {
                        log.info("Creating new equipment type: {}", request.getEquipmentTypeName());
                        EquipmentType newType = EquipmentType.builder()
                                .name(request.getEquipmentTypeName())
                                .build();
                        return equipmentTypeRepository.save(newType);
                    });
        } else {
            throw new EquipmentException("Either equipmentTypeId or equipmentTypeName must be provided");
        }

        Equipment equipment = Equipment.builder()
                .supplierId(request.getSupplierId())
                .equipmentType(equipmentType)
                .vehicleNumber(request.getVehicleNumber())
                .modelName(request.getModelName())
                .manufactureYear(request.getManufactureYear())
                .status(Equipment.EquipmentStatus.ACTIVE)
                .nfcTagId(request.getNfcTagId())
                .preInspectionStatus(Equipment.PreInspectionStatus.PENDING)
                .build();

        Equipment savedEquipment = equipmentRepository.save(equipment);
        log.info("Equipment registered: id={}, vehicleNumber={}", savedEquipment.getId(), request.getVehicleNumber());

        return mapToResponse(savedEquipment);
    }

    @Transactional(readOnly = true)
    public List<EquipmentResponse> getEquipmentList(UUID supplierId) {
        List<Equipment> equipments;
        if (supplierId != null) {
            equipments = equipmentRepository.findBySupplierId(supplierId);
        } else {
            equipments = equipmentRepository.findAll();
        }

        return equipments.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public EquipmentResponse getEquipmentById(UUID id) {
        Equipment equipment = equipmentRepository.findById(id)
                .orElseThrow(() -> new EquipmentException("Equipment not found: " + id));
        return mapToResponse(equipment);
    }

    @Transactional
    public EquipmentResponse updateEquipment(UUID id, EquipmentRequest request) {
        Equipment equipment = equipmentRepository.findById(id)
                .orElseThrow(() -> new EquipmentException("Equipment not found: " + id));

        if (request.getModelName() != null) {
            equipment = Equipment.builder()
                    .id(equipment.getId())
                    .supplierId(equipment.getSupplierId())
                    .equipmentType(equipment.getEquipmentType())
                    .vehicleNumber(equipment.getVehicleNumber())
                    .modelName(request.getModelName())
                    .manufactureYear(equipment.getManufactureYear())
                    .status(equipment.getStatus())
                    .nfcTagId(equipment.getNfcTagId())
                    .preInspectionStatus(equipment.getPreInspectionStatus())
                    .preInspectionDate(equipment.getPreInspectionDate())
                    .createdAt(equipment.getCreatedAt())
                    .build();
        }

        if (request.getManufactureYear() != null) {
            equipment = Equipment.builder()
                    .id(equipment.getId())
                    .supplierId(equipment.getSupplierId())
                    .equipmentType(equipment.getEquipmentType())
                    .vehicleNumber(equipment.getVehicleNumber())
                    .modelName(equipment.getModelName())
                    .manufactureYear(request.getManufactureYear())
                    .status(equipment.getStatus())
                    .nfcTagId(equipment.getNfcTagId())
                    .preInspectionStatus(equipment.getPreInspectionStatus())
                    .preInspectionDate(equipment.getPreInspectionDate())
                    .createdAt(equipment.getCreatedAt())
                    .build();
        }

        Equipment savedEquipment = equipmentRepository.save(equipment);
        log.info("Equipment updated: id={}", id);

        return mapToResponse(savedEquipment);
    }

    @Transactional
    public void registerNfcTag(UUID equipmentId, String nfcTagId) {
        Equipment equipment = equipmentRepository.findById(equipmentId)
                .orElseThrow(() -> new EquipmentException("Equipment not found: " + equipmentId));

        if (equipmentRepository.findByNfcTagId(nfcTagId).isPresent()) {
            throw new EquipmentException("NFC tag already assigned: " + nfcTagId);
        }

        equipment = Equipment.builder()
                .id(equipment.getId())
                .supplierId(equipment.getSupplierId())
                .equipmentType(equipment.getEquipmentType())
                .vehicleNumber(equipment.getVehicleNumber())
                .modelName(equipment.getModelName())
                .manufactureYear(equipment.getManufactureYear())
                .status(equipment.getStatus())
                .nfcTagId(nfcTagId)
                .preInspectionStatus(equipment.getPreInspectionStatus())
                .preInspectionDate(equipment.getPreInspectionDate())
                .createdAt(equipment.getCreatedAt())
                .build();

        equipmentRepository.save(equipment);
        log.info("NFC tag registered: equipmentId={}, nfcTagId={}", equipmentId, nfcTagId);
    }

    @Transactional(readOnly = true)
    public EquipmentResponse getEquipmentByNfcTag(String nfcTagId) {
        Equipment equipment = equipmentRepository.findByNfcTagId(nfcTagId)
                .orElseThrow(() -> new EquipmentException("Equipment not found by NFC tag: " + nfcTagId));
        return mapToResponse(equipment);
    }

    @Transactional(readOnly = true)
    public EquipmentStatusResponse checkEquipmentStatus(UUID equipmentId) {
        Equipment equipment = equipmentRepository.findById(equipmentId)
                .orElseThrow(() -> new EquipmentException("Equipment not found: " + equipmentId));

        boolean preInspectionPassed = equipment.getPreInspectionStatus() == Equipment.PreInspectionStatus.PASSED;
        boolean requiredDocumentsValid = documentServiceClient.checkRequiredDocumentsValid(equipmentId, equipment.getEquipmentType().getName());

        // Check driver health check and safety training via current assignment
        boolean driverHealthCheckCompleted = false;
        boolean safetyTrainingCompleted = false;
        Optional<EquipmentAssignment> currentAssignment = equipmentAssignmentRepository
                .findCurrentAssignmentByEquipmentId(equipmentId);
        if (currentAssignment.isPresent()) {
            Person driver = currentAssignment.get().getDriver();
            LocalDate today = LocalDate.now();
            // Health check is valid if completed within the last year
            if (driver.getHealthCheckDate() != null) {
                driverHealthCheckCompleted = !driver.getHealthCheckDate().isBefore(today.minusYears(1));
            }
            // Safety training is valid if completed within the last year
            if (driver.getSafetyTrainingDate() != null) {
                safetyTrainingCompleted = !driver.getSafetyTrainingDate().isBefore(today.minusYears(1));
            }
        }

        EquipmentStatusResponse.EquipmentStatusResponseBuilder builder = EquipmentStatusResponse.builder()
                .equipmentId(equipmentId)
                .preInspectionPassed(preInspectionPassed)
                .requiredDocumentsValid(requiredDocumentsValid);

        boolean allConditionsMet = preInspectionPassed && requiredDocumentsValid && driverHealthCheckCompleted && safetyTrainingCompleted;

        builder.isReadyForDeployment(allConditionsMet)
                .driverHealthCheckCompleted(driverHealthCheckCompleted)
                .safetyTrainingCompleted(safetyTrainingCompleted);

        if (!allConditionsMet) {
            StringBuilder messageBuilder = new StringBuilder("Equipment is not ready for deployment: ");
            if (!preInspectionPassed) messageBuilder.append("pre-inspection not passed, ");
            if (!requiredDocumentsValid) messageBuilder.append("required documents invalid or expired, ");
            if (!driverHealthCheckCompleted) messageBuilder.append("driver health check not completed, ");
            if (!safetyTrainingCompleted) messageBuilder.append("safety training not completed");
            builder.message(messageBuilder.toString());
        } else {
            builder.message("Equipment is ready for deployment");
        }

        return builder.build();
    }

    public void deleteEquipment(UUID id) {
        Equipment equipment = equipmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Equipment not found: " + id));
        equipmentRepository.delete(equipment);
    }

    private EquipmentResponse mapToResponse(Equipment equipment) {
        return EquipmentResponse.builder()
                .id(equipment.getId())
                .supplierId(equipment.getSupplierId())
                .equipmentTypeId(equipment.getEquipmentType().getId())
                .equipmentTypeName(equipment.getEquipmentType().getName())
                .vehicleNumber(equipment.getVehicleNumber())
                .modelName(equipment.getModelName())
                .manufactureYear(equipment.getManufactureYear())
                .status(equipment.getStatus().toString())
                .nfcTagId(equipment.getNfcTagId())
                .preInspectionStatus(equipment.getPreInspectionStatus().toString())
                .preInspectionDate(equipment.getPreInspectionDate())
                .requiredDocuments(equipment.getEquipmentType().getRequiredDocuments())
                .createdAt(equipment.getCreatedAt())
                .updatedAt(equipment.getUpdatedAt())
                .build();
    }
}
