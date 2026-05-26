package com.unievents.dto.request;

import java.util.UUID;

public record ScanRequest(String qrToken, UUID eventId) {}