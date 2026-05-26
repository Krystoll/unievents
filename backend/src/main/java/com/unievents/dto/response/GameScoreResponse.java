package com.unievents.dto.response;

import com.unievents.model.enums.GameType;

import java.time.LocalDateTime;
import java.util.UUID;

public record GameScoreResponse(
        UUID id,
        GameType gameType,
        Integer score,
        Long durationMs,
        Integer progress,
        Boolean completed,
        LocalDateTime playedAt
) {}
