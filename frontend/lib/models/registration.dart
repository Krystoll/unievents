import '../core/api/api_json.dart';
import 'event.dart';

class Registration {
  final String registrationId;
  final Event event;
  final String status;
  final int? queuePosition;

  const Registration({
    required this.registrationId,
    required this.event,
    required this.status,
    required this.queuePosition,
  });

  factory Registration.fromJson(Map<String, dynamic> json) {
    return Registration(
      registrationId: json['registrationId']?.toString() ?? '',
      event: Event.fromJson(json['event'] as Map<String, dynamic>),
      status: json['status']?.toString() ?? '',
      queuePosition: parseQueuePosition(json['queuePosition']),
    );
  }
}
