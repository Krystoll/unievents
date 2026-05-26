package com.unievents.dto;

import java.util.UUID;

public record ScanRequest(
        UUID userId,
        UUID eventId
) {}
