package com.skep.documentservice.repository;

import com.skep.documentservice.domain.entity.Document;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DocumentRepository extends JpaRepository<Document, UUID> {

    List<Document> findByOwnerIdAndOwnerType(UUID ownerId, Document.OwnerType ownerType);

    @Query("SELECT d FROM Document d WHERE d.status = 'PENDING' OR d.status = 'FAILED'")
    List<Document> findPendingDocuments();

    @Query("SELECT d FROM Document d WHERE d.expiryDate IS NOT NULL AND d.expiryDate <= :targetDate AND d.status != 'EXPIRED'")
    List<Document> findExpiringDocuments(@Param("targetDate") LocalDate targetDate);

    @Query("SELECT d FROM Document d WHERE d.expiryDate IS NOT NULL AND d.expiryDate > :targetDate")
    List<Document> findValidDocuments(@Param("targetDate") LocalDate targetDate);

    List<Document> findByDocumentTypeId(UUID documentTypeId);

    Optional<Document> findByIdAndOwnerId(UUID id, UUID ownerId);

    @Query("SELECT COUNT(d) FROM Document d WHERE d.ownerId = :ownerId AND d.ownerType = :ownerType AND d.status = 'VERIFIED'")
    long countVerifiedDocuments(@Param("ownerId") UUID ownerId, @Param("ownerType") Document.OwnerType ownerType);
}
