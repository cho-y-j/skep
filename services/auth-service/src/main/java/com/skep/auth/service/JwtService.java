package com.skep.auth.service;

import com.skep.auth.domain.entity.User;
import com.skep.auth.domain.enums.UserRole;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Date;
import java.util.UUID;

@Slf4j
@Service
public class JwtService {

    @Value("${jwt.secret}")
    private String jwtSecret;

    @Value("${jwt.expiration}")
    private long jwtExpiration;

    @Value("${jwt.refresh-expiration}")
    private long refreshExpiration;

    @Value("${jwt.issuer}")
    private String issuer;

    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(jwtSecret.getBytes());
    }

    public String generateAccessToken(User user) {
        var now = new Date();
        var expiry = new Date(now.getTime() + jwtExpiration);

        var claimsBuilder = Jwts.claims()
                .subject(user.getId().toString())
                .issuedAt(now)
                .expiration(expiry)
                .issuer(issuer)
                .add("role", user.getRole().name())
                .add("email", user.getEmail())
                .add("name", user.getName());

        if (user.getCompany() != null) {
            claimsBuilder.add("companyId", user.getCompany().getId().toString());
            claimsBuilder.add("companyName", user.getCompany().getName());
        }

        return Jwts.builder()
                .claims(claimsBuilder.build())
                .signWith(getSigningKey())
                .compact();
    }

    public String generateRefreshToken(User user) {
        var now = new Date();
        var expiry = new Date(now.getTime() + refreshExpiration);

        return Jwts.builder()
                .claims(Jwts.claims()
                        .subject(user.getId().toString())
                        .issuedAt(now)
                        .expiration(expiry)
                        .issuer(issuer)
                        .id(UUID.randomUUID().toString())
                        .add("type", "refresh")
                        .build())
                .signWith(getSigningKey())
                .compact();
    }

    public Claims validateToken(String token) throws JwtException {
        try {
            return Jwts.parser()
                    .verifyWith(getSigningKey())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
        } catch (JwtException e) {
            log.error("JWT validation failed: {}", e.getMessage());
            throw e;
        }
    }

    public UUID extractUserId(String token) throws JwtException {
        Claims claims = validateToken(token);
        return UUID.fromString(claims.getSubject());
    }

    public String extractEmail(String token) throws JwtException {
        Claims claims = validateToken(token);
        return claims.get("email", String.class);
    }

    public UserRole extractRole(String token) throws JwtException {
        Claims claims = validateToken(token);
        String roleStr = claims.get("role", String.class);
        return UserRole.fromString(roleStr);
    }

    public boolean isTokenExpired(String token) {
        try {
            Claims claims = validateToken(token);
            return claims.getExpiration().before(new Date());
        } catch (JwtException e) {
            return true;
        }
    }

    public long getExpirationTime() {
        return jwtExpiration;
    }

    public long getRefreshExpirationTime() {
        return refreshExpiration;
    }

    public LocalDateTime getExpirationDateTime(long expirationTime) {
        return LocalDateTime.ofInstant(
                new Date(System.currentTimeMillis() + expirationTime).toInstant(),
                ZoneId.systemDefault()
        );
    }

    public Claims getAllClaims(String token) throws JwtException {
        return validateToken(token);
    }
}
