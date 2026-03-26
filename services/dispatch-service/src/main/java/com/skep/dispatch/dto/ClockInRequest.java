package com.skep.dispatch.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClockInRequest {
    private UUID dailyRosterId;
    private UUID workerId;
    private String workerType;
    private Double gpsLat;
    private Double gpsLng;
    private String fingerprint;
}
