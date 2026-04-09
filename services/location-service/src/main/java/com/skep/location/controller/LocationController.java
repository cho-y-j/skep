package com.skep.location.controller;

import com.skep.location.dto.CurrentLocationResponse;
import com.skep.location.dto.LocationRequest;
import com.skep.location.dto.LocationResponse;
import com.skep.location.service.LocationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/location")
@RequiredArgsConstructor
@Slf4j
public class LocationController {

    private final LocationService locationService;

    @PostMapping("/update")
    public ResponseEntity<LocationResponse> updateLocation(@RequestBody LocationRequest request) {
        log.info("REST location update received for worker: {}", request.getWorkerId());
        LocationResponse response = locationService.updateLocation(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/current/{siteId}")
    public ResponseEntity<List<CurrentLocationResponse>> getSiteCurrentLocations(@PathVariable UUID siteId) {
        log.info("Fetching current locations for site: {}", siteId);
        List<CurrentLocationResponse> responses = locationService.getSiteCurrentLocations(siteId);
        return ResponseEntity.ok(responses);
    }

    @GetMapping("/worker/{workerId}")
    public ResponseEntity<Page<LocationResponse>> getWorkerLocationHistory(
            @PathVariable UUID workerId,
            Pageable pageable) {
        log.info("Fetching location history for worker: {}", workerId);
        Page<LocationResponse> page = locationService.getWorkerLocationHistory(workerId, pageable);
        return ResponseEntity.ok(page);
    }

    @GetMapping("/worker/{workerId}/current")
    public ResponseEntity<CurrentLocationResponse> getWorkerCurrentLocation(@PathVariable UUID workerId) {
        log.info("Fetching current location for worker: {}", workerId);
        CurrentLocationResponse response = locationService.getWorkerCurrentLocation(workerId);
        return ResponseEntity.ok(response);
    }

}
