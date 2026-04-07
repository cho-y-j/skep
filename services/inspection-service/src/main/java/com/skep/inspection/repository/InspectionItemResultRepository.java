package com.skep.inspection.repository;

import com.skep.inspection.domain.InspectionItemResult;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface InspectionItemResultRepository extends JpaRepository<InspectionItemResult, UUID> {
    List<InspectionItemResult> findByInspectionId(UUID inspectionId);

    @Query("SELECT i FROM InspectionItemResult i WHERE i.inspectionId = :inspectionId ORDER BY i.sequenceNumber")
    List<InspectionItemResult> findByInspectionIdOrderBySequence(@Param("inspectionId") UUID inspectionId);

    @Query("SELECT i FROM InspectionItemResult i WHERE i.inspectionId = :inspectionId AND i.itemNumber = :itemNumber")
    Optional<InspectionItemResult> findByInspectionAndItemNumber(
        @Param("inspectionId") UUID inspectionId,
        @Param("itemNumber") Integer itemNumber
    );

    @Query("SELECT MAX(i.sequenceNumber) FROM InspectionItemResult i WHERE i.inspectionId = :inspectionId")
    Integer findMaxSequenceNumber(@Param("inspectionId") UUID inspectionId);
}
