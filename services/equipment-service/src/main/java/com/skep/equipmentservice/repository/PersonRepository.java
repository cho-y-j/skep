package com.skep.equipmentservice.repository;

import com.skep.equipmentservice.domain.entity.Person;
import com.skep.equipmentservice.domain.entity.PersonType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PersonRepository extends JpaRepository<Person, UUID> {

    List<Person> findBySupplierId(UUID supplierId);

    List<Person> findBySupplierIdAndPersonType(UUID supplierId, PersonType.PersonTypeEnum personType);

    List<Person> findByPersonType(PersonType.PersonTypeEnum personType);

    Optional<Person> findByUserId(UUID userId);

    List<Person> findByStatus(Person.PersonStatus status);
}
