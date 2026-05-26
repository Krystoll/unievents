package com.unievents.dto.response;

import java.time.Instant;

public record QrTokenResponse(
        String qrToken,
        long expiresInSeconds,
        Instant expiresAt
) {}
