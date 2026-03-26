package com.skep.documentservice.repository;

import com.skep.documentservice.domain.entity.DocumentType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface DocumentTypeRepository extends JpaRepository<DocumentType, UUID> {

    Optional<DocumentType> findByName(String name);
}
