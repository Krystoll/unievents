package com.unievents.dto;

import java.util.List;

public record RegisterEventRequest(
        List<AnswerRequest> answers
) {
    public RegisterEventRequest {
        if (answers == null) {
            answers = List.of();
        }
    }
}
