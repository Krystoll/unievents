# Запуск UniEvents на ноутбуке (Windows, без эмулятора)

Нужно **4 вещи**: PostgreSQL (БД) → Java 17 + Maven (бэкенд) → Flutter (фронт на Windows).

---

## Шаг 0. Установка программ (один раз)

Открой **PowerShell от администратора** и выполни:

```powershell
winget install -e --id EclipseAdoptium.Temurin.17.JDK
winget install -e --id Apache.Maven
winget install -e --id PostgreSQL.PostgreSQL.17
```

**Закрой и снова открой PowerShell** (чтобы подхватился PATH).

Проверка:

```powershell
java -version
mvn -version
psql --version
flutter --version
```

При установке PostgreSQL запомни **пароль пользователя `postgres`** — он понадобится ниже.

---

## Шаг 1. Создать базу данных

### Вариант А — через pgAdmin (проще)

1. Пуск → **pgAdmin 4**
2. Servers → PostgreSQL → введи пароль `postgres`
3. ПКМ по **Databases** → **Create** → **Database**
4. Имя: `unievents` → Save

### Вариант Б — через терминал

```powershell
psql -U postgres -h localhost
```

В консоли `psql`:

```sql
CREATE DATABASE unievents;
\q
```

Таблицы Spring создаст сам при первом запуске (`ddl-auto=update`).

---

## Шаг 2. Настроить бэкенд

В папке `backend` должен быть файл  
`src/main/resources/application.properties` (он в `.gitignore`, в репозиторий не попадает).

Скопируй шаблон:

```powershell
cd "C:\Users\frolo\OneDrive\Рабочий стол\практикум\unievents\backend"
copy src\main\resources\application.properties.template src\main\resources\application.properties
```

Открой `application.properties` и подставь **свой пароль PostgreSQL** и любой длинный JWT-секрет, например:

```properties
spring.datasource.username=postgres
spring.datasource.password=ТВОЙ_ПАРОЛЬ_ОТ_POSTGRES
jwt.secret=unievents-local-dev-secret-change-me-32chars-min
```

Остальное можно не менять.

---

## Шаг 3. Запустить бэкенд

**Терминал 1:**

```powershell
cd "C:\Users\frolo\OneDrive\Рабочий стол\практикум\unievents\backend"
mvn spring-boot:run
```

Жди строку вроде `Started UniEventsApplication` — API на **http://localhost:8080/api**.

Проверка в браузере (после логина не откроется без токена, но сервер жив):  
http://localhost:8080/api/auth/login — должен отвечать не «connection refused».

---

## Шаг 4. Запустить фронт на Windows (без эмулятора)

**Терминал 2** (бэкенд в первом не закрывай):

```powershell
cd "C:\Users\frolo\OneDrive\Рабочий стол\практикум\unievents\frontend"
flutter pub get
flutter run -d windows
```

Фронт сам ходит на `http://localhost:8080/api` (см. `app_config.dart`).

### Вход в приложение

| Роль | Email | Пароль |
|------|-------|--------|
| Админ | admin@uni.ru | admin123 |
| Чекер | checker@uni.ru | checker123 |
| Студент | — | кнопка «Регистрация» в приложении |

---

## Частые ошибки

| Симптом | Решение |
|---------|---------|
| `mvn` / `java` не найдены | Переустанови JDK/Maven, перезапусти терминал |
| `Connection refused` во Flutter | Бэкенд не запущен или упал — смотри Терминал 1 |
| Ошибка подключения к PostgreSQL | Неверный пароль в `application.properties` или БД `unievents` не создана |
| `flutter run -d windows` — нет устройства | `flutter config --enable-windows-desktop` затем `flutter doctor` |

---

## Когда всё работает — коммит

```powershell
cd "C:\Users\frolo\OneDrive\Рабочий стол\практикум\unievents"
git add README.md SETUP_LOCAL.md frontend/lib frontend/android/app/src/main/AndroidManifest.xml
git status
git commit -m "Подключить Flutter к backend API"
git push origin main
```

`application.properties` **не коммить** — там пароли.
