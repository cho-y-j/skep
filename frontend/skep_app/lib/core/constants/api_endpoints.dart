class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://skep.on1.kr',
  );

  // Auth endpoints
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String refresh = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';

  // Equipment endpoints
  static const String equipments = '/api/equipments';
  static const String equipment = '/api/equipments/{id}';
  static const String persons = '/api/persons';
  static const String person = '/api/persons/{id}';

  // Document endpoints
  static const String documents = '/api/documents';
  static const String document = '/api/documents/{id}';
  static const String documentUpload = '/api/documents/upload';

  // Dispatch endpoints
  static const String deploymentPlans = '/api/deployment-plans';
  static const String deploymentPlan = '/api/deployment-plans/{id}';
  static const String dailyRosters = '/api/daily-rosters';
  static const String dailyRoster = '/api/daily-rosters/{id}';
  static const String workRecords = '/api/work-records';
  static const String workRecord = '/api/work-records/{id}';
  static const String startWork = '/api/work-records/{id}/start';
  static const String endWork = '/api/work-records/{id}/end';

  // Inspection endpoints
  static const String safetyInspections = '/api/safety-inspections';
  static const String safetyInspection = '/api/safety-inspections/{id}';
  static const String maintenanceInspections = '/api/maintenance-inspections';
  static const String maintenanceInspection = '/api/maintenance-inspections/{id}';

  // Settlement endpoints
  static const String settlements = '/api/settlements';
  static const String settlement = '/api/settlements/{id}';

  // Statistics endpoints
  static const String statistics = '/api/statistics';

  // Notification endpoints
  static const String notifications = '/api/notifications';
  static const String notification = '/api/notifications/{id}';
  static const String messages = '/api/messages';

  // WebSocket endpoint
  static const String wsBase = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://skep.on1.kr',
  );
  static const String wsLocation = '/ws/locations';
}
