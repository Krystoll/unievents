package com.unievents.dto;

import com.unievents.model.enums.RegistrationStatus;

import java.util.UUID;

public record MyRegistrationResponse(
        UUID registrationId,
        EventSummaryResponse event,
        RegistrationStatus status,
        Integer queuePosition
) {}
