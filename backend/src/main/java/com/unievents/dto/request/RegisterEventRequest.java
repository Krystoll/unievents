package com.unievents.dto.request;

import java.util.List;
import java.util.UUID;

public record RegisterEventRequest(List<AnswerRequest> answers) {
    public record AnswerRequest(UUID fieldId, String answer) {}
}