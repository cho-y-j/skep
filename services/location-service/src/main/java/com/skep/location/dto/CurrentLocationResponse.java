package com.skep.location.dto;

import com.skep.location.entity.CurrentLocation;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CurrentLocationResponse {

    private UUID workerId;
    private UUID equipmentId;
    private String workerName;
    private String equipmentName;
    private String vehicleNumber;
    private String siteName;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private LocalDateTime lastUpdated;

    public static CurrentLocationResponse fromEntity(CurrentLocation entity) {
        return CurrentLocationResponse.builder()
                .workerId(entity.getWorkerId())
                .equipmentId(entity.getEquipmentId())
                .workerName(entity.getWorkerName())
                .equipmentName(entity.getEquipmentName())
                .vehicleNumber(entity.getVehicleNumber())
                .siteName(entity.getSiteName())
                .latitude(entity.getLatitude())
                .longitude(entity.getLongitude())
                .lastUpdated(entity.getLastUpdated())
                .build();
    }

}
