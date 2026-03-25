package com.skep.dispatch.controller;

import com.skep.dispatch.domain.Site;
import com.skep.dispatch.service.SiteService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/dispatch/sites")
@RequiredArgsConstructor
public class SiteController {

    private final SiteService siteService;

    @GetMapping
    public ResponseEntity<List<Site>> getAllSites() {
        List<Site> sites = siteService.getAllSites();
        return ResponseEntity.ok(sites);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Site> getSite(@PathVariable UUID id) {
        Site site = siteService.getSiteById(id);
        return ResponseEntity.ok(site);
    }

    @GetMapping("/bp/{bpCompanyId}")
    public ResponseEntity<List<Site>> getSitesByBpCompany(@PathVariable UUID bpCompanyId) {
        List<Site> sites = siteService.getSitesByBpCompany(bpCompanyId);
        return ResponseEntity.ok(sites);
    }

    @PostMapping
    public ResponseEntity<Site> createSite(@RequestBody Site site) {
        Site created = siteService.createSite(site);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Site> updateSite(@PathVariable UUID id, @RequestBody Site site) {
        Site updated = siteService.updateSite(id, site);
        return ResponseEntity.ok(updated);
    }
}
