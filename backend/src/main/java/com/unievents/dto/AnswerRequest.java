package com.unievents.dto;

import java.util.UUID;

public record AnswerRequest(
        UUID fieldId,
        String answer
) {}
