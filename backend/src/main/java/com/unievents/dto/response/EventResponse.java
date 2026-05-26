package com.unievents.dto.response;

import com.unievents.model.enums.EventType;
import java.time.LocalDateTime;
import java.util.*;

public record EventResponse(
        UUID id,
        String title,
        String description,
        LocalDateTime eventDate,
        String location,
        Integer maxParticipants,
        Integer currentParticipants,
        Integer waitlistCount,
        EventType type,
        List<FieldDto> fields
) {
    public record FieldDto(UUID id, String fieldName, Boolean required) {}
}