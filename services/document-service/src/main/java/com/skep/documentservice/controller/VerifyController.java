package com.skep.documentservice.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.skep.documentservice.service.LiftonVerifyClient;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@RestController
@RequestMapping("/api/documents/verify")
@RequiredArgsConstructor
public class VerifyController {

    private final LiftonVerifyClient verifyClient;

    // 사업자등록: 국세청 NTS_API 연동
    @PostMapping("/business-registration")
    public ResponseEntity<JsonNode> verifyBusinessRegistration(@RequestBody Map<String, String> body) {
        // 국세청 API는 bizNo/startDate/ownerName 모두 필수. 누락 시 dummy 기본값으로 호출해서 NOT_MATCHED 응답 반환
        String ownerName = body.getOrDefault("ownerName", "");
        if (ownerName.isBlank()) ownerName = "미상";
        String startDate = body.getOrDefault("startDate", "");
        if (startDate.isBlank()) startDate = "19900101";
        JsonNode result = verifyClient.verifyBusinessRegistration(
                body.get("businessNumber"), startDate, ownerName
        );
        return ResponseEntity.ok(result);
    }

    // 운전면허: 도로교통공단 RIMS 연동
    @PostMapping("/driver-license")
    public ResponseEntity<JsonNode> verifyDriverLicense(@RequestBody Map<String, String> body) {
        // 면허번호 숫자만 추출 (21-08-003005-16 → 2108003005 16)
        String licNo = body.get("licenseNumber");
        if (licNo != null) licNo = licNo.replaceAll("[^0-9]", "");
        JsonNode result = verifyClient.verifyDriverLicense(
                licNo,
                body.get("name"),
                body.getOrDefault("birthDate", ""),
                body.getOrDefault("licenseTypeCode", body.getOrDefault("licenseConditionCode", ""))
        );
        return ResponseEntity.ok(result);
    }

    // 화물운송자격증
    @PostMapping("/cargo")
    public ResponseEntity<JsonNode> verifyCargo(@RequestBody Map<String, String> body) {
        JsonNode result = verifyClient.verifyCargo(
                body.get("name"),
                body.getOrDefault("birth", ""),
                body.getOrDefault("lcnsNo", body.getOrDefault("licenseNumber", ""))
        );
        return ResponseEntity.ok(result);
    }

    // KOSHA 안전보건교육 (파일 업로드)
    @PostMapping(value = "/kosha", consumes = "multipart/form-data")
    public ResponseEntity<JsonNode> verifyKosha(@RequestParam("file") MultipartFile file) throws IOException {
        JsonNode result = verifyClient.verifyKosha(file.getBytes(), file.getOriginalFilename());
        return ResponseEntity.ok(result);
    }

    // OCR 추출 — verify-api의 범용 OCR 엔진 (Google Vision 기반)
    // type: DRIVER_LICENSE / BUSINESS_REGISTRATION / KOSHA / CARGO 등
    @PostMapping(value = "/ocr/{type}", consumes = "multipart/form-data")
    public ResponseEntity<JsonNode> extractOcr(
            @PathVariable String type,
            @RequestParam("file") MultipartFile file) throws IOException {
        JsonNode result = verifyClient.extractOcr(type, file.getBytes(), file.getOriginalFilename());
        return ResponseEntity.ok(result);
    }
}
