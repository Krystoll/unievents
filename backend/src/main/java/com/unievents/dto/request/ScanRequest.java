package com.unievents.dto.request;

import java.util.UUID;

public record ScanRequest(UUID userId, UUID eventId) {}