package com.skep.dispatch.service;

import com.skep.dispatch.domain.Site;
import com.skep.dispatch.repository.SiteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class SiteService {

    private final SiteRepository siteRepository;

    @Transactional(readOnly = true)
    public List<Site> getAllSites() {
        return siteRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Site getSiteById(UUID id) {
        return siteRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Site not found: " + id));
    }

    @Transactional(readOnly = true)
    public List<Site> getSitesByBpCompany(UUID bpCompanyId) {
        return siteRepository.findByBpCompanyId(bpCompanyId);
    }

    public Site createSite(Site site) {
        return siteRepository.save(site);
    }

    public Site updateSite(UUID id, Site request) {
        Site site = getSiteById(id);
        if (request.getName() != null) site.setName(request.getName());
        if (request.getAddress() != null) site.setAddress(request.getAddress());
        if (request.getDescription() != null) site.setDescription(request.getDescription());
        if (request.getBoundaryType() != null) site.setBoundaryType(request.getBoundaryType());
        if (request.getBoundaryCoordinates() != null) site.setBoundaryCoordinates(request.getBoundaryCoordinates());
        if (request.getCenterLat() != null) site.setCenterLat(request.getCenterLat());
        if (request.getCenterLng() != null) site.setCenterLng(request.getCenterLng());
        if (request.getRadiusMeters() != null) site.setRadiusMeters(request.getRadiusMeters());
        if (request.getStatus() != null) site.setStatus(request.getStatus());
        return siteRepository.save(site);
    }

    public void deleteSite(UUID id) {
        Site site = getSiteById(id);
        siteRepository.delete(site);
    }
}
