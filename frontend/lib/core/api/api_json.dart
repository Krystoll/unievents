import 'package:dio/dio.dart';

DateTime parseApiDateTime(dynamic value) {
  if (value == null) {
    throw const FormatException('eventDate is null');
  }
  if (value is String) {
    return DateTime.parse(value);
  }
  throw FormatException('Unsupported date format: $value');
}

DateTime? parseApiDateTimeOrNull(dynamic value) {
  if (value == null) return null;
  return parseApiDateTime(value);
}

int? parseQueuePosition(dynamic value) {
  if (value == null || value == 'null') return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String extractApiErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Не удалось подключиться к серверу. Запустите backend и проверьте app_config.dart (apiBaseUrl).';
      default:
        break;
    }
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['error'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    if (error.response?.statusCode == 401) {
      return 'Сессия истекла. Войдите снова.';
    }
  }
  return 'Ошибка запроса. Проверьте сервер и данные.';
}
