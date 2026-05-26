package com.unievents.dto;

public record ScanResponse(
        boolean allowed,
        String userName,
        String eventTitle,
        String message
) {}
