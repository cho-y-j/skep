import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { settlementApi, queryKeys } from "@/api/endpoints";
import type { Settlement as SettlementType } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate, formatMoney } from "@/utils/formatDate";

export default function Settlement() {
  const { data, isLoading, isError } = useQuery({
    queryKey: queryKeys.settlement.all({ size: 100 }),
    queryFn: () => settlementApi.getAll({ size: 100 }),
  });

  const columns = useMemo<ColumnDef<SettlementType, unknown>[]>(
    () => [
      { accessorKey: "companyName", header: "업체" },
      { accessorKey: "period", header: "기간" },
      {
        accessorKey: "totalAmount",
        header: "총액",
        cell: ({ getValue }) => formatMoney(getValue() as number),
      },
      {
        accessorKey: "status",
        header: "상태",
        cell: ({ getValue }) => <StatusBadge status={getValue() as string} />,
      },
      {
        accessorKey: "generatedAt",
        header: "생성일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        accessorKey: "sentAt",
        header: "전송일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        accessorKey: "paidAt",
        header: "정산일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
    ],
    []
  );

  return (
    <div className="space-y-4 p-6">
      <h1 className="text-2xl font-bold text-gray-900">정산 관리</h1>
      <DataTable
        columns={columns}
        data={data?.content ?? []}
        isLoading={isLoading}
        isError={isError}
        searchPlaceholder="업체 검색..."
      />
    </div>
  );
}
