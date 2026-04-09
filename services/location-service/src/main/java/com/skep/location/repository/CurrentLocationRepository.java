package com.skep.location.repository;

import com.skep.location.entity.CurrentLocation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CurrentLocationRepository extends JpaRepository<CurrentLocation, UUID> {

    @Query("SELECT c FROM CurrentLocation c WHERE c.siteName = :siteName")
    List<CurrentLocation> findBySiteName(@Param("siteName") String siteName);

    @Query("SELECT c FROM CurrentLocation c WHERE c.equipmentId = :equipmentId")
    CurrentLocation findByEquipmentId(@Param("equipmentId") UUID equipmentId);

    List<CurrentLocation> findBySiteId(UUID siteId);

}
