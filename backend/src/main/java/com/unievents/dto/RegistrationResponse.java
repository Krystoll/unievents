package com.unievents.dto;

import com.unievents.model.enums.RegistrationStatus;

public record RegistrationResponse(
        RegistrationStatus status,
        Integer queuePosition,
        String message
) {}
