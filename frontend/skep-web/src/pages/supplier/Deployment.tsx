import { useState, useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { plansApi, sitesApi, queryKeys } from "@/api/endpoints";
import type { DeploymentPlan } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate } from "@/utils/formatDate";

export default function Deployment() {
  const [siteId, setSiteId] = useState("");

  const sitesQuery = useQuery({
    queryKey: queryKeys.dispatch.sites({ size: 200 }),
    queryFn: () => sitesApi.getAll({ size: 200 }),
  });

  const plansQuery = useQuery({
    queryKey: queryKeys.dispatch.plans({
      size: 100,
      ...(siteId ? { siteId } : {}),
    }),
    queryFn: () =>
      plansApi.getAll({ size: 100, ...(siteId ? { siteId } : {}) }),
  });

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
      {
        accessorKey: "createdAt",
        header: "생성일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
    ],
    []
  );

  return (
    <div className="space-y-4 p-6">
      <h1 className="text-2xl font-bold text-gray-900">배치 현황</h1>

      <div className="flex items-center gap-4">
        <select
          value={siteId}
          onChange={(e) => setSiteId(e.target.value)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
        >
          <option value="">전체 현장</option>
          {(sitesQuery.data?.content ?? []).map((site) => (
            <option key={site.id} value={site.id}>
              {site.name}
            </option>
          ))}
        </select>
      </div>

      <DataTable
        columns={columns}
        data={plansQuery.data?.content ?? []}
        isLoading={plansQuery.isLoading}
        isError={plansQuery.isError}
        searchPlaceholder="현장, 장비, 운전원 검색..."
      />
    </div>
  );
}
