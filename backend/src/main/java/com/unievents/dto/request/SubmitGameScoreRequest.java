package com.unievents.dto.request;

import com.unievents.model.enums.GameType;

import java.util.UUID;

public record SubmitGameScoreRequest(
        GameType gameType,
        Integer score,
        Long durationMs,
        Integer progress,
        Boolean completed,
        UUID eventId
) {}
