package com.skep.location.service;

import com.skep.location.dto.CurrentLocationResponse;
import com.skep.location.dto.LocationRequest;
import com.skep.location.dto.LocationResponse;
import com.skep.location.entity.CurrentLocation;
import com.skep.location.entity.LocationRecord;
import com.skep.location.repository.CurrentLocationRepository;
import com.skep.location.repository.LocationRecordRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class LocationService {

    private final LocationRecordRepository locationRecordRepository;
    private final CurrentLocationRepository currentLocationRepository;

    public LocationResponse updateLocation(LocationRequest request) {
        log.info("Updating location for worker: {}", request.getWorkerId());

        LocationRecord record = LocationRecord.builder()
                .workerId(request.getWorkerId())
                .equipmentId(request.getEquipmentId())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .accuracy(request.getAccuracy())
                .build();

        LocationRecord saved = locationRecordRepository.save(record);

        CurrentLocation currentLocation = currentLocationRepository.findById(request.getWorkerId())
                .orElse(CurrentLocation.builder().workerId(request.getWorkerId()).build());

        currentLocation.setEquipmentId(request.getEquipmentId());
        currentLocation.setSiteId(request.getSiteId());
        currentLocation.setWorkerName(request.getWorkerName());
        currentLocation.setEquipmentName(request.getEquipmentName());
        currentLocation.setVehicleNumber(request.getVehicleNumber());
        currentLocation.setSiteName(request.getSiteName());
        currentLocation.setLatitude(request.getLatitude());
        currentLocation.setLongitude(request.getLongitude());
        currentLocationRepository.save(currentLocation);

        return LocationResponse.fromEntity(saved);
    }

    public Page<LocationResponse> getWorkerLocationHistory(UUID workerId, Pageable pageable) {
        log.info("Fetching location history for worker: {}", workerId);
        Page<LocationRecord> page = locationRecordRepository.findByWorkerIdOrderByRecordedAtDesc(workerId, pageable);
        return page.map(LocationResponse::fromEntity);
    }

    public List<CurrentLocationResponse> getSiteCurrentLocations(UUID siteId) {
        log.info("Fetching current locations for site: {}", siteId);
        List<CurrentLocation> locations = currentLocationRepository.findBySiteId(siteId);
        return locations.stream()
                .map(CurrentLocationResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public CurrentLocationResponse getWorkerCurrentLocation(UUID workerId) {
        log.info("Fetching current location for worker: {}", workerId);
        CurrentLocation location = currentLocationRepository.findById(workerId)
                .orElseThrow(() -> new RuntimeException("Current location not found for worker: " + workerId));
        return CurrentLocationResponse.fromEntity(location);
    }

}
