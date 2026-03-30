package com.skep.auth.service;

import com.skep.auth.domain.entity.RefreshToken;
import com.skep.auth.domain.entity.User;
import com.skep.auth.domain.enums.UserRole;
import com.skep.auth.dto.request.LoginRequest;
import com.skep.auth.dto.request.RegisterRequest;
import com.skep.auth.dto.response.AuthResponse;
import com.skep.auth.repository.RefreshTokenRepository;
import com.skep.auth.repository.UserRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;

    @Value("${jwt.refresh-expiration}")
    private long refreshExpiration;

    public AuthResponse register(RegisterRequest request) {
        // 이메일 중복 확인
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new IllegalArgumentException("Email already exists");
        }

        // 사용자 생성
        User user = User.builder()
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .name(request.getName())
                .phone(request.getPhone())
                .role(UserRole.fromString(request.getRole()))
                .status(User.UserStatus.ACTIVE)
                .build();

        User savedUser = userRepository.save(user);
        log.info("User registered successfully: {}", savedUser.getEmail());

        // 토큰 생성
        String accessToken = jwtService.generateAccessToken(savedUser);
        String refreshToken = generateAndSaveRefreshToken(savedUser);

        return AuthResponse.builder()
                .userId(savedUser.getId())
                .email(savedUser.getEmail())
                .name(savedUser.getName())
                .role(savedUser.getRole().name())
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .expiresIn(jwtService.getExpirationTime())
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        // 사용자 조회
        User user = userRepository.findActiveUserByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("Invalid email or password"));

        // 비밀번호 확인
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Invalid email or password");
        }

        // 마지막 로그인 시간 업데이트
        user.setLastLoginAt(LocalDateTime.now());
        userRepository.save(user);
        log.info("User logged in successfully: {}", user.getEmail());

        // 기존 refresh token 모두 revoke
        refreshTokenRepository.revokeAllUserTokens(user.getId());

        // 토큰 생성
        String accessToken = jwtService.generateAccessToken(user);
        String refreshToken = generateAndSaveRefreshToken(user);

        return AuthResponse.builder()
                .userId(user.getId())
                .email(user.getEmail())
                .name(user.getName())
                .role(user.getRole().name())
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .expiresIn(jwtService.getExpirationTime())
                .build();
    }

    public AuthResponse refresh(String refreshToken) {
        // refresh token 검증
        RefreshToken token = refreshTokenRepository.findByToken(refreshToken)
                .orElseThrow(() -> new IllegalArgumentException("Invalid refresh token"));

        if (!token.isValid()) {
            throw new IllegalArgumentException("Refresh token is expired or revoked");
        }

        User user = token.getUser();

        // 새로운 토큰 생성
        String newAccessToken = jwtService.generateAccessToken(user);
        String newRefreshToken = generateAndSaveRefreshToken(user);

        // 이전 refresh token 취소
        token.setRevoked(true);
        token.setRevokedAt(LocalDateTime.now());
        refreshTokenRepository.save(token);

        log.info("Token refreshed for user: {}", user.getEmail());

        return AuthResponse.builder()
                .userId(user.getId())
                .email(user.getEmail())
                .name(user.getName())
                .role(user.getRole().name())
                .accessToken(newAccessToken)
                .refreshToken(newRefreshToken)
                .expiresIn(jwtService.getExpirationTime())
                .build();
    }

    public void logout(UUID userId) {
        // 사용자의 모든 refresh token 취소
        refreshTokenRepository.revokeAllUserTokens(userId);
        log.info("User logged out: {}", userId);
    }

    public boolean validateToken(String token) {
        try {
            jwtService.validateToken(token);
            return true;
        } catch (JwtException e) {
            log.warn("Token validation failed: {}", e.getMessage());
            return false;
        }
    }

    public User getUserById(UUID userId) {
        return userRepository.findActiveUserById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
    }

    public User getUserByEmail(String email) {
        return userRepository.findActiveUserByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
    }

    private String generateAndSaveRefreshToken(User user) {
        String refreshTokenValue = jwtService.generateRefreshToken(user);

        RefreshToken refreshToken = RefreshToken.builder()
                .user(user)
                .token(refreshTokenValue)
                .expiresAt(jwtService.getExpirationDateTime(refreshExpiration))
                .revoked(false)
                .build();

        refreshTokenRepository.save(refreshToken);
        return refreshTokenValue;
    }

    public Claims validateTokenAndGetClaims(String token) {
        return jwtService.validateToken(token);
    }

    public UUID extractUserIdFromToken(String token) {
        return jwtService.extractUserId(token);
    }

    public UserRole extractRoleFromToken(String token) {
        return jwtService.extractRole(token);
    }
}
