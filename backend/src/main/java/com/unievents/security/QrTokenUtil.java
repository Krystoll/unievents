package com.unievents.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;
import java.util.Optional;
import java.util.UUID;

@Component
public class QrTokenUtil {

    public static final String CLAIM_TYPE = "qr";

    @Value("${jwt.secret}")
    private String secret;

    /** Время жизни QR-кода в миллисекундах (по умолчанию 2 минуты). */
    @Value("${jwt.qr.expiration:120000}")
    private long qrExpirationMs;

    private Key signingKey() {
        return Keys.hmacShaKeyFor(secret.getBytes());
    }

    public long getExpirationSeconds() {
        return qrExpirationMs / 1000;
    }

    public String generate(UUID userId) {
        Date now = new Date();
        return Jwts.builder()
                .setSubject(userId.toString())
                .claim("type", CLAIM_TYPE)
                .setIssuedAt(now)
                .setExpiration(new Date(now.getTime() + qrExpirationMs))
                .signWith(signingKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    public enum Status { VALID, EXPIRED, INVALID }

    public record ValidationResult(Status status, UUID userId) {}

    public ValidationResult validate(String token) {
        if (token == null || token.isBlank()) {
            return new ValidationResult(Status.INVALID, null);
        }
        try {
            Claims claims = Jwts.parserBuilder()
                    .setSigningKey(signingKey())
                    .build()
                    .parseClaimsJws(token.trim())
                    .getBody();
            if (!CLAIM_TYPE.equals(claims.get("type"))) {
                return new ValidationResult(Status.INVALID, null);
            }
            return new ValidationResult(Status.VALID, UUID.fromString(claims.getSubject()));
        } catch (ExpiredJwtException e) {
            return new ValidationResult(Status.EXPIRED, null);
        } catch (JwtException | IllegalArgumentException e) {
            return new ValidationResult(Status.INVALID, null);
        }
    }

    public Optional<UUID> extractUserId(String token) {
        ValidationResult result = validate(token);
        return result.status() == Status.VALID
                ? Optional.of(result.userId())
                : Optional.empty();
    }
}
