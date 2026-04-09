import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { ClipboardCheck, TrendingUp, AlertTriangle, Clock } from "lucide-react";
import { safetyApi, queryKeys } from "@/api/endpoints";
import type { SafetyInspection } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate } from "@/utils/formatDate";

export default function InspectionManagement() {
  const inspectionsQuery = useQuery({
    queryKey: queryKeys.inspection.safety({ size: 200 }),
    queryFn: () => safetyApi.getAll({ size: 200 }),
  });

  const inspections = inspectionsQuery.data?.content ?? [];

  const stats = useMemo(() => {
    const total = inspections.length;
    const completed = inspections.filter(
      (i) => i.status === "COMPLETED"
    ).length;
    const failed = inspections.filter((i) => i.status === "FAILED").length;
    const pending = inspections.filter(
      (i) => i.status === "PENDING" || i.status === "IN_PROGRESS"
    ).length;
    const completionRate = total > 0 ? Math.round((completed / total) * 100) : 0;
    return { total, completed, failed, pending, completionRate };
  }, [inspections]);

  const columns = useMemo<ColumnDef<SafetyInspection, unknown>[]>(
    () => [
      { accessorKey: "siteName", header: "현장" },
      { accessorKey: "inspectorName", header: "점검관" },
      {
        accessorKey: "scheduledDate",
        header: "예정일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        accessorKey: "completedAt",
        header: "완료일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        accessorKey: "score",
        header: "점수",
        cell: ({ getValue }) => {
          const score = getValue() as number | null;
          if (score == null) return "-";
          return (
            <span
              className={`font-medium ${
                score >= 80
                  ? "text-green-600"
                  : score >= 60
                  ? "text-amber-600"
                  : "text-red-600"
              }`}
            >
              {score}점
            </span>
          );
        },
      },
      {
        accessorKey: "status",
        header: "상태",
        cell: ({ getValue }) => <StatusBadge status={getValue() as string} />,
      },
    ],
    []
  );

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">안전 점검 관리</h1>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <div className="flex items-center gap-3">
            <div className="rounded-lg bg-blue-100 p-2">
              <ClipboardCheck className="h-5 w-5 text-blue-600" />
            </div>
            <div>
              <p className="text-xs text-gray-500">전체</p>
              <p className="text-xl font-bold text-gray-900">{stats.total}</p>
            </div>
          </div>
        </div>
        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <div className="flex items-center gap-3">
            <div className="rounded-lg bg-green-100 p-2">
              <TrendingUp className="h-5 w-5 text-green-600" />
            </div>
            <div>
              <p className="text-xs text-gray-500">완료율</p>
              <p className="text-xl font-bold text-gray-900">
                {stats.completionRate}%
              </p>
            </div>
          </div>
        </div>
        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <div className="flex items-center gap-3">
            <div className="rounded-lg bg-red-100 p-2">
              <AlertTriangle className="h-5 w-5 text-red-600" />
            </div>
            <div>
              <p className="text-xs text-gray-500">불합격</p>
              <p className="text-xl font-bold text-gray-900">{stats.failed}</p>
            </div>
          </div>
        </div>
        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <div className="flex items-center gap-3">
            <div className="rounded-lg bg-amber-100 p-2">
              <Clock className="h-5 w-5 text-amber-600" />
            </div>
            <div>
              <p className="text-xs text-gray-500">대기/진행중</p>
              <p className="text-xl font-bold text-gray-900">{stats.pending}</p>
            </div>
          </div>
        </div>
      </div>

      <DataTable
        columns={columns}
        data={inspections}
        isLoading={inspectionsQuery.isLoading}
        isError={inspectionsQuery.isError}
        searchPlaceholder="현장 또는 점검관 검색..."
      />
    </div>
  );
}
