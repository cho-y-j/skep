import client from "./client";
import type {
  User,
  Company,
  CompanyType,
  Equipment,
  EquipmentType,
  Person,
  Site,
  QuotationRequest,
  Quotation,
  DeploymentPlan,
  DailyRoster,
  WorkRecord,
  DeploymentChecklist,
  SafetyInspection,
  MaintenanceRecord,
  Settlement,
  SettlementStats,
  DocumentType,
  Document,
  Notification,
  LoginRequest,
  LoginResponse,
  PageResponse,
} from "@/types";

// ---------------------------------------------------------------------------
// TanStack Query Key Factories
// ---------------------------------------------------------------------------

export const queryKeys = {
  auth: {
    me: ["auth", "me"] as const,
    users: (params?: Record<string, unknown>) =>
      ["auth", "users", params] as const,
  },
  companies: {
    all: (params?: Record<string, unknown>) =>
      ["companies", "list", params] as const,
    byId: (id: string) => ["companies", "detail", id] as const,
    byType: (type: CompanyType) => ["companies", "type", type] as const,
  },
  equipment: {
    all: (params?: Record<string, unknown>) =>
      ["equipment", "list", params] as const,
    byId: (id: string) => ["equipment", "detail", id] as const,
    persons: (params?: Record<string, unknown>) =>
      ["equipment", "persons", params] as const,
    types: ["equipment", "types"] as const,
  },
  documents: {
    types: ["documents", "types"] as const,
    expiring: (days: number) => ["documents", "expiring", days] as const,
    byOwner: (ownerType: string, ownerId: string) =>
      ["documents", "owner", ownerType, ownerId] as const,
  },
  dispatch: {
    plans: (params?: Record<string, unknown>) =>
      ["dispatch", "plans", params] as const,
    planById: (id: string) => ["dispatch", "plans", id] as const,
    rosters: (params?: Record<string, unknown>) =>
      ["dispatch", "rosters", params] as const,
    rosterById: (id: string) => ["dispatch", "rosters", id] as const,
    workRecords: (params?: Record<string, unknown>) =>
      ["dispatch", "workRecords", params] as const,
    sites: (params?: Record<string, unknown>) =>
      ["dispatch", "sites", params] as const,
    siteById: (id: string) => ["dispatch", "sites", id] as const,
    quotationRequests: (params?: Record<string, unknown>) =>
      ["dispatch", "quotationRequests", params] as const,
    quotations: (params?: Record<string, unknown>) =>
      ["dispatch", "quotations", params] as const,
    quotationById: (id: string) => ["dispatch", "quotations", id] as const,
    checklists: (params?: Record<string, unknown>) =>
      ["dispatch", "checklists", params] as const,
    checklistById: (id: string) => ["dispatch", "checklists", id] as const,
  },
  inspection: {
    safety: (params?: Record<string, unknown>) =>
      ["inspection", "safety", params] as const,
    safetyById: (id: string) => ["inspection", "safety", id] as const,
    maintenance: (params?: Record<string, unknown>) =>
      ["inspection", "maintenance", params] as const,
    maintenanceById: (id: string) =>
      ["inspection", "maintenance", id] as const,
    items: (inspectionId: string) =>
      ["inspection", "items", inspectionId] as const,
  },
  settlement: {
    all: (params?: Record<string, unknown>) =>
      ["settlement", "list", params] as const,
    stats: ["settlement", "stats"] as const,
  },
  notifications: {
    all: (params?: Record<string, unknown>) =>
      ["notifications", "list", params] as const,
    unreadCount: ["notifications", "unreadCount"] as const,
  },
  location: {
    current: (userId: string) => ["location", "current", userId] as const,
    history: (userId: string, date: string) =>
      ["location", "history", userId, date] as const,
  },
};

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

export const authApi = {
  login: (data: LoginRequest) =>
    client.post<unknown, LoginResponse>("/api/auth/login", data),

  register: (data: Record<string, unknown>) =>
    client.post("/api/auth/register", data),

  logout: () => client.post("/api/auth/logout"),

  me: () => client.get<unknown, User>("/api/auth/me"),

  getUsers: (params?: Record<string, unknown>) =>
    client.get<unknown, PageResponse<User>>("/api/auth/users", { params }),
};

// ---------------------------------------------------------------------------
// Companies
// ---------------------------------------------------------------------------

