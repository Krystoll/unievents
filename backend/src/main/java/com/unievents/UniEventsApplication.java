package com.unievents;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class UniEventsApplication {
    public static void main(String[] args) {
        SpringApplication.run(UniEventsApplication.class, args);
    }
}