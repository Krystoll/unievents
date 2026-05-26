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

API: `http://localhost:8080/api` (context-path `/api`).

## Запуск frontend

```bash
cd frontend
flutter pub get
flutter run
```

### Подключение к API

Настройки: `frontend/lib/core/config/app_config.dart`

- `useMockData = false` — все экраны ходят на бэкенд
- `apiBaseUrl` — по умолчанию `http://localhost:8080/api` (Windows/macOS/iOS-симулятор)
- Android-эмулятор: `http://10.0.2.2:8080/api`
- Телефон в той же Wi‑Fi (IP компьютера):

```bash
flutter run --dart-define=API_HOST=192.168.0.10
```

### Тестовые аккаунты

| Роль | Email | Пароль |
|------|-------|--------|
| ADMIN | admin@uni.ru | admin123 |
| CHECKER | checker@uni.ru | checker123 |
| STUDENT | — | регистрация в приложении |

### Соответствие API

| Фронт | Бэкенд |
|-------|--------|
| `/auth/login`, `/auth/register`, `/auth/me` | AuthController |
| `/events`, `/events/{id}` | EventController |
| `/api/events/{id}/register` | RegistrationController |
| `/api/users/me/registrations` | RegistrationController |
| `/api/scan` | ScanController |
| `/api/events/.../registrations`, attendance, finalize | AdminController |
