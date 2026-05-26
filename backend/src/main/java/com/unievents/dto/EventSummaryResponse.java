package com.unievents.dto;

import com.unievents.model.enums.EventType;

import java.time.LocalDateTime;
import java.util.UUID;

public record EventSummaryResponse(
        UUID id,
        String title,
        LocalDateTime eventDate,
        String location,
        EventType type
) {}
