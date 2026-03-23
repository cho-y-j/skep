package com.skep.equipmentservice.domain.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "persons")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Person {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = true)
    private UUID supplierId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = true)
    private PersonType.PersonTypeEnum personType;

    @Column
    private UUID userId;

    @Column(nullable = false)
    private String name;

    @Column
    private String phone;

    @Column
    private LocalDate birthDate;

    @Column
    private String photoUrl;

    @Column
    private LocalDate healthCheckDate;

    @Column
    private LocalDate safetyTrainingDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PersonStatus status;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;

    public enum PersonStatus {
        ACTIVE, INACTIVE
    }
}
