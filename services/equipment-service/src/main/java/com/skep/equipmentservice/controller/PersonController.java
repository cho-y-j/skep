package com.skep.equipmentservice.controller;

import com.skep.equipmentservice.domain.dto.PersonRequest;
import com.skep.equipmentservice.domain.dto.PersonResponse;
import com.skep.equipmentservice.service.PersonService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/equipment/persons")
@RequiredArgsConstructor
public class PersonController {

    private final PersonService personService;

    @PostMapping
    public ResponseEntity<PersonResponse> registerPerson(@RequestBody PersonRequest request) {
        PersonResponse response = personService.registerPerson(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<List<PersonResponse>> getPersonList(
            @RequestParam(value = "supplier_id", required = false) UUID supplierId) {

        List<PersonResponse> persons = personService.getPersonList(supplierId);
        return ResponseEntity.ok(persons);
    }

    @GetMapping("/{id}")
    public ResponseEntity<PersonResponse> getPersonById(@PathVariable UUID id) {
        PersonResponse person = personService.getPersonById(id);
        return ResponseEntity.ok(person);
    }

    @PutMapping("/{id}")
    public ResponseEntity<PersonResponse> updatePerson(
            @PathVariable UUID id,
            @RequestBody PersonRequest request) {

        PersonResponse response = personService.updatePerson(id, request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{id}/health-check")
    public ResponseEntity<PersonResponse> recordHealthCheck(
            @PathVariable UUID id,
            @RequestParam(value = "check_date", required = false) LocalDate checkDate) {

        LocalDate date = checkDate != null ? checkDate : LocalDate.now();
        PersonResponse response = personService.recordHealthCheck(id, date);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{id}/safety-training")
    public ResponseEntity<PersonResponse> recordSafetyTraining(
            @PathVariable UUID id,
            @RequestParam(value = "training_date", required = false) LocalDate trainingDate) {

        LocalDate date = trainingDate != null ? trainingDate : LocalDate.now();
        PersonResponse response = personService.recordSafetyTraining(id, date);
        return ResponseEntity.ok(response);
    }
}
