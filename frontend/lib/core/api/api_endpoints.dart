class ApiEndpoints {
  // AuthController: @RequestMapping("/auth") + context-path /api
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String me = '/api/auth/me';
  static const String qrToken = '/api/auth/me/qr';

  // Контроллеры с префиксом /api в маппинге + context-path /api
  static const String scan = '/api/scan';
  static const String myRegistrations = '/api/users/me/registrations';

  // EventController: @RequestMapping("/events") + context-path /api
  static const String events = '/api/events';

  static String eventById(String id) => '/api/events/$id';
  static String registerForEvent(String eventId) => '/api/events/$eventId/register';
  static String eventRegistrations(String eventId) => '/api/events/$eventId/registrations';
  static String approveRegistration(String eventId, String registrationId) =>
      '/api/events/$eventId/registrations/$registrationId/approve';
  static String rejectRegistration(String eventId, String registrationId) =>
      '/api/events/$eventId/registrations/$registrationId/reject';
  static String attendance(String eventId) => '/api/events/$eventId/attendance';
  static String finalize(String eventId) => '/api/events/$eventId/finalize';

  static const String submitGameScore = '/api/games/scores';
  static const String myGameStats = '/api/games/stats/me';
  static String gameLeaderboard(String gameType) => '/api/games/leaderboard/$gameType';
  static String eventGameLeaderboard(String eventId, String gameType) =>
      '/api/games/events/$eventId/leaderboard/$gameType';
}
