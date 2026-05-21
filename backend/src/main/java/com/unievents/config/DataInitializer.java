package com.unievents.config;

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
        createUserIfAbsent("admin@uni.ru", "admin123", "Администратор", Role.ADMIN);
        createUserIfAbsent("checker@uni.ru", "checker123", "Чекер", Role.CHECKER);
    }

    private void createUserIfAbsent(String email, String password, String name, Role role) {
        if (userRepository.existsByEmail(email)) {
            return;
        }

        User user = User.builder()
                .name(name)
                .email(email)
                .password(passwordEncoder.encode(password))
                .role(role)
                .build();

        userRepository.save(user);
    }
}
