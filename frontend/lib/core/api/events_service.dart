import 'package:dio/dio.dart';

import '../../models/attendance.dart';
import '../../models/event.dart';
import '../../models/registration.dart';
import '../config/app_config.dart';
import '../mock/mock_data.dart';
import 'api_client.dart';
import 'api_endpoints.dart';
import 'api_json.dart';

class EventRegistrationResponse {
  final String status;
  final int? queuePosition;
  final String message;

  const EventRegistrationResponse({
    required this.status,
    required this.queuePosition,
    required this.message,
  });

  factory EventRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return EventRegistrationResponse(
      status: json['status']?.toString() ?? '',
      queuePosition: parseQueuePosition(json['queuePosition']),
      message: (json['message'] as String?) ?? '',
    );
  }
}

class EventsService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Event>> getEvents() async {
    if (AppConfig.useMockData) {
      return MockData.events;
    }
    final response = await _dio.get(ApiEndpoints.events);
    final data = response.data as List<dynamic>;
    return data.map((item) => Event.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Event> getEventById(String id) async {
    if (AppConfig.useMockData) {
      return MockData.events.firstWhere((e) => e.id == id);
    }
    final response = await _dio.get(ApiEndpoints.eventById(id));
    return Event.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EventRegistrationResponse> registerForEvent(
    String id, {
    List<Map<String, String>> answers = const [],
  }) async {
    if (AppConfig.useMockData) {
      final event = MockData.events.firstWhere((e) => e.id == id);
      if (event.type == 'APPROVAL') {
        return const EventRegistrationResponse(
          status: 'PENDING',
          queuePosition: null,
          message: 'Заявка отправлена. Ожидайте подтверждения',
        );
      }
      if (event.currentParticipants < event.maxParticipants) {
        return const EventRegistrationResponse(
          status: 'REGISTERED',
          queuePosition: null,
          message: 'Вы успешно записаны',
        );
      }
      return const EventRegistrationResponse(
        status: 'WAITLISTED',
        queuePosition: 4,
        message: 'Вы в очереди на позиции 4',
      );
    }
    final response = await _dio.post(
      ApiEndpoints.registerForEvent(id),
      data: answers.isEmpty ? {} : {'answers': answers},
    );
    return EventRegistrationResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> cancelRegistration(String id) async {
    if (AppConfig.useMockData) {
      return 'Участие отменено';
    }
    final response = await _dio.delete(ApiEndpoints.registerForEvent(id));
    final data = response.data as Map<String, dynamic>;
    return (data['message'] as String?) ?? 'Участие отменено';
  }

  Future<List<Registration>> getMyRegistrations() async {
    if (AppConfig.useMockData) {
      return MockData.myRegistrations;
    }
    final response = await _dio.get(ApiEndpoints.myRegistrations);
    final data = response.data as List<dynamic>;
    return data.map((item) => Registration.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Event> createEvent({
    required String title,
    required String description,
    required DateTime eventDate,
    required int durationMinutes,
    required String location,
    required int maxParticipants,
    required String type,
    required List<Map<String, dynamic>> fields,
  }) async {
    if (AppConfig.useMockData) {
      return Event(
        id: 'new-event-id',
        title: title,
        description: description,
        eventDate: eventDate,
        durationMinutes: durationMinutes,
        location: location,
        maxParticipants: maxParticipants,
        currentParticipants: 0,
        waitlistCount: 0,
        type: type,
        fields: [],
      );
    }
    final response = await _dio.post(
      ApiEndpoints.events,
      data: {
        'title': title,
        'description': description,
        'eventDate': eventDate.toIso8601String(),
        'durationMinutes': durationMinutes,
        'location': location,
        'maxParticipants': maxParticipants,
        'type': type,
        'fields': fields,
      },
    );
    return Event.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Event> updateEvent({
    required String id,
    required String title,
    required String description,
    required DateTime eventDate,
    required int durationMinutes,
    required String location,
    required int maxParticipants,
    required String type,
    required List<Map<String, dynamic>> fields,
  }) async {
    if (AppConfig.useMockData) {
      return await getEventById(id);
    }
    final response = await _dio.put(
      ApiEndpoints.eventById(id),
      data: {
        'title': title,
        'description': description,
        'eventDate': eventDate.toIso8601String(),
        'durationMinutes': durationMinutes,
        'location': location,
        'maxParticipants': maxParticipants,
        'type': type,
        'fields': fields,
      },
    );
    return Event.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteEvent(String id) async {
    if (AppConfig.useMockData) {
      return;
    }
    await _dio.delete(ApiEndpoints.eventById(id));
  }

  Future<EventParticipantsResponse> getEventRegistrations(String eventId) async {
    if (AppConfig.useMockData) {
      return MockData.participants;
    }
    final response = await _dio.get(ApiEndpoints.eventRegistrations(eventId));
    return EventParticipantsResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> approveRegistration(String eventId, String registrationId) async {
    if (AppConfig.useMockData) {
      return 'Заявка одобрена';
    }
    final response = await _dio.post(ApiEndpoints.approveRegistration(eventId, registrationId), data: {});
    return (response.data as Map<String, dynamic>)['message'] as String? ?? 'Заявка одобрена';
  }

  Future<String> rejectRegistration(String eventId, String registrationId) async {
    if (AppConfig.useMockData) {
      return 'Заявка отклонена';
    }
    final response = await _dio.post(ApiEndpoints.rejectRegistration(eventId, registrationId), data: {});
    return (response.data as Map<String, dynamic>)['message'] as String? ?? 'Заявка отклонена';
  }

  Future<AttendanceStats> getAttendance(String eventId) async {
    if (AppConfig.useMockData) {
      return MockData.attendance;
    }
    final response = await _dio.get(ApiEndpoints.attendance(eventId));
    return AttendanceStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> finalizeEvent(String eventId) async {
    if (AppConfig.useMockData) {
      return 'Мероприятие завершено. Обновлено записей: 8';
    }
    final response = await _dio.post(ApiEndpoints.finalize(eventId), data: {});
    return (response.data as Map<String, dynamic>)['message'] as String? ?? 'Мероприятие завершено';
  }

  Future<ScanResponse> scan({
    required String qrToken,
    required String eventId,
  }) async {
    if (AppConfig.useMockData) {
      final studentId = MockData.studentUser.id;
      final window = DateTime.now().millisecondsSinceEpoch ~/ 120000;
      final currentToken = 'mock-qr-$studentId-$window';
      if (qrToken == currentToken) {
        return MockData.scanAllowed(studentId);
      }
      if (qrToken.startsWith('mock-qr-')) {
        return ScanResponse(
          allowed: false,
          userName: '',
          eventTitle: '',
          message: 'QR-код устарел. Попросите студента обновить код в приложении',
        );
      }
      return MockData.scanDenied(qrToken);
    }
    final response = await _dio.post(
      ApiEndpoints.scan,
      data: {'qrToken': qrToken, 'eventId': eventId},
    );
    return ScanResponse.fromJson(response.data as Map<String, dynamic>);
  }
}

class ParticipantInfo {
  final String registrationId;
  final String userId;
  final String name;
  final String email;
  final double reliabilityScore;
  final DateTime registeredAt;
  final int? queuePosition;
  final List<PendingAnswer> answers;

  const ParticipantInfo({
    required this.registrationId,
    required this.userId,
    required this.name,
    required this.email,
    required this.reliabilityScore,
    required this.registeredAt,
    this.queuePosition,
    this.answers = const [],
  });

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantInfo(
      registrationId: json['registrationId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name'] as String,
      email: json['email'] as String,
      reliabilityScore: (json['reliabilityScore'] as num?)?.toDouble() ?? 0,
      registeredAt: parseApiDateTime(json['registeredAt']),
      queuePosition: parseQueuePosition(json['queuePosition']),
      answers: (json['answers'] as List<dynamic>? ?? [])
          .map((e) => PendingAnswer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EventParticipantsResponse {
  final List<ParticipantInfo> registered;
  final List<ParticipantInfo> waitlist;
  final List<ParticipantInfo> pending;

  const EventParticipantsResponse({
    required this.registered,
    required this.waitlist,
    required this.pending,
  });

  factory EventParticipantsResponse.fromJson(Map<String, dynamic> json) {
    final registeredJson = (json['registered'] as List<dynamic>? ?? []);
    final waitlistJson = (json['waitlist'] as List<dynamic>? ?? []);
    final pendingJson = (json['pending'] as List<dynamic>? ?? []);
    return EventParticipantsResponse(
      registered: registeredJson
          .map((e) => ParticipantInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      waitlist: waitlistJson
          .map((e) => ParticipantInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      pending: pendingJson
          .map((e) => ParticipantInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PendingAnswer {
  final String fieldName;
  final String answer;

  const PendingAnswer({
    required this.fieldName,
    required this.answer,
  });

  factory PendingAnswer.fromJson(Map<String, dynamic> json) {
    return PendingAnswer(
      fieldName: json['fieldName'] as String,
      answer: json['answer'] as String,
    );
  }
}

class ScanResponse {
  final bool allowed;
  final String userName;
  final String eventTitle;
  final String message;

  const ScanResponse({
    required this.allowed,
    required this.userName,
    required this.eventTitle,
    required this.message,
  });

  factory ScanResponse.fromJson(Map<String, dynamic> json) {
    return ScanResponse(
      allowed: json['allowed'] as bool? ?? false,
      userName: (json['userName'] as String?) ?? '',
      eventTitle: (json['eventTitle'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
    );
  }
}