export const companiesApi = {
  getAll: (params?: Record<string, unknown>) =>
    client.get<unknown, PageResponse<Company>>("/api/auth/companies", { params }),

  getById: (id: string) =>
    client.get<unknown, Company>(`/api/auth/companies/${id}`),

  getByType: (type: CompanyType, params?: Record<string, unknown>) =>
    client.get<unknown, PageResponse<Company>>(`/api/auth/companies/type/${type}`, {
      params,
    }),

  create: (data: Partial<Company>) =>
    client.post<unknown, Company>("/api/auth/companies", data),

  update: (id: string, data: Partial<Company>) =>
    client.put<unknown, Company>(`/api/auth/companies/${id}`, data),

  // 백엔드는 PUT
  updateStatus: (id: string, status: string) =>
    client.put<unknown, Company>(`/api/auth/companies/${id}/status`, { status }),

  delete: (id: string) => client.delete(`/api/auth/companies/${id}`),
};

// ---------------------------------------------------------------------------
// Equipment
// ---------------------------------------------------------------------------

export const equipmentApi = {
  getAll: (params?: Record<string, unknown>) =>
    client.get<unknown, PageResponse<Equipment>>("/api/equipment", { params }),

  getById: (id: string) =>
    client.get<unknown, Equipment>(`/api/equipment/${id}`),

  create: (data: Partial<Equipment>) =>
    client.post<unknown, Equipment>("/api/equipment", data),

  update: (id: string, data: Partial<Equipment>) =>
    client.put<unknown, Equipment>(`/api/equipment/${id}`, data),

  delete: (id: string) => client.delete(`/api/equipment/${id}`),

  getPersons: (params?: Record<string, unknown>) =>
    client.get<unknown, PageResponse<Person>>("/api/equipment/persons", {
      params,
    }),

  createPerson: (data: Partial<Person>) =>
    client.post<unknown, Person>("/api/equipment/persons", data),

  updatePerson: (id: string, data: Partial<Person>) =>
    client.put<unknown, Person>(`/api/equipment/persons/${id}`, data),

  getTypes: () =>
    client.get<unknown, EquipmentType[]>("/api/equipment/types"),

  createType: (data: Partial<EquipmentType>) =>
    client.post<unknown, EquipmentType>("/api/equipment/types", data),
};

// ---------------------------------------------------------------------------
// Documents
// ---------------------------------------------------------------------------

export const documentsApi = {
  getTypes: () =>
    client.get<unknown, DocumentType[]>("/api/documents/types"),

  createType: (data: Partial<DocumentType>) =>
    client.post<unknown, DocumentType>("/api/documents/types", data),

  getExpiring: (days: number) =>
    client.get<unknown, Document[]>("/api/documents/expiring", {
      params: { days },
    }),

  getByOwner: (ownerType: string, ownerId: string) =>
    client.get<unknown, Document[]>(
      // 주의: 백엔드는 {ownerId}/{ownerType} 순서
      `/api/documents/${ownerId}/${ownerType}`
    ),

  upload: (data: FormData) =>
    client.post<unknown, Document>("/api/documents/upload", data, {
      headers: { "Content-Type": "multipart/form-data" },
    }),

  getFile: (id: string) =>
    client.get(`/api/documents/${id}/file`, { responseType: "blob" }),

  // 백엔드는 POST /api/documents/{id}/verify (body에 verified: true/false)
  verify: (id: string) =>
    client.post<unknown, Document>(`/api/documents/${id}/verify`, { verified: true }),

  unverify: (id: string) =>
    client.post<unknown, Document>(`/api/documents/${id}/verify`, { verified: false }),
};

// ---------------------------------------------------------------------------
// Dispatch - Plans
// ---------------------------------------------------------------------------

export const plansApi = {
  getAll: (params?: Record<string, unknown>) =>
    client.get<unknown, PageResponse<DeploymentPlan>>("/api/dispatch/plans", {
      params,
    }),

  getById: (id: string) =>
    client.get<unknown, DeploymentPlan>(`/api/dispatch/plans/${id}`),

  create: (data: Partial<DeploymentPlan>) =>
    client.post<unknown, DeploymentPlan>("/api/dispatch/plans", data),

  update: (id: string, data: Partial<DeploymentPlan>) =>
    client.put<unknown, DeploymentPlan>(`/api/dispatch/plans/${id}`, data),

  delete: (id: string) => client.delete(`/api/dispatch/plans/${id}`),
};

