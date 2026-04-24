package com.skep.documentservice.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.skep.documentservice.service.WorksheetEditorService;
import com.skep.documentservice.service.WorksheetMailService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Map;

@RestController
@RequestMapping("/api/worksheet")
@RequiredArgsConstructor
public class WorksheetEditorController {

    private final WorksheetEditorService editorService;
    private final WorksheetMailService mailService;

    private static ResponseEntity<byte[]> attachment(byte[] bytes, String name, String ext, MediaType type) {
        String dn = URLEncoder.encode((name != null ? name : "worksheet") + "." + ext,
                StandardCharsets.UTF_8).replace("+", "%20");
        return ResponseEntity.ok()
                .contentType(type)
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename*=UTF-8''" + dn)
                .body(bytes);
    }

    @PostMapping(value = "/editor-session", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, Object>> createSession(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "name", required = false) String baseName,
            @RequestParam(value = "userName", required = false) String userName
    ) throws Exception {
        return ResponseEntity.ok(editorService.createSession(file, userName, baseName));
    }

    @GetMapping("/editor-file/{sessionId}")
    public ResponseEntity<byte[]> getFile(@PathVariable String sessionId) throws Exception {
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.wordprocessingml.document"))
                .body(editorService.readSession(sessionId));
    }

    @PostMapping("/onlyoffice-callback/{sessionId}")
    public ResponseEntity<Map<String, Object>> callback(@PathVariable String sessionId,
                                                         @RequestBody JsonNode body) {
        return ResponseEntity.ok(editorService.handleCallback(sessionId, body));
    }

    @GetMapping("/editor-session/{sessionId}/download")
    public ResponseEntity<byte[]> download(@PathVariable String sessionId,
                                           @RequestParam(value = "name", required = false) String name) throws Exception {
        return attachment(editorService.readSession(sessionId), name, "docx",
                MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.wordprocessingml.document"));
    }

    @GetMapping("/editor-session/{sessionId}/pdf")
    public ResponseEntity<byte[]> downloadPdf(@PathVariable String sessionId,
                                               @RequestParam(value = "name", required = false) String name) throws Exception {
        byte[] docx = editorService.readSession(sessionId);
        byte[] pdf = mailService.convertDocxToPdf(docx, name != null ? name : "worksheet");
        return attachment(pdf, name, "pdf", MediaType.APPLICATION_PDF);
    }
}
