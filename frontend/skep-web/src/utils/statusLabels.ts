// Status enum value -> Korean label mapping

const STATUS_LABELS: Record<string, string> = {
  // CompanyStatus
  ACTIVE: "활성",
  PENDING: "대기",
  SUSPENDED: "정지",
  INACTIVE: "비활성",

  // EquipmentStatus
  AVAILABLE: "가용",
  DEPLOYED: "배치됨",
  MAINTENANCE: "정비중",
  RETIRED: "퇴역",

  // QuotationStatus
  DRAFT: "초안",
  SUBMITTED: "제출됨",
  ACCEPTED: "승인됨",
  REJECTED: "반려됨",
  EXPIRED: "만료됨",

  // ChecklistStatus
  APPROVED: "승인",
  OVERRIDE: "관리자 승인",

  // InspectionStatus
  IN_PROGRESS: "진행중",
  COMPLETED: "완료",
  FAILED: "불합격",

  // SettlementStatus
  GENERATED: "생성됨",
  SENT: "전송됨",
  PAID: "정산완료",
  OVERDUE: "연체",

  // UserRole
  ADMIN: "관리자",
  SUPPLIER: "공급사",
  BP: "BP",
  DRIVER: "운전원",
  INSPECTOR: "점검관",
  VIEWER: "열람자",
};

// Status enum value -> Tailwind color class mapping (bg + text)
const STATUS_COLORS: Record<string, { bg: string; text: string }> = {
  ACTIVE: { bg: "bg-green-100", text: "text-green-800" },
  AVAILABLE: { bg: "bg-green-100", text: "text-green-800" },
  COMPLETED: { bg: "bg-green-100", text: "text-green-800" },
  APPROVED: { bg: "bg-green-100", text: "text-green-800" },
  PAID: { bg: "bg-green-100", text: "text-green-800" },
  ACCEPTED: { bg: "bg-green-100", text: "text-green-800" },

  PENDING: { bg: "bg-amber-100", text: "text-amber-800" },
  DRAFT: { bg: "bg-gray-100", text: "text-gray-800" },
  IN_PROGRESS: { bg: "bg-blue-100", text: "text-blue-800" },
  DEPLOYED: { bg: "bg-blue-100", text: "text-blue-800" },
  GENERATED: { bg: "bg-blue-100", text: "text-blue-800" },
  SUBMITTED: { bg: "bg-blue-100", text: "text-blue-800" },
  SENT: { bg: "bg-indigo-100", text: "text-indigo-800" },

  SUSPENDED: { bg: "bg-red-100", text: "text-red-800" },
  REJECTED: { bg: "bg-red-100", text: "text-red-800" },
  FAILED: { bg: "bg-red-100", text: "text-red-800" },
  OVERDUE: { bg: "bg-red-100", text: "text-red-800" },
  INACTIVE: { bg: "bg-gray-100", text: "text-gray-600" },
  RETIRED: { bg: "bg-gray-100", text: "text-gray-600" },
  EXPIRED: { bg: "bg-gray-100", text: "text-gray-600" },

  MAINTENANCE: { bg: "bg-orange-100", text: "text-orange-800" },
  OVERRIDE: { bg: "bg-purple-100", text: "text-purple-800" },
};

const DEFAULT_COLOR = { bg: "bg-gray-100", text: "text-gray-800" };

/**
 * Get the Korean label for a status enum value.
 */
export function getStatusLabel(status: string | null | undefined): string {
  if (!status) return "-";
  return STATUS_LABELS[status] ?? status;
}

/**
 * Get the Tailwind color classes for a status enum value.
 */
export function getStatusColor(
  status: string | null | undefined
): { bg: string; text: string } {
  if (!status) return DEFAULT_COLOR;
  return STATUS_COLORS[status] ?? DEFAULT_COLOR;
}