// ---------------------------------------------------------------------------
// Dispatch - Rosters
// ---------------------------------------------------------------------------

export const rostersApi = {
  getAll: (params?: Record<string, unknown>) =>
    client.get<unknown, PageResponse<DailyRoster>>("/api/dispatch/rosters", {
      params,
    }),

  getById: (id: string) =>
    client.get<unknown, DailyRoster>(`/api/dispatch/rosters/${id}`),

  create: (data: Partial<DailyRoster>) =>
    client.post<unknown, DailyRoster>("/api/dispatch/rosters", data),

  // NOTE: 백엔드엔 일반 PUT /rosters/{id} 없음 — 필요 시 create로 재생성
  update: (id: string, data: Partial<DailyRoster>) =>
    client.put<unknown, DailyRoster>(`/api/dispatch/rosters/${id}`, data),

  // PUT (백엔드 메서드)
  approve: (id: string) =>
    client.put<unknown, DailyRoster>(`/api/dispatch/rosters/${id}/approve`),

  reject: (id: string, reason: string) =>
    client.put<unknown, DailyRoster>(`/api/dispatch/rosters/${id}/reject`, {
      reason,
    }),

  // NOTE: 백엔드엔 DELETE /rosters/{id} 없음
  delete: (id: string) => client.delete(`/api/dispatch/rosters/${id}`),
};

// ---------------------------------------------------------------------------
// Dispatch - Work Records
// ---------------------------------------------------------------------------

export const workRecordsApi = {
  getAll: (params?: Record<string, unknown>) =>
    client.get<unknown, PageResponse<WorkRecord>>(
      "/api/dispatch/work-records",
      { params }
    ),

  // 백엔드: POST /api/dispatch/work-records/clock-in (body: rosterId, lat, lng)
  clockIn: (
    rosterId: string,
    data: { latitude: number; longitude: number }
  ) =>
    client.post<unknown, WorkRecord>(
      "/api/dispatch/work-records/clock-in",
      { rosterId, ...data }
    ),

  // 백엔드는 POST
  startWork: (id: string) =>
    client.post<unknown, WorkRecord>(
      `/api/dispatch/work-records/${id}/start`
    ),

  endWork: (id: string) =>
    client.post<unknown, WorkRecord>(`/api/dispatch/work-records/${id}/end`),
};

// ---------------------------------------------------------------------------
// Dispatch - Sites
// ---------------------------------------------------------------------------

export const sitesApi = {
  getAll: (params?: Record<string, unknown>) =>
    client.get<unknown, PageResponse<Site>>("/api/dispatch/sites", { params }),

  getById: (id: string) =>
    client.get<unknown, Site>(`/api/dispatch/sites/${id}`),

  create: (data: Partial<Site>) =>
    client.post<unknown, Site>("/api/dispatch/sites", data),

  update: (id: string, data: Partial<Site>) =>
    client.put<unknown, Site>(`/api/dispatch/sites/${id}`, data),

  delete: (id: string) => client.delete(`/api/dispatch/sites/${id}`),
};

// ---------------------------------------------------------------------------
// Dispatch - Quotation Requests
// ---------------------------------------------------------------------------

export const quotationRequestsApi = {
  getAll: (params?: Record<string, unknown>) =>
    client.get<unknown, PageResponse<QuotationRequest>>(
      "/api/dispatch/quotations/requests",
      { params }
    ),

  getById: (id: string) =>
    client.get<unknown, QuotationRequest>(
      `/api/dispatch/quotations/requests/${id}`
    ),

  create: (data: Partial<QuotationRequest>) =>
    client.post<unknown, QuotationRequest>(
      "/api/dispatch/quotations/requests",
      data
    ),
};

// ---------------------------------------------------------------------------
// Dispatch - Quotations
// ---------------------------------------------------------------------------

export const quotationsApi = {
  getAll: (params?: Record<string, unknown>) =>
    client.get<unknown, PageResponse<Quotation>>("/api/dispatch/quotations", {
      params,
    }),

  getById: (id: string) =>
    client.get<unknown, Quotation>(`/api/dispatch/quotations/${id}`),

  create: (data: Partial<Quotation>) =>
    client.post<unknown, Quotation>("/api/dispatch/quotations", data),

  update: (id: string, data: Partial<Quotation>) =>
    client.put<unknown, Quotation>(`/api/dispatch/quotations/${id}`, data),

  // 백엔드는 PUT
  submit: (id: string) =>
    client.put<unknown, Quotation>(
      `/api/dispatch/quotations/${id}/submit`
    ),

  accept: (id: string) =>
    client.put<unknown, Quotation>(
      `/api/dispatch/quotations/${id}/accept`
    ),

  reject: (id: string, reason: string) =>
    client.put<unknown, Quotation>(
      `/api/dispatch/quotations/${id}/reject`,
      { reason }
    ),
};

