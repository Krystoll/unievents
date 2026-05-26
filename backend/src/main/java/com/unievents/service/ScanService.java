package com.unievents.service;

import com.unievents.dto.request.ScanRequest;
import com.unievents.dto.response.ScanResponse;
import com.unievents.exception.NotFoundException;
import com.unievents.model.*;
import com.unievents.model.enums.RegistrationStatus;
import com.unievents.repository.*;
import com.unievents.security.QrTokenUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ScanService {

    private final QrTokenUtil qrTokenUtil;
    private final UserRepository userRepository;
    private final EventRepository eventRepository;
    private final RegistrationRepository registrationRepository;

    @Transactional
    public ScanResponse scan(ScanRequest req) {
        Event event = eventRepository.findById(req.eventId())
                .orElseThrow(() -> new NotFoundException("Мероприятие не найдено"));
        String eventTitle = event.getTitle();

        QrTokenUtil.ValidationResult qr = qrTokenUtil.validate(req.qrToken());
        if (qr.status() == QrTokenUtil.Status.EXPIRED) {
            return new ScanResponse(false, "", eventTitle,
                    "QR-код устарел. Попросите студента обновить код в приложении");
        }
        if (qr.status() == QrTokenUtil.Status.INVALID) {
            return new ScanResponse(false, "", eventTitle,
                    "QR-код недействителен");
        }

        User student = userRepository.findById(qr.userId())
                .orElseThrow(() -> new NotFoundException("Пользователь не найден"));

        String userName = student.getName();

        Optional<Registration> regOpt =
                registrationRepository.findByUserAndEvent(student, event);

        if (regOpt.isEmpty()) {
            return new ScanResponse(false, userName, eventTitle,
                    "Вход запрещён — студент не записан на мероприятие");
        }

        Registration reg = regOpt.get();

        return switch (reg.getStatus()) {
            case ATTENDED -> new ScanResponse(false, userName, eventTitle,
                    "Этот студент уже проходил");
            case REGISTERED -> {
                reg.setStatus(RegistrationStatus.ATTENDED);
                reg.setAttendedAt(LocalDateTime.now());
                registrationRepository.save(reg);
                student.setAttendedCount(student.getAttendedCount() + 1);
                userRepository.save(student);
                yield new ScanResponse(true, userName, eventTitle, "Вход разрешён");
            }
            default -> new ScanResponse(false, userName, eventTitle,
                    "Вход запрещён — заявка не подтверждена");
        };
    }
}