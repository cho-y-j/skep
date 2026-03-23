package com.skep.dispatch.repository;

import com.skep.dispatch.domain.DailyWorkConfirmation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DailyWorkConfirmationRepository extends JpaRepository<DailyWorkConfirmation, UUID> {
    Optional<DailyWorkConfirmation> findByWorkRecordId(UUID workRecordId);
    List<DailyWorkConfirmation> findByStatus(String status);

    @Query("SELECT d FROM DailyWorkConfirmation d WHERE d.bpSignedBy = :bpId AND d.status = 'SIGNED'")
    List<DailyWorkConfirmation> findSignedByBP(@Param("bpId") UUID bpId);
}