// ---------------------------------------------------------------------------
// Dispatch - Checklists
// ---------------------------------------------------------------------------

export const checklistsApi = {
  getAll: (params?: Record<string, unknown>) =>
    client.get<unknown, PageResponse<DeploymentChecklist>>(
      "/api/dispatch/checklists",
      { params }
    ),

  // 백엔드: GET /api/dispatch/checklists/plan/{planId}
  getByPlanId: (planId: string) =>
    client.get<unknown, DeploymentChecklist>(
      `/api/dispatch/checklists/plan/${planId}`
    ),

  // backward-compat alias
  getById: (id: string) =>
    client.get<unknown, DeploymentChecklist>(
      `/api/dispatch/checklists/plan/${id}`
    ),

  // 백엔드: PUT /api/dispatch/checklists/{id}/update
  update: (
    id: string,
    items: Array<{ itemId: string; checked: boolean; note?: string }>
  ) =>
    client.put<unknown, DeploymentChecklist>(
      `/api/dispatch/checklists/${id}/update`,
      { items }
    ),

  // 백엔드는 PUT
  override: (id: string, reason: string) =>
    client.put<unknown, DeploymentChecklist>(
      `/api/dispatch/checklists/${id}/override`,
      { reason }
    ),
};

// ---------------------------------------------------------------------------
// Dispatch - Confirmations
// ---------------------------------------------------------------------------

export const confirmationsApi = {
  // 백엔드: GET /api/dispatch/confirmations/daily
  getDaily: (params?: Record<string, unknown>) =>
    client.get("/api/dispatch/confirmations/daily", { params }),

  // backward-compat
  getAll: (params?: Record<string, unknown>) =>
    client.get("/api/dispatch/confirmations/daily", { params }),

  getDailyById: (id: string) =>
    client.get(`/api/dispatch/confirmations/daily/${id}`),

  getMonthlyByPlan: (planId: string) =>
    client.get(`/api/dispatch/confirmations/monthly/plan/${planId}`),

  // 서명 (PATCH→POST confirm 없음, 대신 sign 제공됨)
  signDaily: (id: string, data?: Record<string, unknown>) =>
    client.post(`/api/dispatch/confirmations/daily/${id}/sign`, data),

  signMonthly: (id: string, data?: Record<string, unknown>) =>
    client.post(`/api/dispatch/confirmations/monthly/${id}/sign`, data),

  sendMonthly: (id: string) =>
    client.post(`/api/dispatch/confirmations/monthly/${id}/send`),
};

// ---------------------------------------------------------------------------
// Inspection - Safety
// ---------------------------------------------------------------------------

export const safetyApi = {
  getAll: (params?: Record<string, unknown>) =>
    client.get<unknown, PageResponse<SafetyInspection>>(
      "/api/inspection/safety",
      { params }
    ),

  getById: (id: string) =>
    client.get<unknown, SafetyInspection>(`/api/inspection/safety/${id}`),

  // 백엔드: POST /api/inspection/safety/start (body에 planId/equipmentId 등)
  start: (data?: Record<string, unknown>) =>
    client.post<unknown, SafetyInspection>(
      `/api/inspection/safety/start`,
      data
    ),

  // 백엔드: POST /api/inspection/safety/{id}/record-item
  recordItem: (
    id: string,
    data: { itemId: string; passed: boolean; note?: string }
  ) =>
    client.post(
      `/api/inspection/safety/${id}/record-item`,
      data
    ),

  complete: (id: string) =>
    client.post<unknown, SafetyInspection>(
      `/api/inspection/safety/${id}/complete`
    ),

  fail: (id: string, reason: string) =>
    client.post<unknown, SafetyInspection>(
      `/api/inspection/safety/${id}/fail`,
      { reason }
    ),
};

// ---------------------------------------------------------------------------
// Inspection - Maintenance
// ---------------------------------------------------------------------------

