import { useState, useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { plansApi, queryKeys } from "@/api/endpoints";
import type { DeploymentPlan } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate } from "@/utils/formatDate";

const STATUS_OPTIONS = [
  { value: "", label: "전체 상태" },
  { value: "PENDING", label: "대기" },
  { value: "ACTIVE", label: "활성" },
  { value: "COMPLETED", label: "완료" },
  { value: "CANCELLED", label: "취소" },
];

export default function DeploymentManagement() {
  const [statusFilter, setStatusFilter] = useState("");

  const plansQuery = useQuery({
    queryKey: queryKeys.dispatch.plans({ size: 200 }),
    queryFn: () => plansApi.getAll({ size: 200 }),
  });

  const filteredData = useMemo(() => {
    const plans = plansQuery.data?.content ?? [];
    if (!statusFilter) return plans;
    return plans.filter((p) => p.status === statusFilter);
  }, [plansQuery.data, statusFilter]);

  const columns = useMemo<ColumnDef<DeploymentPlan, unknown>[]>(
    () => [
      { accessorKey: "siteName", header: "현장" },
      { accessorKey: "equipmentName", header: "장비" },
      { accessorKey: "driverName", header: "운전원" },
      {
        accessorKey: "startDate",
        header: "시작일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        accessorKey: "endDate",
        header: "종료일",
        cell: ({ getValue }) => formatDate(getValue() as string),
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
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">배치 관리</h1>
      </div>

      <div className="flex gap-3">
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
        >
          {STATUS_OPTIONS.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      </div>

      <DataTable
        columns={columns}
        data={filteredData}
        isLoading={plansQuery.isLoading}
        isError={plansQuery.isError}
        searchPlaceholder="현장, 장비, 운전원 검색..."
      />
    </div>
  );
}
