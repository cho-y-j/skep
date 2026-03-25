package com.skep.auth.service;

import com.skep.auth.domain.entity.Company;
import com.skep.auth.domain.enums.CompanyType;
import com.skep.auth.repository.CompanyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CompanyService {

    private final CompanyRepository companyRepository;

    public List<Company> getAllCompanies() {
        return companyRepository.findAll();
    }

    public Company getCompanyById(UUID id) {
        return companyRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Company not found: " + id));
    }

    public List<Company> getCompaniesByType(CompanyType type) {
        return companyRepository.findActiveCompaniesByType(type);
    }

    public List<Company> getActiveCompanies() {
        return companyRepository.findByStatus(Company.CompanyStatus.ACTIVE);
    }

    @Transactional
    public Company createCompany(Company company) {
        if (companyRepository.countByBusinessNumber(company.getBusinessNumber()) > 0) {
            throw new RuntimeException("Business number already registered: " + company.getBusinessNumber());
        }
        company.setStatus(Company.CompanyStatus.ACTIVE);
        return companyRepository.save(company);
    }

    @Transactional
    public Company updateCompany(UUID id, Company request) {
        Company company = getCompanyById(id);
        if (request.getName() != null) company.setName(request.getName());
        if (request.getRepresentative() != null) company.setRepresentative(request.getRepresentative());
        if (request.getAddress() != null) company.setAddress(request.getAddress());
        if (request.getEmail() != null) company.setEmail(request.getEmail());
        if (request.getPhone() != null) company.setPhone(request.getPhone());
        if (request.getCompanyType() != null) company.setCompanyType(request.getCompanyType());
        return companyRepository.save(company);
    }

    @Transactional
    public Company updateStatus(UUID id, Company.CompanyStatus status) {
        Company company = getCompanyById(id);
        company.setStatus(status);
        return companyRepository.save(company);
    }

    @Transactional
    public void deleteCompany(UUID id) {
        Company company = getCompanyById(id);
        company.setStatus(Company.CompanyStatus.DELETED);
        companyRepository.save(company);
    }
}
