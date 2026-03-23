package com.skep.location.dto;

import lombok.*;
import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LocationRequest {

    private UUID workerId;
    private UUID equipmentId;
    private UUID siteId;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private BigDecimal accuracy;
    private String workerName;
    private String equipmentName;
    private String vehicleNumber;
    private String siteName;

}
