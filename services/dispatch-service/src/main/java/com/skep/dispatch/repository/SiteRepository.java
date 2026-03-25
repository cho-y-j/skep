package com.skep.dispatch.repository;

import com.skep.dispatch.domain.Site;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface SiteRepository extends JpaRepository<Site, UUID> {
    List<Site> findByBpCompanyId(UUID bpCompanyId);
    List<Site> findByStatus(String status);
    List<Site> findByBpCompanyIdAndStatus(UUID bpCompanyId, String status);
}
