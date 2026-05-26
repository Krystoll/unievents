package com.unievents.dto;

import java.util.UUID;

public record EventFieldResponse(
        UUID id,
        String fieldName,
        Boolean required
) {}
