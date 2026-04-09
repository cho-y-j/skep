// --- Enums ---

export enum UserRole {
  ADMIN = "ADMIN",
  SUPPLIER = "SUPPLIER",
  BP = "BP",
  DRIVER = "DRIVER",
  INSPECTOR = "INSPECTOR",
  VIEWER = "VIEWER",
}

export enum CompanyType {
  SUPPLIER = "SUPPLIER",
  BP = "BP",
}

export enum CompanyStatus {
  ACTIVE = "ACTIVE",
  PENDING = "PENDING",
  SUSPENDED = "SUSPENDED",
  INACTIVE = "INACTIVE",
}

export enum EquipmentStatus {
  AVAILABLE = "AVAILABLE",
  DEPLOYED = "DEPLOYED",
  MAINTENANCE = "MAINTENANCE",
  RETIRED = "RETIRED",
}

export enum BoundaryType {
  CIRCLE = "CIRCLE",
  POLYGON = "POLYGON",
}

export enum QuotationStatus {
  DRAFT = "DRAFT",
  SUBMITTED = "SUBMITTED",
  ACCEPTED = "ACCEPTED",
  REJECTED = "REJECTED",
  EXPIRED = "EXPIRED",
}

export enum ChecklistStatus {
  PENDING = "PENDING",
  APPROVED = "APPROVED",
  REJECTED = "REJECTED",
  OVERRIDE = "OVERRIDE",
}

export enum InspectionStatus {
  PENDING = "PENDING",
  IN_PROGRESS = "IN_PROGRESS",
  COMPLETED = "COMPLETED",
  FAILED = "FAILED",
}

export enum SettlementStatus {
  DRAFT = "DRAFT",
  GENERATED = "GENERATED",
  SENT = "SENT",
  PAID = "PAID",
  OVERDUE = "OVERDUE",
}

// --- Core Entities ---

