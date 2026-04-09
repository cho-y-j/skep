import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { safetyApi, queryKeys } from "@/api/endpoints";
import type { SafetyInspection } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate } from "@/utils/formatDate";

export default function InspectionStatus() {
  const { data, isLoading, isError } = useQuery({
    queryKey: queryKeys.inspection.safety({ size: 100 }),
    queryFn: () => safetyApi.getAll({ size: 100 }),
  });

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
          return score != null ? `${score}점` : "-";
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
    <div className="space-y-4 p-6">
      <h1 className="text-2xl font-bold text-gray-900">안전 점검 현황</h1>
      <DataTable
        columns={columns}
        data={data?.content ?? []}
        isLoading={isLoading}
        isError={isError}
        searchPlaceholder="현장, 점검관 검색..."
      />
    </div>
  );
}
