package com.unievents;

import com.unievents.model.User;
import com.unievents.model.enums.Role;
import com.unievents.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        createIfAbsent("Admin",   "admin@uni.ru",   "admin123",   Role.ADMIN);
        createIfAbsent("Checker", "checker@uni.ru", "checker123", Role.CHECKER);
    }

    private void createIfAbsent(String name, String email,
                                String password, Role role) {
        if (userRepository.findByEmail(email).isEmpty()) {
            userRepository.save(User.builder()
                    .name(name)
                    .email(email)
                    .password(passwordEncoder.encode(password))
                    .role(role)
                    .reliabilityScore(100.0f)
                    .attendedCount(0)
                    .noShowCount(0)
                    .build());
        }
    }
}