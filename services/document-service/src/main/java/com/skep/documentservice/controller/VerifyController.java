package com.skep.documentservice.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.skep.documentservice.service.LiftonVerifyClient;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/documents/verify")
@RequiredArgsConstructor
public class VerifyController {

    private final LiftonVerifyClient verifyClient;

    @PostMapping("/driver-license")
    public ResponseEntity<JsonNode> verifyDriverLicense(@RequestBody Map<String, String> body) {
        String licenseNumber = body.get("licenseNumber");
        String name = body.get("name");
        JsonNode result = verifyClient.verifyDriverLicense(licenseNumber, name);
        return ResponseEntity.ok(result);
    }

    @PostMapping("/business-registration")
    public ResponseEntity<JsonNode> verifyBusinessRegistration(@RequestBody Map<String, String> body) {
        String businessNumber = body.get("businessNumber");
        JsonNode result = verifyClient.verifyBusinessRegistration(businessNumber);
        return ResponseEntity.ok(result);
    }

    @PostMapping("/cargo")
    public ResponseEntity<JsonNode> verifyCargo(@RequestBody Map<String, String> body) {
        JsonNode result = verifyClient.verifyCargo(
                body.get("name"), body.get("birth"), body.get("lcnsNo"));
        return ResponseEntity.ok(result);
    }
}
