package com.skep.documentservice.controller;

import com.skep.documentservice.service.WorksheetMailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/worksheet")
@RequiredArgsConstructor
public class WorksheetMailController {

    private final WorksheetMailService mailService;

    // DOCX만 업로드해서 PDF 받기 (다운로드용)
    @PostMapping(value = "/to-pdf", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<byte[]> toPdf(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "name", required = false) String baseName
    ) throws Exception {
        byte[] pdf = mailService.convertDocxToPdf(file.getBytes(),
                baseName != null ? baseName : "worksheet");
        String downloadName = URLEncoder.encode(
                (baseName != null ? baseName : "worksheet") + ".pdf",
                StandardCharsets.UTF_8).replace("+", "%20");
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename*=UTF-8''" + downloadName)
                .body(pdf);
    }

    // DOCX + 이메일 정보 → PDF 변환 후 메일 발송 + PDF 응답
    @PostMapping(value = "/send-pdf", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, Object>> sendPdf(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "from", required = false) String from,
            @RequestParam("to") String to,
            @RequestParam(value = "subject", required = false) String subject,
            @RequestParam(value = "body", required = false) String body,
            @RequestParam(value = "name", required = false) String baseName
    ) {
        try {
            byte[] pdf = mailService.sendWorksheetPdf(file, from, to, subject, body, baseName);
            return ResponseEntity.ok(Map.of(
                    "ok", true,
                    "to", to,
                    "pdfSize", pdf.length,
                    "message", "메일 발송 완료"
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "ok", false,
                    "message", e.getMessage()
            ));
        } catch (Exception e) {
            log.error("메일 발송 실패", e);
            return ResponseEntity.internalServerError().body(Map.of(
                    "ok", false,
                    "message", "메일 발송 실패: " + e.getMessage()
            ));
        }
    }
}
