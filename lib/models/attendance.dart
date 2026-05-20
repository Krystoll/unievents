class AttendanceStats {
  final int totalRegistered;
  final int attended;
  final int noShow;
  final double attendanceRate;
  final List<Attendee> attendees;
  final List<NoShowUser> noShowList;

  const AttendanceStats({
    required this.totalRegistered,
    required this.attended,
    required this.noShow,
    required this.attendanceRate,
    required this.attendees,
    required this.noShowList,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    return AttendanceStats(
      totalRegistered: json['totalRegistered'] as int? ?? 0,
      attended: json['attended'] as int? ?? 0,
      noShow: json['noShow'] as int? ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0,
      attendees: (json['attendees'] as List<dynamic>? ?? [])
          .map((e) => Attendee.fromJson(e as Map<String, dynamic>))
          .toList(),
      noShowList: (json['noShowList'] as List<dynamic>? ?? [])
          .map((e) => NoShowUser.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Attendee {
  final String userId;
  final String name;
  final DateTime attendedAt;

  const Attendee({
    required this.userId,
    required this.name,
    required this.attendedAt,
  });

  factory Attendee.fromJson(Map<String, dynamic> json) {
    return Attendee(
      userId: json['userId'] as String,
      name: json['name'] as String,
      attendedAt: DateTime.parse(json['attendedAt'] as String),
    );
  }
}

class NoShowUser {
  final String userId;
  final String name;

  const NoShowUser({required this.userId, required this.name});

  factory NoShowUser.fromJson(Map<String, dynamic> json) {
    return NoShowUser(
      userId: json['userId'] as String,
      name: json['name'] as String,
    );
  }
}
