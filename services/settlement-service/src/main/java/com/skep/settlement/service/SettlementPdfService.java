package com.skep.settlement.service;

import com.itextpdf.text.*;
import com.itextpdf.text.pdf.PdfPCell;
import com.itextpdf.text.pdf.PdfPTable;
import com.itextpdf.text.pdf.PdfWriter;
import com.skep.settlement.entity.Settlement;
import com.skep.settlement.entity.SettlementDailyDetail;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.text.DecimalFormat;
import java.util.Base64;
import java.util.List;

@Service
@Slf4j
public class SettlementPdfService {

    private static final DecimalFormat CURRENCY_FORMAT = new DecimalFormat("#,##0.00");

    public String generatePdf(Settlement settlement) throws DocumentException, IOException {
        Document document = new Document(PageSize.A4);
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        PdfWriter.getInstance(document, outputStream);

        document.open();

        addHeader(document, settlement);
        addSummary(document, settlement);
        addDailyDetailsTable(document, settlement);
        addFooter(document);

        document.close();

        byte[] pdfBytes = outputStream.toByteArray();
        return Base64.getEncoder().encodeToString(pdfBytes);
    }

    private void addHeader(Document document, Settlement settlement) throws DocumentException {
        Paragraph header = new Paragraph("정산 명세서");
        header.setAlignment(Element.ALIGN_CENTER);
        Font headerFont = new Font(Font.FontFamily.HELVETICA, 18, Font.BOLD);
        header.setFont(headerFont);
        document.add(header);

        Paragraph period = new Paragraph("기간: " + settlement.getYearMonth());
        period.setAlignment(Element.ALIGN_CENTER);
        document.add(period);

        document.add(new Paragraph("\n"));
    }

    private void addSummary(Document document, Settlement settlement) throws DocumentException {
        PdfPTable summaryTable = new PdfPTable(2);
        summaryTable.setWidthPercentage(100);

        addSummaryRow(summaryTable, "공급가액", settlement.getSupplyAmount().toString());
        addSummaryRow(summaryTable, "세액(10%)", settlement.getTaxAmount().toString());
        addSummaryRow(summaryTable, "합계", settlement.getTotalAmount().toString());

        document.add(summaryTable);
        document.add(new Paragraph("\n"));
    }

    private void addSummaryRow(PdfPTable table, String label, String value) {
        PdfPCell labelCell = new PdfPCell(new Phrase(label));
        labelCell.setBackgroundColor(BaseColor.LIGHT_GRAY);
        table.addCell(labelCell);

        PdfPCell valueCell = new PdfPCell(new Phrase(value));
        valueCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
        table.addCell(valueCell);
    }

    private void addDailyDetailsTable(Document document, Settlement settlement) throws DocumentException {
        List<SettlementDailyDetail> dailyDetails = settlement.getDailyDetails();

        if (dailyDetails.isEmpty()) {
            document.add(new Paragraph("일별 상세내역이 없습니다."));
            return;
        }

        PdfPTable table = new PdfPTable(11);
        table.setWidthPercentage(100);

        String[] headers = {
                "작업일자", "일급", "연장시간", "연장비", "새벽근무", "야간시간", "야간비", "철야", "철야비", "합계", ""
        };

        for (String header : headers) {
            PdfPCell cell = new PdfPCell(new Phrase(header));
            cell.setBackgroundColor(BaseColor.LIGHT_GRAY);
            cell.setHorizontalAlignment(Element.ALIGN_CENTER);
            table.addCell(cell);
        }

        for (SettlementDailyDetail detail : dailyDetails) {
            table.addCell(detail.getWorkDate().toString());
            table.addCell(formatAmount(detail.getDailyAmount()));
            table.addCell(formatDecimal(detail.getOvertimeHours()));
            table.addCell(formatAmount(detail.getOvertimeAmount()));
            table.addCell(detail.getEarlyMorningCount().toString());
            table.addCell(formatDecimal(detail.getNightHours()));
            table.addCell(formatAmount(detail.getNightAmount()));
            table.addCell(detail.getIsOvernight() ? "O" : "");
            table.addCell(formatAmount(detail.getOvernightAmount()));
            table.addCell(formatAmount(detail.getDayTotal()));
            table.addCell("");
        }

        document.add(table);
    }

    private void addFooter(Document document) throws DocumentException {
        Paragraph footer = new Paragraph("이 명세서는 자동으로 생성되었습니다.");
        footer.setAlignment(Element.ALIGN_CENTER);
        footer.setFont(new Font(Font.FontFamily.HELVETICA, 10, Font.ITALIC));
        document.add(new Paragraph("\n"));
        document.add(footer);
    }

    private String formatAmount(Object value) {
        if (value == null) {
            return "0.00";
        }
        return CURRENCY_FORMAT.format(value);
    }

    private String formatDecimal(Object value) {
        if (value == null) {
            return "0.00";
        }
        return value.toString();
    }

}
