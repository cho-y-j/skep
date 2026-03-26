package com.skep.documentservice.repository;

import com.skep.documentservice.domain.entity.DocumentTypeRequirement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface DocumentTypeRequirementRepository extends JpaRepository<DocumentTypeRequirement, UUID> {

    List<DocumentTypeRequirement> findByEntityType(DocumentTypeRequirement.EntityType entityType);

    List<DocumentTypeRequirement> findByEntityTypeAndIsRequiredTrue(DocumentTypeRequirement.EntityType entityType);
}
