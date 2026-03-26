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

  // Company endpoints
  static const String companies = '/api/auth/companies';
  static const String company = '/api/auth/companies/{id}';
  static const String companiesByType = '/api/auth/companies/type/{type}';

  // Equipment endpoints
  static const String equipments = '/api/equipment';
  static const String equipment = '/api/equipment/{id}';
  static const String equipmentNfc = '/api/equipment/{id}/nfc';
  static const String equipmentStatus = '/api/equipment/{id}/status';
  static const String equipmentAssign = '/api/equipment/{id}/assign';
  static const String persons = '/api/equipment/persons';
  static const String person = '/api/equipment/persons/{id}';

  // Document endpoints
  static const String documents = '/api/documents';
  static const String document = '/api/documents/{id}';
  static const String documentUpload = '/api/documents/upload';
  static const String documentFile = '/api/documents/{id}/file';
  static const String documentTypes = '/api/documents/types';
  static const String documentsByOwner = '/api/documents/{ownerId}/{ownerType}';
  static const String documentExpiring = '/api/documents/expiring';

  // Dispatch endpoints
  static const String deploymentPlans = '/api/dispatch/plans';
  static const String deploymentPlan = '/api/dispatch/plans/{id}';
  static const String dailyRosters = '/api/dispatch/rosters';
  static const String dailyRoster = '/api/dispatch/rosters/{id}';
  static const String workRecords = '/api/dispatch/work-records';
  static const String workRecord = '/api/dispatch/work-records/{id}';
  static const String clockIn = '/api/dispatch/work-records/clock-in';
  static const String startWork = '/api/dispatch/work-records/{id}/start';
  static const String endWork = '/api/dispatch/work-records/{id}/end';

  // Quotation endpoints
  static const String quotationRequests = '/api/dispatch/quotations/requests';
  static const String quotations = '/api/dispatch/quotations';
  static const String quotationsByRequest = '/api/dispatch/quotations/request/{requestId}';
  static const String quotationSubmit = '/api/dispatch/quotations/{id}/submit';
  static const String quotationAccept = '/api/dispatch/quotations/{id}/accept';
  static const String quotationReject = '/api/dispatch/quotations/{id}/reject';

  // Site endpoints
  static const String sites = '/api/dispatch/sites';
  static const String sitesByBp = '/api/dispatch/sites/bp/{bpCompanyId}';

  // Checklist endpoints
  static const String checklists = '/api/dispatch/checklists/plan/{planId}';
  static const String checklistUpdate = '/api/dispatch/checklists/{id}/update';
  static const String checklistOverride = '/api/dispatch/checklists/{id}/override';

  // Verification endpoints
  static const String verifyDriverLicense = '/api/documents/verify/driver-license';
  static const String verifyBusinessRegistration = '/api/documents/verify/business-registration';
  static const String verifyCargo = '/api/documents/verify/cargo';

  // Confirmation endpoints
  static const String dailyConfirmations = '/api/dispatch/confirmations/daily';
  static const String monthlyConfirmations = '/api/dispatch/confirmations/monthly';

  // Inspection endpoints
  static const String safetyInspections = '/api/inspection/safety';
  static const String safetyInspection = '/api/inspection/safety/{id}';
  static const String maintenanceInspections = '/api/inspection/maintenance';
  static const String maintenanceInspection = '/api/inspection/maintenance/{id}';
  static const String inspectionItems = '/api/inspection/items';

  // Settlement endpoints
  static const String settlements = '/api/settlement';
  static const String settlement = '/api/settlement/{id}';
  static const String settlementGenerate = '/api/settlement/generate';

  // Document type CRUD
  static const String documentTypeCreate = '/api/documents/types';
  static const String documentTypeUpdate = '/api/documents/types/{id}';
  static const String documentTypeDelete = '/api/documents/types/{id}';

  // Equipment type CRUD
  static const String equipmentTypes = '/api/equipment/types';
  static const String equipmentTypeCreate = '/api/equipment/types';
  static const String equipmentTypeUpdate = '/api/equipment/types/{id}';
  static const String equipmentTypeDelete = '/api/equipment/types/{id}';

  // Statistics endpoints
  static const String statistics = '/api/statistics';

  // Notification endpoints
  static const String notifications = '/api/notifications';
  static const String notification = '/api/notifications/{id}';
  static const String messages = '/api/notifications/messages';
  static const String fcmRegister = '/api/notifications/fcm/register';

  // Location endpoints
  static const String locationUpdate = '/api/location/update';
  static const String locationCurrent = '/api/location/current/{siteId}';
  static const String locationWorker = '/api/location/worker/{workerId}';

  // WebSocket endpoint
  static const String wsBase = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://skep.on1.kr',
  );
  static const String wsLocation = '/ws/locations';
}
