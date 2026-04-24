import { lazy, Suspense, useEffect } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "react-hot-toast";
import { Loader2 } from "lucide-react";
import { useAuthStore } from "@/stores/authStore";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { LoginPage } from "@/pages/auth/LoginPage";

// ---------------------------------------------------------------------------
// Admin pages
// ---------------------------------------------------------------------------
const AdminDashboard = lazy(() => import("@/pages/admin/DashboardHome"));
const AdminCompanyList = lazy(() => import("@/pages/admin/CompanyList"));
const AdminUserManagement = lazy(() => import("@/pages/admin/UserManagement"));
const AdminBpManagement = lazy(() => import("@/pages/admin/BpManagement"));
const AdminEquipmentStatus = lazy(() => import("@/pages/admin/EquipmentStatus"));
const AdminEquipmentTypeSettings = lazy(() => import("@/pages/admin/EquipmentTypeSettings"));
const AdminPersonnelTypeSettings = lazy(() => import("@/pages/admin/PersonnelTypeSettings"));
const AdminDocumentManagement = lazy(() => import("@/pages/admin/DocumentManagement"));
const AdminDocumentTypeManagement = lazy(() => import("@/pages/admin/DocumentTypeManagement"));
const AdminDeploymentManagement = lazy(() => import("@/pages/admin/DeploymentManagement"));
const AdminSiteManagement = lazy(() => import("@/pages/admin/SiteManagement"));
const AdminQuotationManagement = lazy(() => import("@/pages/admin/QuotationManagement"));
const AdminChecklistManagement = lazy(() => import("@/pages/admin/ChecklistManagement"));
const AdminInspectionManagement = lazy(() => import("@/pages/admin/InspectionManagement"));
const AdminSettlement = lazy(() => import("@/pages/admin/Settlement"));
const AdminStatistics = lazy(() => import("@/pages/admin/Statistics"));
const AdminNotifications = lazy(() => import("@/pages/admin/Notifications"));
const AdminVerification = lazy(() => import("@/pages/admin/Verification"));
const AdminSupplierDocVerification = lazy(() => import("@/pages/admin/SupplierDocVerification"));

// ---------------------------------------------------------------------------
// Shared pages
// ---------------------------------------------------------------------------
const WorkPlanCreate = lazy(() => import("@/pages/shared/WorkPlanCreate"));
const WorkPlanEditor = lazy(() => import("@/pages/shared/WorkPlanEditor"));

// ---------------------------------------------------------------------------
// Supplier pages
// ---------------------------------------------------------------------------
const SupplierDashboard = lazy(() => import("@/pages/supplier/Dashboard"));
const SupplierEquipmentList = lazy(() => import("@/pages/supplier/EquipmentList"));
const SupplierEquipmentRegister = lazy(() => import("@/pages/supplier/EquipmentRegister"));
const SupplierPersonnelList = lazy(() => import("@/pages/supplier/PersonnelList"));
const SupplierPersonnelRegister = lazy(() => import("@/pages/supplier/PersonnelRegister"));
const SupplierDocumentManagement = lazy(() => import("@/pages/supplier/DocumentManagement"));
const SupplierDeployment = lazy(() => import("@/pages/supplier/Deployment"));
const SupplierMatchingResponse = lazy(() => import("@/pages/supplier/MatchingResponse"));
const SupplierAttendance = lazy(() => import("@/pages/supplier/Attendance"));
const SupplierMaintenanceCheck = lazy(() => import("@/pages/supplier/MaintenanceCheck"));
const SupplierSettlementDetail = lazy(() => import("@/pages/supplier/SettlementDetail"));
const SupplierQuotationManagement = lazy(() => import("@/pages/supplier/QuotationManagement"));
const SupplierEmployeeManagement = lazy(() => import("@/pages/supplier/EmployeeManagement"));
const SupplierDocumentPreview = lazy(() => import("@/pages/supplier/DocumentPreview"));
const SupplierVerification = lazy(() => import("@/pages/supplier/Verification"));

