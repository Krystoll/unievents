package com.unievents.dto;

import com.unievents.model.enums.EventType;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record EventResponse(
        UUID id,
        String title,
        String description,
        LocalDateTime eventDate,
        String location,
        Integer maxParticipants,
        EventType type,
        Integer currentParticipants,
        Integer waitlistCount,
        List<EventFieldResponse> fields
) {}
