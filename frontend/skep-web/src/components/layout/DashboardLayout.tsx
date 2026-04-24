import { Outlet } from "react-router-dom";
import {
  LayoutDashboard,
  Building2,
  Truck,
  FileText,
  CalendarDays,
  ClipboardCheck,
  Shield,
  Wallet,
  Bell,
  Users,
  MapPin,
  Handshake,
  Clock,
  Wrench,
  FileSignature,
  Search,
  Eye,
  ShieldCheck,
  ClipboardList,
} from "lucide-react";
import { Sidebar, type MenuItem } from "./Sidebar";
import { TopBar } from "./TopBar";
import { useAuth } from "@/hooks/useAuth";

// ---------------------------------------------------------------------------
// Admin menu
// ---------------------------------------------------------------------------
const ADMIN_MENU: MenuItem[] = [
  { label: "대시보드", path: "/", icon: LayoutDashboard },
  { label: "업체 관리", path: "/companies", icon: Building2 },
  {
    label: "장비/인력",
    icon: Truck,
    children: [
      { label: "장비 목록", path: "/equipment" },
      { label: "인력 목록", path: "/equipment/persons" },
      { label: "장비 유형", path: "/equipment/types" },
    ],
  },
  { label: "문서 관리", path: "/documents", icon: FileText },
  { label: "서류 검증", path: "/verification", icon: ShieldCheck },
  { label: "작업계획서 생성", path: "/worksheet/new", icon: ClipboardList },
  {
    label: "배치 관리",
    icon: CalendarDays,
    children: [
      { label: "배치 계획", path: "/dispatch/plans" },
      { label: "일일 배치표", path: "/dispatch/rosters" },
      { label: "작업 기록", path: "/dispatch/work-records" },
      { label: "현장 관리", path: "/dispatch/sites" },
      { label: "견적 관리", path: "/dispatch/quotations" },
      { label: "체크리스트", path: "/dispatch/checklists" },
    ],
  },
  {
    label: "점검 관리",
    icon: ClipboardCheck,
    children: [
      { label: "안전 점검", path: "/inspection/safety" },
      { label: "정비 이력", path: "/inspection/maintenance" },
    ],
  },
  { label: "정산 관리", path: "/settlement", icon: Wallet },
  { label: "현장 위치", path: "/location", icon: MapPin },
  { label: "알림", path: "/notifications", icon: Bell },
  { label: "사용자 관리", path: "/users", icon: Users },
];

// ---------------------------------------------------------------------------
// Supplier menu
// ---------------------------------------------------------------------------
const SUPPLIER_MENU: MenuItem[] = [
  { label: "대시보드", path: "/supplier", icon: LayoutDashboard },
  {
    label: "장비 관리",
    icon: Truck,
    children: [
      { label: "장비 목록", path: "/supplier/equipment" },
      { label: "장비 등록", path: "/supplier/equipment/register" },
    ],
  },
  {
    label: "인력 관리",
    icon: Users,
    children: [
      { label: "인력 목록", path: "/supplier/personnel" },
      { label: "인력 등록", path: "/supplier/personnel/register" },
    ],
  },
  { label: "서류 관리", path: "/supplier/documents", icon: FileText },
  { label: "서류 미리보기", path: "/supplier/documents/preview", icon: Eye },
  { label: "서류 검증", path: "/supplier/verification", icon: ShieldCheck },
  { label: "배치 현황", path: "/supplier/deployment", icon: CalendarDays },
  { label: "매칭 응답", path: "/supplier/matching", icon: Handshake },
  { label: "출근 관리", path: "/supplier/attendance", icon: Clock },
  { label: "정비 점검", path: "/supplier/maintenance", icon: Wrench },
  { label: "정산 상세", path: "/supplier/settlement", icon: Wallet },
  { label: "견적 관리", path: "/supplier/quotations", icon: FileSignature },
  { label: "직원 관리", path: "/supplier/employees", icon: Users },
];

// ---------------------------------------------------------------------------
// BP menu
// ---------------------------------------------------------------------------
const BP_MENU: MenuItem[] = [
  { label: "대시보드", path: "/bp", icon: LayoutDashboard },
  { label: "배치 계획", path: "/bp/deployment-plan", icon: CalendarDays },
  { label: "매칭 요청", path: "/bp/matching", icon: Search },
  { label: "일일 배치표", path: "/bp/daily-roster", icon: ClipboardCheck },
  { label: "안전 점검", path: "/bp/inspection", icon: Shield },
  { label: "정산 관리", path: "/bp/settlement", icon: Wallet },
  { label: "위치 추적", path: "/bp/location", icon: MapPin },
  { label: "작업 확인서", path: "/bp/work-confirmation", icon: FileSignature },
  { label: "현장 관리", path: "/bp/sites", icon: Building2 },
  { label: "견적 관리", path: "/bp/quotations", icon: FileText },
  { label: "체크리스트", path: "/bp/checklist", icon: ShieldCheck },
  { label: "직원 관리", path: "/bp/employees", icon: Users },
  { label: "작업계획서 생성", path: "/bp/worksheet/new", icon: ClipboardList },
];

// ---------------------------------------------------------------------------
// Worker menu (DRIVER / INSPECTOR)
// ---------------------------------------------------------------------------
const WORKER_MENU: MenuItem[] = [
  { label: "대시보드", path: "/worker", icon: LayoutDashboard },
  { label: "출근 기록", path: "/worker/attendance", icon: Clock },
  { label: "작업 확인서", path: "/worker/work-confirmation", icon: FileSignature },
  { label: "안전 점검", path: "/worker/safety-inspection", icon: Shield },
  { label: "정비 점검", path: "/worker/maintenance", icon: Wrench },
  { label: "위치 확인", path: "/worker/location", icon: MapPin },
];

function getMenuForRole(role: string | undefined): MenuItem[] {
  switch (role) {
    case "ADMIN":
      return ADMIN_MENU;
    case "SUPPLIER":
      return SUPPLIER_MENU;
    case "BP":
      return BP_MENU;
    case "DRIVER":
    case "INSPECTOR":
      return WORKER_MENU;
    default:
      return ADMIN_MENU;
  }
}

export function DashboardLayout() {
  const { user } = useAuth();
  const menuItems = getMenuForRole(user?.role);

  return (
    <div className="flex h-screen overflow-hidden bg-gray-50">
      <Sidebar menuItems={menuItems} />
      <div className="flex flex-1 flex-col overflow-hidden">
        <TopBar />
        <main className="flex-1 overflow-y-auto">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
