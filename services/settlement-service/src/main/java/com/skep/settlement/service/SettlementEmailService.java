package com.skep.settlement.service;

import com.skep.settlement.entity.Settlement;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import java.util.Base64;

@Service
@RequiredArgsConstructor
@Slf4j
public class SettlementEmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.from:noreply@skep.com}")
    private String fromEmail;

    public void sendSettlementEmail(Settlement settlement, String toEmail, String pdfContent) throws MessagingException {
        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

        helper.setFrom(fromEmail);
        helper.setTo(toEmail);
        helper.setSubject("정산명세서 - " + settlement.getYearMonth());

        String emailBody = buildEmailBody(settlement);
        helper.setText(emailBody, true);

        byte[] pdfBytes = Base64.getDecoder().decode(pdfContent);
        helper.addAttachment("settlement_" + settlement.getId() + ".pdf",
                new ByteArrayResource(pdfBytes), "application/pdf");

        mailSender.send(message);
        log.info("Settlement email sent to {}", toEmail);
    }

    private String buildEmailBody(Settlement settlement) {
        return "<html>" +
                "<body style='font-family: Arial, sans-serif;'>" +
                "<h2>정산명세서</h2>" +
                "<p>기간: " + settlement.getYearMonth() + "</p>" +
                "<table style='border-collapse: collapse; width: 100%;'>" +
                "<tr style='background-color: #f0f0f0;'>" +
                "<td style='border: 1px solid #ddd; padding: 10px;'>공급가액</td>" +
                "<td style='border: 1px solid #ddd; padding: 10px; text-align: right;'>" +
                settlement.getSupplyAmount() + "</td>" +
                "</tr>" +
                "<tr>" +
                "<td style='border: 1px solid #ddd; padding: 10px;'>세액(10%)</td>" +
                "<td style='border: 1px solid #ddd; padding: 10px; text-align: right;'>" +
                settlement.getTaxAmount() + "</td>" +
                "</tr>" +
                "<tr style='background-color: #f0f0f0;'>" +
                "<td style='border: 1px solid #ddd; padding: 10px;'><strong>합계</strong></td>" +
                "<td style='border: 1px solid #ddd; padding: 10px; text-align: right;'><strong>" +
                settlement.getTotalAmount() + "</strong></td>" +
                "</tr>" +
                "</table>" +
                "<p>첨부파일을 확인해주시기 바랍니다.</p>" +
                "</body>" +
                "</html>";
    }

    private static class ByteArrayResource extends org.springframework.core.io.ByteArrayResource {
        private final String filename;

        public ByteArrayResource(byte[] byteArray) {
            super(byteArray);
            this.filename = null;
        }

        @Override
        public String getFilename() {
            return filename;
        }
    }

}
