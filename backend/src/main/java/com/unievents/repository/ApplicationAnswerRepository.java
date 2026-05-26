package com.unievents.repository;

import com.unievents.model.*;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;

public interface ApplicationAnswerRepository extends JpaRepository<ApplicationAnswer, UUID> {
    List<ApplicationAnswer> findByRegistration(Registration registration);

    boolean existsByField_Event(Event event);
}