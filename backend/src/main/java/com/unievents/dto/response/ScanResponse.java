package com.unievents.dto.response;

public record ScanResponse(
        boolean allowed,
        String userName,
        String eventTitle,
        String message
) {}