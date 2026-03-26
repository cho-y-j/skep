package com.skep.equipmentservice.service;

import com.skep.equipmentservice.domain.dto.PersonRequest;
import com.skep.equipmentservice.domain.dto.PersonResponse;
import com.skep.equipmentservice.domain.entity.Person;
import com.skep.equipmentservice.domain.entity.PersonType;
import com.skep.equipmentservice.exception.EquipmentException;
import com.skep.equipmentservice.repository.PersonRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class PersonService {

    private final PersonRepository personRepository;

    @Transactional
    public PersonResponse registerPerson(PersonRequest request) {
        String personTypeValue = request.getPersonType();
        if (personTypeValue == null || personTypeValue.isBlank()) {
            personTypeValue = request.getPersonTypeName();
        }
        if (personTypeValue == null || personTypeValue.isBlank()) {
            throw new EquipmentException("Either personType or personTypeName must be provided");
        }

        PersonType.PersonTypeEnum personType;
        try {
            personType = PersonType.PersonTypeEnum.valueOf(personTypeValue.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new EquipmentException("Invalid person type: " + personTypeValue);
        }

        Person person = Person.builder()
                .supplierId(request.getSupplierId())
                .personType(personType)
                .userId(request.getUserId())
                .name(request.getName())
                .phone(request.getPhone())
                .birthDate(request.getBirthDate())
                .photoUrl(request.getPhotoUrl())
                .status(Person.PersonStatus.ACTIVE)
                .build();

        Person savedPerson = personRepository.save(person);
        log.info("Person registered: id={}, type={}, supplierId={}", savedPerson.getId(), personType, request.getSupplierId());

        return mapToResponse(savedPerson);
    }

    @Transactional(readOnly = true)
    public List<PersonResponse> getPersonList(UUID supplierId) {
        List<Person> persons;
        if (supplierId != null) {
            persons = personRepository.findBySupplierId(supplierId);
        } else {
            persons = personRepository.findAll();
        }

        return persons.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public PersonResponse getPersonById(UUID id) {
        Person person = personRepository.findById(id)
                .orElseThrow(() -> new EquipmentException("Person not found: " + id));
        return mapToResponse(person);
    }

    @Transactional
    public PersonResponse updatePerson(UUID id, PersonRequest request) {
        Person person = personRepository.findById(id)
                .orElseThrow(() -> new EquipmentException("Person not found: " + id));

        Person updatedPerson = Person.builder()
                .id(person.getId())
                .supplierId(person.getSupplierId())
                .personType(person.getPersonType())
                .userId(request.getUserId() != null ? request.getUserId() : person.getUserId())
                .name(request.getName() != null ? request.getName() : person.getName())
                .phone(request.getPhone() != null ? request.getPhone() : person.getPhone())
                .birthDate(request.getBirthDate() != null ? request.getBirthDate() : person.getBirthDate())
                .photoUrl(request.getPhotoUrl() != null ? request.getPhotoUrl() : person.getPhotoUrl())
                .healthCheckDate(person.getHealthCheckDate())
                .safetyTrainingDate(person.getSafetyTrainingDate())
                .status(person.getStatus())
                .createdAt(person.getCreatedAt())
                .build();

        Person savedPerson = personRepository.save(updatedPerson);
        log.info("Person updated: id={}", id);

        return mapToResponse(savedPerson);
    }

    @Transactional
    public PersonResponse recordHealthCheck(UUID personId, LocalDate checkDate) {
        Person person = personRepository.findById(personId)
                .orElseThrow(() -> new EquipmentException("Person not found: " + personId));

        Person updatedPerson = Person.builder()
                .id(person.getId())
                .supplierId(person.getSupplierId())
                .personType(person.getPersonType())
                .userId(person.getUserId())
                .name(person.getName())
                .phone(person.getPhone())
                .birthDate(person.getBirthDate())
                .photoUrl(person.getPhotoUrl())
                .healthCheckDate(checkDate)
                .safetyTrainingDate(person.getSafetyTrainingDate())
                .status(person.getStatus())
                .createdAt(person.getCreatedAt())
                .build();

        Person savedPerson = personRepository.save(updatedPerson);
        log.info("Health check recorded: personId={}, date={}", personId, checkDate);

        return mapToResponse(savedPerson);
    }

    @Transactional
    public PersonResponse recordSafetyTraining(UUID personId, LocalDate trainingDate) {
        Person person = personRepository.findById(personId)
                .orElseThrow(() -> new EquipmentException("Person not found: " + personId));

        Person updatedPerson = Person.builder()
                .id(person.getId())
                .supplierId(person.getSupplierId())
                .personType(person.getPersonType())
                .userId(person.getUserId())
                .name(person.getName())
                .phone(person.getPhone())
                .birthDate(person.getBirthDate())
                .photoUrl(person.getPhotoUrl())
                .healthCheckDate(person.getHealthCheckDate())
                .safetyTrainingDate(trainingDate)
                .status(person.getStatus())
                .createdAt(person.getCreatedAt())
                .build();

        Person savedPerson = personRepository.save(updatedPerson);
        log.info("Safety training recorded: personId={}, date={}", personId, trainingDate);

        return mapToResponse(savedPerson);
    }

    private PersonResponse mapToResponse(Person person) {
        return PersonResponse.builder()
                .id(person.getId())
                .supplierId(person.getSupplierId())
                .personType(person.getPersonType().toString())
                .userId(person.getUserId())
                .name(person.getName())
                .phone(person.getPhone())
                .birthDate(person.getBirthDate())
                .photoUrl(person.getPhotoUrl())
                .healthCheckDate(person.getHealthCheckDate())
                .safetyTrainingDate(person.getSafetyTrainingDate())
                .status(person.getStatus().toString())
                .createdAt(person.getCreatedAt())
                .updatedAt(person.getUpdatedAt())
                .build();
    }
}
