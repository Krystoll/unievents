package com.unievents.dto.response;

import com.unievents.model.enums.GameType;

public record GameTypeStatsResponse(
        GameType gameType,
        long gamesPlayed,
        int bestScore,
        double averageScore,
        int lastScore,
        Long lastDurationMs,
        Integer lastProgress,
        Boolean lastCompleted
) {}
