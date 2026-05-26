package com.unievents.dto.request;

import com.unievents.model.enums.EventType;
import java.time.LocalDateTime;
import java.util.List;

public record EventRequest(
        String title,
        String description,
        LocalDateTime eventDate,
        String location,
        Integer maxParticipants,
        EventType type,
        List<FieldRequest> fields
) {
    public record FieldRequest(String fieldName, Boolean required) {}
}