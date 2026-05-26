package com.unievents.dto.response;

import com.unievents.model.enums.GameType;

import java.time.LocalDateTime;
import java.util.UUID;

public record LeaderboardEntryResponse(
        int rank,
        UUID userId,
        String userName,
        GameType gameType,
        int score,
        long durationMs,
        int progress,
        boolean completed,
        LocalDateTime playedAt
) {}
