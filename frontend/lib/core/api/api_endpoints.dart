class ApiEndpoints {
  // AuthController: @RequestMapping("/auth") + context-path /api
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // Контроллеры с префиксом /api в маппинге + context-path /api
  static const String scan = '/api/scan';
  static const String myRegistrations = '/api/users/me/registrations';

  // EventController: @RequestMapping("/events") + context-path /api
  static const String events = '/events';

  static String eventById(String id) => '/events/$id';
  static String registerForEvent(String eventId) => '/api/events/$eventId/register';
  static String eventRegistrations(String eventId) => '/api/events/$eventId/registrations';
  static String approveRegistration(String eventId, String registrationId) =>
      '/api/events/$eventId/registrations/$registrationId/approve';
  static String rejectRegistration(String eventId, String registrationId) =>
      '/api/events/$eventId/registrations/$registrationId/reject';
  static String attendance(String eventId) => '/api/events/$eventId/attendance';
  static String finalize(String eventId) => '/api/events/$eventId/finalize';
}
