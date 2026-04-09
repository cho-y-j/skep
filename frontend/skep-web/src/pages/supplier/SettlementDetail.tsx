import { useState, useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { settlementApi, companiesApi, queryKeys } from "@/api/endpoints";
import type { Settlement, SettlementLineItem, CompanyType } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate, formatMoney } from "@/utils/formatDate";

export default function SettlementDetail() {
  const [companyId, setCompanyId] = useState("");
  const [month, setMonth] = useState(
    new Date().toISOString().slice(0, 7)
  );

  const bpQuery = useQuery({
    queryKey: queryKeys.companies.byType("BP" as CompanyType),
    queryFn: () => companiesApi.getByType("BP" as CompanyType, { size: 200 }),
  });

  const settlementsQuery = useQuery({
    queryKey: queryKeys.settlement.all({
      ...(companyId ? { companyId } : {}),
      month,
      size: 100,
    }),
    queryFn: () =>
      settlementApi.getAll({
        ...(companyId ? { companyId } : {}),
        month,
        size: 100,
      }),
  });

  const selectedSettlement = (settlementsQuery.data?.content ?? [])[0] as
    | Settlement
    | undefined;

  const summaryColumns = useMemo<ColumnDef<Settlement, unknown>[]>(
    () => [
      { accessorKey: "companyName", header: "BP" },
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
    ],
    []
  );

  const lineColumns = useMemo<ColumnDef<SettlementLineItem, unknown>[]>(
    () => [
      { accessorKey: "description", header: "항목" },
      { accessorKey: "quantity", header: "수량" },
      {
        accessorKey: "unitPrice",
        header: "단가",
        cell: ({ getValue }) => formatMoney(getValue() as number),
      },
      {
        accessorKey: "amount",
        header: "금액",
        cell: ({ getValue }) => formatMoney(getValue() as number),
      },
    ],
    []
  );

  return (
    <div className="space-y-6 p-6">
      <h1 className="text-2xl font-bold text-gray-900">정산 상세</h1>

      <div className="flex items-center gap-4">
        <select
          value={companyId}
          onChange={(e) => setCompanyId(e.target.value)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
        >
          <option value="">전체 BP</option>
          {(bpQuery.data?.content ?? []).map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
        <input
          type="month"
          value={month}
          onChange={(e) => setMonth(e.target.value)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
        />
      </div>

      <DataTable
        columns={summaryColumns}
        data={settlementsQuery.data?.content ?? []}
        isLoading={settlementsQuery.isLoading}
        isError={settlementsQuery.isError}
        searchPlaceholder="BP 검색..."
      />

      {selectedSettlement && selectedSettlement.lineItems.length > 0 && (
        <div className="space-y-3">
          <h2 className="text-lg font-semibold text-gray-900">
            일별 내역 - {selectedSettlement.companyName}
          </h2>
          <DataTable
            columns={lineColumns}
            data={selectedSettlement.lineItems}
            searchPlaceholder="항목 검색..."
          />
        </div>
      )}
    </div>
  );
}
