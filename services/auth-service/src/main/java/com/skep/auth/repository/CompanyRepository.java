package com.skep.auth.repository;

import com.skep.auth.domain.entity.Company;
import com.skep.auth.domain.enums.CompanyType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CompanyRepository extends JpaRepository<Company, UUID> {

    Optional<Company> findByBusinessNumber(String businessNumber);

    Optional<Company> findByBusinessNumberAndStatus(String businessNumber, Company.CompanyStatus status);

    List<Company> findByCompanyType(CompanyType companyType);

    List<Company> findByCompanyTypeAndStatus(CompanyType companyType, Company.CompanyStatus status);

    List<Company> findByStatus(Company.CompanyStatus status);

    @Query("SELECT c FROM Company c WHERE c.businessNumber = :businessNumber AND c.status = 'ACTIVE'")
    Optional<Company> findActiveCompanyByBusinessNumber(@Param("businessNumber") String businessNumber);

    @Query("SELECT COUNT(c) FROM Company c WHERE c.businessNumber = :businessNumber")
    long countByBusinessNumber(@Param("businessNumber") String businessNumber);

    @Query("SELECT c FROM Company c WHERE c.id = :companyId AND c.status = 'ACTIVE'")
    Optional<Company> findActiveCompanyById(@Param("companyId") UUID companyId);

    @Query("SELECT c FROM Company c WHERE c.companyType = :companyType AND c.status = 'ACTIVE' ORDER BY c.name")
    List<Company> findActiveCompaniesByType(@Param("companyType") CompanyType companyType);
}
