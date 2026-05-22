package com.unievents.exception;

import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import java.util.Arrays;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<?> notFound(NotFoundException e) {
        return ResponseEntity.status(404).body(Map.of("error", e.getMessage()));
    }

    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<?> badRequest(BadRequestException e) {
        return ResponseEntity.status(400).body(Map.of("error", e.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<?> general(Exception e) {
        // ВАЖНО: выводим ошибку в консоль!
        System.err.println("=== ОШИБКА ===");
        e.printStackTrace(System.err);

        return ResponseEntity.status(500).body(Map.of(
                "error", "Внутренняя ошибка сервера",
                "details", e.getClass().getSimpleName() + ": " + e.getMessage()
        ));
    }
}