export const maintenanceApi = {
  getAll: (params?: Record<string, unknown>) =>
    client.get<unknown, PageResponse<MaintenanceRecord>>(
      "/api/inspection/maintenance",
      { params }
    ),

  getById: (id: string) =>
    client.get<unknown, MaintenanceRecord>(
      `/api/inspection/maintenance/${id}`
    ),

  create: (data: Partial<MaintenanceRecord>) =>
    client.post<unknown, MaintenanceRecord>(
      "/api/inspection/maintenance",
      data
    ),

  update: (id: string, data: Partial<MaintenanceRecord>) =>
    client.put<unknown, MaintenanceRecord>(
      `/api/inspection/maintenance/${id}`,
      data
    ),

  delete: (id: string) =>
    client.delete(`/api/inspection/maintenance/${id}`),
};

// ---------------------------------------------------------------------------
// Settlement
// ---------------------------------------------------------------------------

export const settlementApi = {
  getAll: (params?: Record<string, unknown>) =>
    client.get<unknown, PageResponse<Settlement>>("/api/settlement", {
      params,
    }),

  generate: (data: {
    companyId: string;
    startDate: string;
    endDate: string;
  }) => client.post<unknown, Settlement>("/api/settlement/generate", data),

  // 백엔드는 POST
  send: (id: string) =>
    client.post<unknown, Settlement>(`/api/settlement/${id}/send`),

  // 백엔드: PUT /api/settlement/{id}/mark-paid
  markPaid: (id: string) =>
    client.put<unknown, Settlement>(`/api/settlement/${id}/mark-paid`),

  // 백엔드: /api/settlement/statistics/bp/{bpId} / /supplier/{supplierId}
  statsByBp: (bpId: string) =>
    client.get<unknown, SettlementStats>(`/api/settlement/statistics/bp/${bpId}`),

  statsBySupplier: (supplierId: string) =>
    client.get<unknown, SettlementStats>(`/api/settlement/statistics/supplier/${supplierId}`),

  // backward-compat (호출부 있으면 일단 bp 통계로 연결; 엄밀히는 사용자 컨텍스트 필요)
  stats: () => {
    // fallback: empty stats
    return Promise.resolve({} as SettlementStats);
  },
};

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

export const notificationsApi = {
  // 백엔드: GET /api/notifications/my
  getMy: (params?: Record<string, unknown>) =>
    client.get<unknown, PageResponse<Notification>>("/api/notifications/my", {
      params,
    }),

  // backward-compat
  getAll: (params?: Record<string, unknown>) =>
    client.get<unknown, PageResponse<Notification>>("/api/notifications/my", {
      params,
    }),

  // 백엔드: PUT /api/notifications/{id}/read
  markRead: (id: string) =>
    client.put(`/api/notifications/${id}/read`),

  // 백엔드엔 read-all 없음 — 각각 read 호출하도록 페이지에서 처리 필요
  markAllRead: () =>
    Promise.reject(new Error("markAllRead은 백엔드에서 지원하지 않음 — 개별 markRead 사용")),

  sendMessage: (data: {
    userId: string;
    title: string;
    message: string;
    type?: string;
  }) => client.post("/api/notifications/send", data),

  unreadCount: (userId: string) =>
    client.get<unknown, { unreadCount: number }>("/api/notifications/unread-count", {
      params: { userId },
    }),
};

// ---------------------------------------------------------------------------
// Location
// ---------------------------------------------------------------------------

export const locationApi = {
  update: (data: { latitude: number; longitude: number }) =>
    client.post("/api/location/update", data),

  // 백엔드: GET /api/location/worker/{workerId}/current
  getCurrent: (workerId: string) =>
    client.get<
      unknown,
      { latitude: number; longitude: number; updatedAt: string }
    >(`/api/location/worker/${workerId}/current`),

  // 백엔드: GET /api/location/worker/{workerId} ?date=
  getWorkerHistory: (workerId: string, date: string) =>
    client.get<
      unknown,
      Array<{ latitude: number; longitude: number; timestamp: string }>
    >(`/api/location/worker/${workerId}`, { params: { date } }),

  // 백엔드: GET /api/location/current/{siteId} (현장 기준 현재 모든 근로자 위치)
  getSiteCurrent: (siteId: string) =>
    client.get<
      unknown,
      Array<{ workerId: string; latitude: number; longitude: number; updatedAt: string }>
    >(`/api/location/current/${siteId}`),
};
