package com.skep.equipmentservice.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.skep.equipmentservice.domain.dto.EquipmentAssignmentRequest;
import com.skep.equipmentservice.domain.dto.EquipmentAssignmentResponse;
import com.skep.equipmentservice.domain.entity.Equipment;
import com.skep.equipmentservice.domain.entity.EquipmentAssignment;
import com.skep.equipmentservice.domain.entity.Person;
import com.skep.equipmentservice.domain.entity.PersonType;
import com.skep.equipmentservice.exception.EquipmentException;
import com.skep.equipmentservice.repository.EquipmentAssignmentRepository;
import com.skep.equipmentservice.repository.EquipmentRepository;
import com.skep.equipmentservice.repository.PersonRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class EquipmentAssignmentService {

    private final EquipmentAssignmentRepository equipmentAssignmentRepository;
    private final EquipmentRepository equipmentRepository;
    private final PersonRepository personRepository;
    private final ObjectMapper objectMapper;

    @Transactional
    public EquipmentAssignmentResponse assignEquipmentToDriver(EquipmentAssignmentRequest request) {
        Equipment equipment = equipmentRepository.findById(request.getEquipmentId())
                .orElseThrow(() -> new EquipmentException("Equipment not found: " + request.getEquipmentId()));

        Person driver = personRepository.findById(request.getDriverId())
                .orElseThrow(() -> new EquipmentException("Driver not found: " + request.getDriverId()));

        if (driver.getPersonType() != PersonType.PersonTypeEnum.DRIVER) {
            throw new EquipmentException("Person is not a driver: " + request.getDriverId());
        }

        // Set previous assignment to not current
        Optional<EquipmentAssignment> currentAssignment = equipmentAssignmentRepository
                .findCurrentAssignmentByEquipmentId(request.getEquipmentId());
        if (currentAssignment.isPresent()) {
            EquipmentAssignment oldAssignment = currentAssignment.get();
            equipmentAssignmentRepository.save(
                    EquipmentAssignment.builder()
                            .id(oldAssignment.getId())
                            .equipment(oldAssignment.getEquipment())
                            .driver(oldAssignment.getDriver())
                            .guides(oldAssignment.getGuides())
                            .assignedFrom(oldAssignment.getAssignedFrom())
                            .assignedUntil(oldAssignment.getAssignedUntil())
                            .isCurrent(false)
                            .createdAt(oldAssignment.getCreatedAt())
                            .build()
            );
        }

        // Create guides JSON array
        ArrayNode guidesArray = objectMapper.createArrayNode();
        if (request.getGuideIds() != null && !request.getGuideIds().isEmpty()) {
            for (UUID guideId : request.getGuideIds()) {
                Person guide = personRepository.findById(guideId)
                        .orElseThrow(() -> new EquipmentException("Guide not found: " + guideId));

                if (guide.getPersonType() != PersonType.PersonTypeEnum.GUIDE) {
                    throw new EquipmentException("Person is not a guide: " + guideId);
                }

                ObjectNode guideNode = objectMapper.createObjectNode();
                guideNode.put("id", guideId.toString());
                guideNode.put("name", guide.getName());
                guidesArray.add(guideNode);
            }
        }

        EquipmentAssignment assignment = EquipmentAssignment.builder()
                .equipment(equipment)
                .driver(driver)
                .guides(guidesArray)
                .assignedFrom(request.getAssignedFrom() != null ? request.getAssignedFrom() : LocalDate.now())
                .assignedUntil(request.getAssignedUntil())
                .isCurrent(true)
                .build();

        EquipmentAssignment savedAssignment = equipmentAssignmentRepository.save(assignment);
        log.info("Equipment assigned: equipmentId={}, driverId={}, assignmentId={}",
                 request.getEquipmentId(), request.getDriverId(), savedAssignment.getId());

        return mapToResponse(savedAssignment);
    }

    @Transactional(readOnly = true)
    public EquipmentAssignmentResponse getCurrentAssignment(UUID equipmentId) {
        EquipmentAssignment assignment = equipmentAssignmentRepository
                .findCurrentAssignmentByEquipmentId(equipmentId)
                .orElseThrow(() -> new EquipmentException("No current assignment found for equipment: " + equipmentId));

        return mapToResponse(assignment);
    }

    private EquipmentAssignmentResponse mapToResponse(EquipmentAssignment assignment) {
        return EquipmentAssignmentResponse.builder()
                .id(assignment.getId())
                .equipmentId(assignment.getEquipment().getId())
                .equipmentName(assignment.getEquipment().getVehicleNumber())
                .driverId(assignment.getDriver().getId())
                .driverName(assignment.getDriver().getName())
                .guides(assignment.getGuides())
                .assignedFrom(assignment.getAssignedFrom())
                .assignedUntil(assignment.getAssignedUntil())
                .isCurrent(assignment.getIsCurrent())
                .createdAt(assignment.getCreatedAt())
                .build();
    }
}
