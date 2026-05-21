class ApiEndpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String scan = '/scan';
  static const String events = '/events';
  static const String myRegistrations = '/users/me/registrations';

  static String eventById(String id) => '/events/$id';
  static String registerForEvent(String eventId) => '/events/$eventId/register';
  static String eventRegistrations(String eventId) => '/events/$eventId/registrations';
  static String approveRegistration(String eventId, String registrationId) =>
      '/events/$eventId/registrations/$registrationId/approve';
  static String rejectRegistration(String eventId, String registrationId) =>
      '/events/$eventId/registrations/$registrationId/reject';
  static String attendance(String eventId) => '/events/$eventId/attendance';
  static String finalize(String eventId) => '/events/$eventId/finalize';
}
