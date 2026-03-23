package com.skep.settlement.service;

import com.skep.settlement.dto.*;
import com.skep.settlement.entity.Settlement;
import com.skep.settlement.entity.SettlementDailyDetail;
import com.skep.settlement.repository.SettlementRepository;
import com.skep.settlement.repository.SettlementDailyDetailRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class SettlementService {

    private final SettlementRepository settlementRepository;
    private final SettlementDailyDetailRepository dailyDetailRepository;
    private final SettlementPdfService pdfService;
    private final SettlementEmailService emailService;

    private static final BigDecimal TAX_RATE = new BigDecimal("0.10");

    public SettlementResponse generateSettlement(SettlementRequest request) {
        log.info("Generating settlement for supplier: {}, bp: {}, period: {}",
                request.getSupplierId(), request.getBpCompanyId(), request.getYearMonth());

        Settlement settlement = Settlement.builder()
                .deploymentPlanId(request.getDeploymentPlanId())
                .supplierId(request.getSupplierId())
                .bpCompanyId(request.getBpCompanyId())
                .yearMonth(request.getYearMonth())
                .status(Settlement.SettlementStatus.DRAFT)
                .build();

        Settlement saved = settlementRepository.save(settlement);
        calculateSettlementAmounts(saved);

        return SettlementResponse.fromEntity(saved);
    }

    private void calculateSettlementAmounts(Settlement settlement) {
        YearMonth yearMonth = YearMonth.parse(settlement.getYearMonth());
        LocalDate firstDay = yearMonth.atDay(1);
        LocalDate lastDay = yearMonth.atEndOfMonth();

        settlement.setTotalDailyAmount(BigDecimal.ZERO);
        settlement.setTotalOvertimeAmount(BigDecimal.ZERO);
        settlement.setTotalEarlyMorningAmount(BigDecimal.ZERO);
        settlement.setTotalNightAmount(BigDecimal.ZERO);
        settlement.setTotalOvernightAmount(BigDecimal.ZERO);

        for (SettlementDailyDetail detail : settlement.getDailyDetails()) {
            settlement.setTotalDailyAmount(settlement.getTotalDailyAmount().add(detail.getDailyAmount()));
            settlement.setTotalOvertimeAmount(settlement.getTotalOvertimeAmount().add(detail.getOvertimeAmount()));
            settlement.setTotalEarlyMorningAmount(settlement.getTotalEarlyMorningAmount().add(detail.getEarlyMorningAmount()));
            settlement.setTotalNightAmount(settlement.getTotalNightAmount().add(detail.getNightAmount()));
            settlement.setTotalOvernightAmount(settlement.getTotalOvernightAmount().add(detail.getOvernightAmount()));
        }

        BigDecimal totalWorkAmount = settlement.getTotalDailyAmount()
                .add(settlement.getTotalOvertimeAmount())
                .add(settlement.getTotalEarlyMorningAmount())
                .add(settlement.getTotalNightAmount())
                .add(settlement.getTotalOvernightAmount());

        settlement.setSupplyAmount(totalWorkAmount);
        settlement.setTaxAmount(totalWorkAmount.multiply(TAX_RATE).setScale(2, RoundingMode.HALF_UP));
        settlement.setTotalAmount(settlement.getSupplyAmount().add(settlement.getTaxAmount()));

        settlementRepository.save(settlement);
    }

    public SettlementResponse getSettlement(UUID id) {
        Settlement settlement = settlementRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Settlement not found: " + id));
        return SettlementResponse.fromEntity(settlement);
    }

    public Page<SettlementResponse> getSettlements(UUID supplierId, UUID bpCompanyId, String yearMonth, Pageable pageable) {
        Page<Settlement> page = settlementRepository.findByFilters(supplierId, bpCompanyId, yearMonth, pageable);
        return page.map(SettlementResponse::fromEntity);
    }

    public void sendSettlement(UUID settlementId, String bpEmailAddress) throws Exception {
        Settlement settlement = settlementRepository.findById(settlementId)
                .orElseThrow(() -> new RuntimeException("Settlement not found: " + settlementId));

        String pdfContent = pdfService.generatePdf(settlement);
        emailService.sendSettlementEmail(settlement, bpEmailAddress, pdfContent);

        settlement.setStatus(Settlement.SettlementStatus.SENT);
        settlement.setSentAt(LocalDateTime.now());
        settlementRepository.save(settlement);

        log.info("Settlement {} sent to {}", settlementId, bpEmailAddress);
    }

    public void markAsPaid(UUID settlementId) {
        Settlement settlement = settlementRepository.findById(settlementId)
                .orElseThrow(() -> new RuntimeException("Settlement not found: " + settlementId));

        settlement.setStatus(Settlement.SettlementStatus.PAID);
        settlement.setPaidAt(LocalDateTime.now());
        settlementRepository.save(settlement);

        log.info("Settlement {} marked as paid", settlementId);
    }

    public SettlementStatisticsResponse getSupplierStatistics(UUID supplierId) {
        Page<Settlement> settlements = settlementRepository.findBySupplierId(supplierId,
                org.springframework.data.domain.PageRequest.of(0, Integer.MAX_VALUE));

        BigDecimal totalAmount = settlementRepository.sumTotalAmountBySupplier(supplierId);
        if (totalAmount == null) {
            totalAmount = BigDecimal.ZERO;
        }

        List<Settlement> list = settlements.getContent();
        BigDecimal avgAmount = list.isEmpty() ? BigDecimal.ZERO :
                totalAmount.divide(new BigDecimal(list.size()), 2, RoundingMode.HALF_UP);

        BigDecimal maxAmount = list.stream()
                .map(Settlement::getTotalAmount)
                .max(BigDecimal::compareTo)
                .orElse(BigDecimal.ZERO);

        BigDecimal minAmount = list.stream()
                .map(Settlement::getTotalAmount)
                .min(BigDecimal::compareTo)
                .orElse(BigDecimal.ZERO);

        return SettlementStatisticsResponse.builder()
                .entityId(supplierId.toString())
                .entityType("SUPPLIER")
                .totalCount(list.size())
                .totalAmount(totalAmount)
                .averageAmount(avgAmount)
                .maxAmount(maxAmount)
                .minAmount(minAmount)
                .build();
    }

    public SettlementStatisticsResponse getBpStatistics(UUID bpCompanyId) {
        Page<Settlement> settlements = settlementRepository.findByBpCompanyId(bpCompanyId,
                org.springframework.data.domain.PageRequest.of(0, Integer.MAX_VALUE));

        BigDecimal totalAmount = settlementRepository.sumTotalAmountByBpCompany(bpCompanyId);
        if (totalAmount == null) {
            totalAmount = BigDecimal.ZERO;
        }

        List<Settlement> list = settlements.getContent();
        BigDecimal avgAmount = list.isEmpty() ? BigDecimal.ZERO :
                totalAmount.divide(new BigDecimal(list.size()), 2, RoundingMode.HALF_UP);

        BigDecimal maxAmount = list.stream()
                .map(Settlement::getTotalAmount)
                .max(BigDecimal::compareTo)
                .orElse(BigDecimal.ZERO);

        BigDecimal minAmount = list.stream()
                .map(Settlement::getTotalAmount)
                .min(BigDecimal::compareTo)
                .orElse(BigDecimal.ZERO);

        return SettlementStatisticsResponse.builder()
                .entityId(bpCompanyId.toString())
                .entityType("BP_COMPANY")
                .totalCount(list.size())
                .totalAmount(totalAmount)
                .averageAmount(avgAmount)
                .maxAmount(maxAmount)
                .minAmount(minAmount)
                .build();
    }

}
