import '../../core/api/auth_service.dart';
import '../../core/api/events_service.dart';
import '../../models/attendance.dart';
import '../../models/event.dart';
import '../../models/event_field.dart';
import '../../models/registration.dart';
import '../../models/user.dart';

class MockData {
  static const studentUser = User(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Иван Иванов',
    email: 'ivan@uni.ru',
    role: 'STUDENT',
    reliabilityScore: 87.5,
  );

  static const adminUser = User(
    id: '22222222-2222-2222-2222-222222222222',
    name: 'Админ Системы',
    email: 'admin@uni.ru',
    role: 'ADMIN',
    reliabilityScore: 100,
  );

  static const checkerUser = User(
    id: '33333333-3333-3333-3333-333333333333',
    name: 'Охранник Входа',
    email: 'checker@uni.ru',
    role: 'CHECKER',
    reliabilityScore: 100,
  );

  static final Event eventFree = Event(
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    title: 'Хакатон Spring 2025',
    description: 'Соревнование по разработке на Spring Boot.',
    eventDate: DateTime.now().add(const Duration(days: 2, hours: 10)),
    durationMinutes: 180,
    location: 'Аудитория 301',
    maxParticipants: 30,
    currentParticipants: 18,
    waitlistCount: 3,
    type: 'FREE',
    fields: const [],
  );

  static final Event eventApproval = Event(
    id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    title: 'Мастер-класс по Flutter',
    description: 'Только для студентов с подтверждением заявки.',
    eventDate: DateTime.now().add(const Duration(days: 5, hours: 14)),
    durationMinutes: 120,
    location: 'Лаборатория 205',
    maxParticipants: 20,
    currentParticipants: 12,
    waitlistCount: 1,
    type: 'APPROVAL',
    fields: const [
      EventField(id: 'f1f1f1f1-f1f1-f1f1-f1f1-f1f1f1f1f1f1', fieldName: 'Курс', required: true),
      EventField(id: 'f2f2f2f2-f2f2-f2f2-f2f2-f2f2f2f2f2f2', fieldName: 'Группа', required: true),
    ],
  );

  static List<Event> get events => [eventFree, eventApproval];

  static User userByEmail(String email) {
    if (email.contains('admin')) return adminUser;
    if (email.contains('checker')) return checkerUser;
    return studentUser;
  }

  static AuthResponse authResponse(User user) {
    return AuthResponse(token: 'mock-jwt-token-${user.role}', user: user);
  }

  static List<Registration> get myRegistrations => [
        Registration(
          registrationId: 'reg-11111111-1111-1111-1111-111111111111',
          event: Event(
            id: eventFree.id,
            title: eventFree.title,
            description: '',
            eventDate: eventFree.eventDate,
            durationMinutes: eventFree.durationMinutes,
            location: eventFree.location,
            maxParticipants: 0,
            currentParticipants: 0,
            waitlistCount: 0,
            type: 'FREE',
            fields: const [],
          ),
          status: 'REGISTERED',
          queuePosition: null,
        ),
      ];

  static EventParticipantsResponse get participants => EventParticipantsResponse(
        registered: [
          ParticipantInfo(
            registrationId: 'reg-registered-1',
            userId: studentUser.id,
            name: studentUser.name,
            email: studentUser.email,
            reliabilityScore: 92.5,
            registeredAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ],
        waitlist: [
          ParticipantInfo(
            registrationId: 'reg-waitlist-1',
            userId: '44444444-4444-4444-4444-444444444444',
            name: 'Мария Петрова',
            email: 'maria@uni.ru',
            reliabilityScore: 75,
            registeredAt: DateTime.now().subtract(const Duration(days: 3)),
            queuePosition: 1,
          ),
        ],
        pending: [
          ParticipantInfo(
            registrationId: 'reg-pending-1',
            userId: '55555555-5555-5555-5555-555555555555',
            name: 'Алексей Сидоров',
            email: 'alex@uni.ru',
            reliabilityScore: 60,
            registeredAt: DateTime.now().subtract(const Duration(days: 1)),
            answers: const [
              PendingAnswer(fieldName: 'Курс', answer: '2 курс'),
              PendingAnswer(fieldName: 'Группа', answer: 'ИВТ-22'),
            ],
          ),
        ],
      );

  static AttendanceStats get attendance => AttendanceStats(
        totalRegistered: 30,
        attended: 22,
        noShow: 8,
        attendanceRate: 73.3,
        attendees: [
          Attendee(
            userId: studentUser.id,
            name: studentUser.name,
            attendedAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
        noShowList: const [
          NoShowUser(userId: '66666666-6666-6666-6666-666666666666', name: 'Пётр Петров'),
        ],
      );

  static ScanResponse scanAllowed(String userId) => ScanResponse(
        allowed: true,
        userName: studentUser.name,
        eventTitle: eventFree.title,
        message: 'Вход разрешён',
      );

  static ScanResponse scanDenied(String userId) => ScanResponse(
        allowed: false,
        userName: studentUser.name,
        eventTitle: eventFree.title,
        message: 'Вход запрещён — заявка не подтверждена',
      );
}
