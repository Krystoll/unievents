# UniEvents

Монорепозиторий системы учёта мероприятий университета.

## Структура

- `backend/` — Spring Boot API
- `frontend/` — Flutter-приложение (STUDENT, ADMIN, CHECKER)

## Запуск backend

```bash
cd backend
# скопировать application.properties.template → application.properties и задать параметры
mvn spring-boot:run
```

## Запуск frontend

```bash
cd frontend
flutter pub get
flutter run
```

По умолчанию в `frontend/lib/core/config/app_config.dart` включены mock-данные (`useMockData = true`).
