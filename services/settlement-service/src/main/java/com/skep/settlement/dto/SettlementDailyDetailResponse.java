package com.skep.settlement.dto;

import com.skep.settlement.entity.SettlementDailyDetail;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SettlementDailyDetailResponse {

    private UUID id;
    private LocalDate workDate;
    private Boolean isDailyWork;
    private BigDecimal dailyAmount;
    private BigDecimal overtimeHours;
    private BigDecimal overtimeAmount;
    private Integer earlyMorningCount;
    private BigDecimal earlyMorningAmount;
    private BigDecimal nightHours;
    private BigDecimal nightAmount;
    private Boolean isOvernight;
    private BigDecimal overnightAmount;
    private BigDecimal dayTotal;

    public static SettlementDailyDetailResponse fromEntity(SettlementDailyDetail entity) {
        return SettlementDailyDetailResponse.builder()
                .id(entity.getId())
                .workDate(entity.getWorkDate())
                .isDailyWork(entity.getIsDailyWork())
                .dailyAmount(entity.getDailyAmount())
                .overtimeHours(entity.getOvertimeHours())
                .overtimeAmount(entity.getOvertimeAmount())
                .earlyMorningCount(entity.getEarlyMorningCount())
                .earlyMorningAmount(entity.getEarlyMorningAmount())
                .nightHours(entity.getNightHours())
                .nightAmount(entity.getNightAmount())
                .isOvernight(entity.getIsOvernight())
                .overnightAmount(entity.getOvernightAmount())
                .dayTotal(entity.getDayTotal())
                .build();
    }

}
