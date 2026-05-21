package com.unievents.dto.response;

import com.unievents.model.enums.RegistrationStatus;

public record RegistrationResponse(
        RegistrationStatus status,
        Integer queuePosition,
        String message
) {}