export interface User {
  id: string;
  email: string;
  name: string;
  phone: string;
  role: UserRole;
  companyId: string | null;
  companyName: string | null;
  active: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface Company {
  id: string;
  name: string;
  businessNumber: string;
  type: CompanyType;
  status: CompanyStatus;
  representativeName: string;
  phone: string;
  email: string;
  address: string;
  createdAt: string;
  updatedAt: string;
}

export interface Equipment {
  id: string;
  name: string;
  typeId: string;
  typeName: string;
  model: string;
  manufacturer: string;
  year: number;
  serialNumber: string;
  status: EquipmentStatus;
  companyId: string;
  companyName: string;
  createdAt: string;
  updatedAt: string;
}

export interface EquipmentType {
  id: string;
  name: string;
  category: string;
  description: string;
}

export interface Person {
  id: string;
  name: string;
  phone: string;
  role: string;
  companyId: string;
  companyName: string;
  equipmentId: string | null;
  equipmentName: string | null;
  active: boolean;
  createdAt: string;
}

export interface Site {
  id: string;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  boundaryType: BoundaryType;
  boundaryRadius: number | null;
  boundaryCoordinates: string | null;
  companyId: string;
  companyName: string;
  active: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface QuotationRequest {
  id: string;
  siteId: string;
  siteName: string;
  requesterId: string;
  requesterName: string;
  equipmentTypeId: string;
  equipmentTypeName: string;
  quantity: number;
  startDate: string;
  endDate: string;
  description: string;
  status: QuotationStatus;
  createdAt: string;
}

export interface QuotationItem {
  id: string;
  quotationId: string;
  equipmentTypeId: string;
  equipmentTypeName: string;
  unitPrice: number;
  quantity: number;
  subtotal: number;
  description: string;
}

export interface Quotation {
  id: string;
  requestId: string;
  supplierId: string;
  supplierName: string;
  status: QuotationStatus;
  totalAmount: number;
  validUntil: string;
  notes: string;
  items: QuotationItem[];
  createdAt: string;
  updatedAt: string;
}

export interface DeploymentPlan {
  id: string;
  siteId: string;
  siteName: string;
  equipmentId: string;
  equipmentName: string;
  driverId: string;
  driverName: string;
  startDate: string;
  endDate: string;
  status: string;
  notes: string;
  createdAt: string;
  updatedAt: string;
}

export interface DailyRoster {
  id: string;
  planId: string;
  date: string;
  driverId: string;
  driverName: string;
  equipmentId: string;
  equipmentName: string;
  siteId: string;
  siteName: string;
  status: ChecklistStatus;
  approvedBy: string | null;
  approvedAt: string | null;
  createdAt: string;
}

export interface WorkRecord {
  id: string;
  rosterId: string;
  driverId: string;
  driverName: string;
  siteId: string;
  siteName: string;
  date: string;
  clockInTime: string | null;
  workStartTime: string | null;
  workEndTime: string | null;
  clockInLatitude: number | null;
  clockInLongitude: number | null;
  totalHours: number | null;
  status: string;
  createdAt: string;
}

export interface DeploymentChecklist {
  id: string;
  rosterId: string;
  date: string;
  driverId: string;
  driverName: string;
  equipmentId: string;
  equipmentName: string;
  status: ChecklistStatus;
  items: DeploymentChecklistItem[];
  overrideReason: string | null;
  overriddenBy: string | null;
  completedAt: string | null;
}

export interface DeploymentChecklistItem {
  id: string;
  checklistId: string;
  category: string;
  item: string;
  checked: boolean;
  note: string | null;
}

export interface SafetyInspection {
  id: string;
  siteId: string;
  siteName: string;
  inspectorId: string;
  inspectorName: string;
  status: InspectionStatus;
  scheduledDate: string;
  completedAt: string | null;
  score: number | null;
  notes: string;
  items: SafetyInspectionItem[];
  createdAt: string;
  updatedAt: string;
}

export interface SafetyInspectionItem {
  id: string;
  inspectionId: string;
  category: string;
  item: string;
  passed: boolean | null;
  severity: string;
  note: string | null;
}

export interface MaintenanceRecord {
  id: string;
  equipmentId: string;
  equipmentName: string;
  type: string;
  description: string;
  scheduledDate: string;
  completedDate: string | null;
  cost: number | null;
  performedBy: string | null;
  status: string;
  createdAt: string;
}

export interface Settlement {
  id: string;
  companyId: string;
  companyName: string;
  period: string;
  startDate: string;
  endDate: string;
  totalAmount: number;
  status: SettlementStatus;
  generatedAt: string;
  sentAt: string | null;
  paidAt: string | null;
  lineItems: SettlementLineItem[];
  createdAt: string;
}

export interface SettlementLineItem {
  id: string;
  settlementId: string;
  description: string;
  quantity: number;
  unitPrice: number;
  amount: number;
}

export interface DocumentType {
  id: string;
  name: string;
  category: string;
  requiredForEquipment: boolean;
  requiredForPerson: boolean;
  validityDays: number | null;
}

export interface Document {
  id: string;
  typeId: string;
  typeName: string;
  ownerId: string;
  ownerType: string;
  ownerName: string;
  fileName: string;
  fileUrl: string;
  expiryDate: string | null;
  verified: boolean;
  verifiedBy: string | null;
  verifiedAt: string | null;
  createdAt: string;
}

export interface Notification {
  id: string;
  userId: string;
  title: string;
  message: string;
  type: string;
  referenceId: string | null;
  referenceType: string | null;
  read: boolean;
  createdAt: string;
}

// --- API Response Types ---

export interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
  first: boolean;
  last: boolean;
}

export interface ApiError {
  status: number;
  message: string;
  errors?: Record<string, string>;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  refreshToken: string;
  user: User;
}

export interface SettlementStats {
  totalGenerated: number;
  totalSent: number;
  totalPaid: number;
  totalOverdue: number;
  totalAmount: number;
  paidAmount: number;
}
