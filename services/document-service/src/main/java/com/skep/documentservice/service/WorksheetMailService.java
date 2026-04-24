package com.skep.documentservice.service;

import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class WorksheetMailService {

    private final JavaMailSender mailSender;

    @Value("${MAIL_USERNAME:}")
    private String defaultFrom;

    private static final String PDF_EXPORT_FILTER = "pdf:writer_pdf_Export:"
            + "{\"ReduceImageResolution\":{\"type\":\"boolean\",\"value\":\"true\"},"
            + "\"MaxImageResolution\":{\"type\":\"long\",\"value\":\"150\"},"
            + "\"UseLosslessCompression\":{\"type\":\"boolean\",\"value\":\"false\"},"
            + "\"Quality\":{\"type\":\"long\",\"value\":\"80\"}}";

    // DOCX 바이트를 LibreOffice로 PDF 변환.
    // UserInstallation 을 요청별 임시 디렉토리로 분리 — 동시 실행 시 기본 프로파일 락 충돌 방지
    public byte[] convertDocxToPdf(byte[] docxBytes, String baseName) throws IOException, InterruptedException {
        Path workDir = Files.createTempDirectory("skep-pdf-");
        try {
            String safeName = (baseName == null || baseName.isBlank()) ? "worksheet"
                    : baseName.replaceAll("[^\\p{L}\\p{N}_-]", "_");
            Path docxFile = workDir.resolve(safeName + ".docx");
            Files.write(docxFile, docxBytes);

            String userProfile = "-env:UserInstallation=file://" + workDir.resolve("lo-profile");
            ProcessBuilder pb = new ProcessBuilder(
                    "libreoffice", userProfile, "--headless", "--nologo", "--nofirststartwizard",
                    "--convert-to", PDF_EXPORT_FILTER, "--outdir", workDir.toString(), docxFile.toString());
            pb.redirectErrorStream(true);
            Process p = pb.start();
            String output = new String(p.getInputStream().readAllBytes());
            if (!p.waitFor(90, java.util.concurrent.TimeUnit.SECONDS)) {
                p.destroyForcibly();
                throw new IOException("LibreOffice 변환 타임아웃");
            }
            if (p.exitValue() != 0) {
                throw new IOException("LibreOffice 변환 실패 (code=" + p.exitValue() + "): " + output);
            }
            Path pdfFile = workDir.resolve(safeName + ".pdf");
            return Files.readAllBytes(pdfFile);
        } finally {
            try (var stream = Files.walk(workDir)) {
                stream.sorted((a, b) -> b.compareTo(a))
                        .forEach(f -> { try { Files.deleteIfExists(f); } catch (IOException ignored) {} });
            } catch (IOException ignored) { /* best-effort cleanup */ }
        }
    }

    // 작업계획서 DOCX → PDF → 이메일 발송
    public byte[] sendWorksheetPdf(MultipartFile docxFile, String from, String to,
                                    String subject, String bodyText, String baseName)
            throws Exception {
        if (docxFile == null || docxFile.isEmpty()) {
            throw new IllegalArgumentException("DOCX 파일이 필요합니다");
        }
        if (to == null || to.isBlank()) {
            throw new IllegalArgumentException("받는 사람 이메일이 필요합니다");
        }
        // 네이버 SMTP는 From이 반드시 계정 본인이어야 함(554 unauthorized).
        // 사용자가 입력한 from은 Reply-To로 사용하고, 실제 발신자는 defaultFrom으로 강제.
        if (defaultFrom == null || defaultFrom.isBlank()) {
            throw new IllegalArgumentException("SMTP 발신 계정이 설정되지 않았습니다 (MAIL_USERNAME 미설정)");
        }
        String replyTo = (from == null || from.isBlank()) ? null : from.trim();
        String safeBase = (baseName == null || baseName.isBlank()) ? "작업계획서_" + UUID.randomUUID().toString().substring(0, 6) : baseName;

        byte[] pdf = convertDocxToPdf(docxFile.getBytes(), safeBase);

        MimeMessage msg = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(msg, true, "UTF-8");
        helper.setFrom(defaultFrom);
        if (replyTo != null && !replyTo.equalsIgnoreCase(defaultFrom)) {
            helper.setReplyTo(replyTo);
        }
        for (String t : to.split("[,;\\s]+")) {
            if (!t.isBlank()) helper.addTo(t.trim());
        }
        helper.setSubject(subject == null || subject.isBlank() ? "[SKEP] " + safeBase : subject);
        helper.setText(bodyText == null ? "" : bodyText, false);
        helper.addAttachment(safeBase + ".pdf", new ByteArrayResource(pdf));

        mailSender.send(msg);
        log.info("Worksheet PDF mail sent: from={} replyTo={} to={} subject={} pdfSize={}", defaultFrom, replyTo, to, subject, pdf.length);

        return pdf;
    }
}
