package com.unievents.controller;

import com.unievents.dto.request.*;
import com.unievents.dto.response.AuthResponse;
import com.unievents.model.User;
import com.unievents.model.enums.Role;
import com.unievents.repository.UserRepository;
import com.unievents.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authManager;
    private final JwtUtil jwtUtil;

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest req) {
        if (userRepository.findByEmail(req.email()).isPresent())
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Email уже занят"));

        User user = User.builder()
                .name(req.name())
                .email(req.email())
                .password(passwordEncoder.encode(req.password()))
                .role(req.role() != null ? req.role() : Role.STUDENT)
                .reliabilityScore(100.0f)
                .attendedCount(0)
                .noShowCount(0)
                .build();
        userRepository.save(user);

        return ResponseEntity.ok(buildAuthResponse(user));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest req) {
        try {
            authManager.authenticate(
                    new UsernamePasswordAuthenticationToken(req.email(), req.password()));
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(401)
                    .body(Map.of("error", "Неверный email или пароль"));
        }
        User user = userRepository.findByEmail(req.email()).orElseThrow();
        return ResponseEntity.ok(buildAuthResponse(user));
    }

    @GetMapping("/me")
    public ResponseEntity<?> me(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(new AuthResponse.UserDto(
                user.getId(), user.getName(), user.getEmail(),
                user.getRole(), user.getReliabilityScore()));
    }

    private AuthResponse buildAuthResponse(User user) {
        String token = jwtUtil.generateToken(user.getEmail());
        return new AuthResponse(token, new AuthResponse.UserDto(
                user.getId(), user.getName(), user.getEmail(),
                user.getRole(), user.getReliabilityScore()));
    }
}