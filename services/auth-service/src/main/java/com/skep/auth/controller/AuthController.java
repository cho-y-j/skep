package com.skep.auth.controller;

import com.skep.auth.domain.entity.User;
import com.skep.auth.dto.request.FingerprintRegisterRequest;
import com.skep.auth.dto.request.LoginRequest;
import com.skep.auth.dto.request.RefreshTokenRequest;
import com.skep.auth.dto.request.RegisterRequest;
import com.skep.auth.dto.response.AuthResponse;
import com.skep.auth.dto.response.UserResponse;
import com.skep.auth.service.AuthService;
import com.skep.auth.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final UserService userService;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        log.info("Register request for email: {}", request.getEmail());
        AuthResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        log.info("Login request for email: {}", request.getEmail());
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refresh(@Valid @RequestBody RefreshTokenRequest request) {
        log.info("Token refresh request");
        AuthResponse response = authService.refresh(request.getRefreshToken());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(HttpServletRequest request) {
        String userId = request.getHeader("X-User-Id");
        if (userId != null) {
            authService.logout(UUID.fromString(userId));
            log.info("Logout successful for user: {}", userId);
        }
        return ResponseEntity.ok().build();
    }

    @GetMapping("/me")
    public ResponseEntity<UserResponse> getCurrentUser(HttpServletRequest request) {
        String userId = request.getHeader("X-User-Id");
        if (userId == null || userId.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        User user = authService.getUserById(UUID.fromString(userId));
        UserResponse response = UserResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .name(user.getName())
                .phone(user.getPhone())
                .role(user.getRole().name())
                .companyId(user.getCompany() != null ? user.getCompany().getId() : null)
                .companyName(user.getCompany() != null ? user.getCompany().getName() : null)
                .status(user.getStatus().name())
                .lastLoginAt(user.getLastLoginAt())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .build();

        return ResponseEntity.ok(response);
    }

    @GetMapping("/users")
    public ResponseEntity<List<UserResponse>> getAllUsers() {
        List<User> users = userService.getAllUsers();
        List<UserResponse> responses = users.stream()
                .map(user -> UserResponse.builder()
                        .id(user.getId())
                        .email(user.getEmail())
                        .name(user.getName())
                        .phone(user.getPhone())
                        .role(user.getRole().name())
                        .companyId(user.getCompany() != null ? user.getCompany().getId() : null)
                        .companyName(user.getCompany() != null ? user.getCompany().getName() : null)
                        .status(user.getStatus().name())
                        .lastLoginAt(user.getLastLoginAt())
                        .createdAt(user.getCreatedAt())
                        .updatedAt(user.getUpdatedAt())
                        .build())
                .collect(Collectors.toList());
        return ResponseEntity.ok(responses);
    }

    @PostMapping("/fingerprint/register")
    public ResponseEntity<Void> registerFingerprint(
            @Valid @RequestBody FingerprintRegisterRequest request,
            HttpServletRequest httpRequest) {
        String userId = httpRequest.getHeader("X-User-Id");
        if (userId == null || userId.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        userService.registerFingerprint(UUID.fromString(userId), request.getTemplate(), request.getFingerIndex());
        log.info("Fingerprint registered for user: {}, finger index: {}", userId, request.getFingerIndex());
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/validate")
    public ResponseEntity<Boolean> validateToken(@RequestParam String token) {
        boolean isValid = authService.validateToken(token);
        return ResponseEntity.ok(isValid);
    }
}
