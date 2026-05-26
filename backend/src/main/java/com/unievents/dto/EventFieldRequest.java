package com.unievents.dto;

public record EventFieldRequest(
        String fieldName,
        Boolean required
) {}