// ---------------------------------------------------------------------------
// BP pages
// ---------------------------------------------------------------------------
const BpDashboard = lazy(() => import("@/pages/bp/Dashboard"));
const BpDeploymentPlan = lazy(() => import("@/pages/bp/DeploymentPlan"));
const BpMatching = lazy(() => import("@/pages/bp/Matching"));
const BpDailyRoster = lazy(() => import("@/pages/bp/DailyRoster"));
const BpInspectionStatus = lazy(() => import("@/pages/bp/InspectionStatus"));
const BpSettlement = lazy(() => import("@/pages/bp/Settlement"));
const BpLocationTracking = lazy(() => import("@/pages/bp/LocationTracking"));
const BpWorkConfirmation = lazy(() => import("@/pages/bp/WorkConfirmation"));
const BpSiteManagement = lazy(() => import("@/pages/bp/SiteManagement"));
const BpQuotationManagement = lazy(() => import("@/pages/bp/QuotationManagement"));
const BpChecklist = lazy(() => import("@/pages/bp/Checklist"));
const BpEmployeeManagement = lazy(() => import("@/pages/bp/EmployeeManagement"));

// ---------------------------------------------------------------------------
// Worker pages
// ---------------------------------------------------------------------------
const WorkerDashboard = lazy(() => import("@/pages/worker/Dashboard"));
const WorkerAttendance = lazy(() => import("@/pages/worker/Attendance"));
const WorkerWorkConfirmation = lazy(() => import("@/pages/worker/WorkConfirmation"));
const WorkerSafetyInspection = lazy(() => import("@/pages/worker/SafetyInspection"));
const WorkerMaintenanceCheck = lazy(() => import("@/pages/worker/MaintenanceCheck"));
const WorkerLocationTracking = lazy(() => import("@/pages/worker/LocationTracking"));

// ---------------------------------------------------------------------------
// Query client
// ---------------------------------------------------------------------------
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,
      gcTime: 10 * 60 * 1000,
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

function PageLoader() {
  return (
    <div className="flex h-full items-center justify-center">
      <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
    </div>
  );
}

function AuthGuard({ children }: { children: React.ReactNode }) {
  const token = useAuthStore((s) => s.token);
  if (!token) {
    return <Navigate to="/login" replace />;
  }
  return <>{children}</>;
}

