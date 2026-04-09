package com.skep.location.dto;

import com.skep.location.entity.LocationRecord;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LocationResponse {

    private UUID id;
    private UUID workerId;
    private UUID equipmentId;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private BigDecimal accuracy;
    private LocalDateTime recordedAt;

    public static LocationResponse fromEntity(LocationRecord entity) {
        return LocationResponse.builder()
                .id(entity.getId())
                .workerId(entity.getWorkerId())
                .equipmentId(entity.getEquipmentId())
                .latitude(entity.getLatitude())
                .longitude(entity.getLongitude())
                .accuracy(entity.getAccuracy())
                .recordedAt(entity.getRecordedAt())
                .build();
    }

}
