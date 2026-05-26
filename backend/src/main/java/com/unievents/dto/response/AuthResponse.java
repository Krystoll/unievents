package com.unievents.dto.response;

import com.unievents.model.enums.Role;
import java.util.UUID;

public record AuthResponse(String token, UserDto user) {

    public record UserDto(
            UUID id,
            String name,
            String email,
            Role role,
            Float reliabilityScore
    ) {}
}