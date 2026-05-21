class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final double reliabilityScore;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.reliabilityScore,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role']?.toString() ?? 'STUDENT',
      reliabilityScore: (json['reliabilityScore'] as num?)?.toDouble() ?? 0,
    );
  }
}