function AppRoutes() {
  const initialize = useAuthStore((s) => s.initialize);

  useEffect(() => {
    initialize();
  }, [initialize]);

  return (
    <Suspense fallback={<PageLoader />}>
      <Routes>
        <Route path="/login" element={<LoginPage />} />

        {/* 편집기는 DashboardLayout 밖 최상위로 — OnlyOffice가 주입하는 DOM이
            사이드바/탑바가 있는 레이아웃 리렌더 주기와 충돌해서 insertBefore 에러가 남 */}
        <Route path="/worksheet/edit/:sessionId" element={<AuthGuard><WorkPlanEditor /></AuthGuard>} />
        <Route path="/bp/worksheet/edit/:sessionId" element={<AuthGuard><WorkPlanEditor /></AuthGuard>} />

        <Route
          path="/*"
          element={
            <AuthGuard>
              <DashboardLayout />
            </AuthGuard>
          }
        >
          {/* ---- Admin routes ---- */}
          <Route index element={<AdminDashboard />} />
          <Route path="worksheet/new" element={<WorkPlanCreate />} />
          <Route path="companies" element={<AdminCompanyList />} />
          <Route path="users" element={<AdminUserManagement />} />
          <Route path="bp" element={<AdminBpManagement />} />
          <Route path="equipment" element={<AdminEquipmentStatus />} />
          <Route path="equipment/persons" element={<AdminEquipmentStatus />} />
          <Route path="equipment/types" element={<AdminEquipmentTypeSettings />} />
          <Route path="personnel/types" element={<AdminPersonnelTypeSettings />} />
          <Route path="documents" element={<AdminDocumentManagement />} />
          <Route path="documents/types" element={<AdminDocumentTypeManagement />} />
          <Route path="dispatch/plans" element={<AdminDeploymentManagement />} />
          <Route path="dispatch/rosters" element={<AdminDeploymentManagement />} />
          <Route path="dispatch/work-records" element={<AdminDeploymentManagement />} />
          <Route path="dispatch/sites" element={<AdminSiteManagement />} />
          <Route path="dispatch/quotations" element={<AdminQuotationManagement />} />
          <Route path="dispatch/checklists" element={<AdminChecklistManagement />} />
          <Route path="inspection/safety" element={<AdminInspectionManagement />} />
          <Route path="inspection/maintenance" element={<AdminInspectionManagement />} />
          <Route path="settlement" element={<AdminSettlement />} />
          <Route path="statistics" element={<AdminStatistics />} />
          <Route path="notifications" element={<AdminNotifications />} />
          <Route path="verification" element={<AdminSupplierDocVerification />} />
          <Route path="verification/legacy" element={<AdminVerification />} />
          <Route path="location" element={<AdminDashboard />} />

          {/* ---- Supplier routes ---- */}
          <Route path="supplier" element={<SupplierDashboard />} />
          <Route path="supplier/equipment" element={<SupplierEquipmentList />} />
          <Route path="supplier/equipment/register" element={<SupplierEquipmentRegister />} />
          <Route path="supplier/personnel" element={<SupplierPersonnelList />} />
          <Route path="supplier/personnel/register" element={<SupplierPersonnelRegister />} />
          <Route path="supplier/documents" element={<SupplierDocumentManagement />} />
          <Route path="supplier/documents/preview" element={<SupplierDocumentPreview />} />
          <Route path="supplier/verification" element={<SupplierVerification />} />
          <Route path="supplier/deployment" element={<SupplierDeployment />} />
          <Route path="supplier/matching" element={<SupplierMatchingResponse />} />
          <Route path="supplier/attendance" element={<SupplierAttendance />} />
          <Route path="supplier/maintenance" element={<SupplierMaintenanceCheck />} />
          <Route path="supplier/settlement" element={<SupplierSettlementDetail />} />
          <Route path="supplier/quotations" element={<SupplierQuotationManagement />} />
          <Route path="supplier/employees" element={<SupplierEmployeeManagement />} />

          {/* ---- BP routes ---- */}
          <Route path="bp" element={<BpDashboard />} />
          <Route path="bp/deployment-plan" element={<BpDeploymentPlan />} />
          <Route path="bp/matching" element={<BpMatching />} />
          <Route path="bp/daily-roster" element={<BpDailyRoster />} />
          <Route path="bp/inspection" element={<BpInspectionStatus />} />
          <Route path="bp/settlement" element={<BpSettlement />} />
          <Route path="bp/location" element={<BpLocationTracking />} />
          <Route path="bp/work-confirmation" element={<BpWorkConfirmation />} />
          <Route path="bp/sites" element={<BpSiteManagement />} />
          <Route path="bp/quotations" element={<BpQuotationManagement />} />
          <Route path="bp/checklist" element={<BpChecklist />} />
          <Route path="bp/employees" element={<BpEmployeeManagement />} />
          <Route path="bp/worksheet/new" element={<WorkPlanCreate />} />

          {/* ---- Worker routes ---- */}
          <Route path="worker" element={<WorkerDashboard />} />
          <Route path="worker/attendance" element={<WorkerAttendance />} />
          <Route path="worker/work-confirmation" element={<WorkerWorkConfirmation />} />
          <Route path="worker/safety-inspection" element={<WorkerSafetyInspection />} />
          <Route path="worker/maintenance" element={<WorkerMaintenanceCheck />} />
          <Route path="worker/location" element={<WorkerLocationTracking />} />
        </Route>
      </Routes>
    </Suspense>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <AppRoutes />
        <Toaster
          position="top-right"
          toastOptions={{
            duration: 4000,
            style: {
              background: "#363636",
              color: "#fff",
              fontSize: "14px",
            },
          }}
        />
      </BrowserRouter>
    </QueryClientProvider>
  );
}
