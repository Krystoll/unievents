import 'package:dio/dio.dart';

import '../../models/user.dart';
import '../config/app_config.dart';
import '../mock/mock_data.dart';
import '../storage/token_storage.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class AuthResponse {
  final String token;
  final User user;

  const AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthService {
  final Dio _dio = ApiClient.instance.dio;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    if (AppConfig.useMockData) {
      final user = MockData.userByEmail(email);
      return MockData.authResponse(user);
    }
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    String role = 'STUDENT',
  }) async {
    if (AppConfig.useMockData) {
      return AuthResponse(
        token: 'mock-jwt-token-STUDENT',
        user: User(
          id: MockData.studentUser.id,
          name: name,
          email: email,
          role: 'STUDENT',
          reliabilityScore: 100,
        ),
      );
    }
    final response = await _dio.post(
      ApiEndpoints.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      },
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> me() async {
    if (AppConfig.useMockData) {
      final role = await TokenStorage.getRole();
      if (role == 'ADMIN') return MockData.adminUser;
      if (role == 'CHECKER') return MockData.checkerUser;
      return MockData.studentUser;
    }
    final response = await _dio.get(ApiEndpoints.me);
    return User.fromJson(response.data as Map<String, dynamic>);
  }
}
