package com.skep.dispatch.repository;

import com.skep.dispatch.domain.DeploymentChecklist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface DeploymentChecklistRepository extends JpaRepository<DeploymentChecklist, UUID> {
    List<DeploymentChecklist> findByDeploymentPlanId(UUID deploymentPlanId);
}
