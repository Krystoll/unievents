import 'package:flutter/foundation.dart';

/// Настройки подключения к Spring Boot API (см. backend application.properties.template).
class AppConfig {
  /// false — запросы на бэкенд; true — локальные mock-данные.
  static const bool useMockData = false;

  /// IP ПК в Wi‑Fi для запуска на физическом телефоне:
  /// `flutter run --dart-define=API_HOST=192.168.0.10`
  static const String _hostOverride = String.fromEnvironment('API_HOST');

  /// context-path бэка: `/api` → базовый URL `http://host:8080/api`.
  static String get apiBaseUrl {
    final host = _resolveHost();
    return 'http://$host:8080/api';
  }

  static String _resolveHost() {
    if (_hostOverride.isNotEmpty) {
      return _hostOverride;
    }
    if (kIsWeb) {
      return 'localhost';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '10.0.2.2';
      default:
        return 'localhost';
    }
  }
}
