import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { Truck, Users, Building2, DollarSign } from "lucide-react";
import {
  equipmentApi,
  companiesApi,
  settlementApi,
  queryKeys,
} from "@/api/endpoints";
import { DataTable } from "@/components/common/DataTable";
import { formatMoney } from "@/utils/formatDate";
import type { Settlement } from "@/types";

export default function Statistics() {
  const equipmentQuery = useQuery({
    queryKey: queryKeys.equipment.all({ size: 1 }),
    queryFn: () => equipmentApi.getAll({ size: 1 }),
  });

  const personsQuery = useQuery({
    queryKey: queryKeys.equipment.persons({ size: 1 }),
    queryFn: () => equipmentApi.getPersons({ size: 1 }),
  });

  const companiesQuery = useQuery({
    queryKey: queryKeys.companies.all({ size: 1 }),
    queryFn: () => companiesApi.getAll({ size: 1 }),
  });

  const statsQuery = useQuery({
    queryKey: queryKeys.settlement.stats,
    queryFn: () => settlementApi.stats(),
  });

  const settlementsQuery = useQuery({
    queryKey: queryKeys.settlement.all({ size: 200 }),
    queryFn: () => settlementApi.getAll({ size: 200 }),
  });

  // Aggregate settlement by company
  const companySettlements = useMemo(() => {
    const map: Record<string, { companyName: string; total: number; paid: number; count: number }> = {};
    (settlementsQuery.data?.content ?? []).forEach((s) => {
      if (!map[s.companyId]) {
        map[s.companyId] = { companyName: s.companyName, total: 0, paid: 0, count: 0 };
      }
      map[s.companyId].total += s.totalAmount;
      if (s.status === "PAID") map[s.companyId].paid += s.totalAmount;
      map[s.companyId].count += 1;
    });
    return Object.values(map);
  }, [settlementsQuery.data]);

  type CompanySettlement = (typeof companySettlements)[number];

  const columns = useMemo<ColumnDef<CompanySettlement, unknown>[]>(
    () => [
      { accessorKey: "companyName", header: "회사명" },
      {
        accessorKey: "total",
        header: "총 정산액",
        cell: ({ getValue }) => formatMoney(getValue() as number),
      },
      {
        accessorKey: "paid",
        header: "정산완료",
        cell: ({ getValue }) => formatMoney(getValue() as number),
      },
      {
        id: "unpaid",
        header: "미정산",
        cell: ({ row }) =>
          formatMoney(row.original.total - row.original.paid),
      },
      { accessorKey: "count", header: "건수" },
    ],
    []
  );

  const cards = [
    {
      title: "총 장비",
      value: equipmentQuery.data?.totalElements ?? 0,
      icon: Truck,
      color: "bg-blue-100 text-blue-600",
      isLoading: equipmentQuery.isLoading,
    },
    {
      title: "총 인원",
      value: personsQuery.data?.totalElements ?? 0,
      icon: Users,
      color: "bg-green-100 text-green-600",
      isLoading: personsQuery.isLoading,
    },
    {
      title: "총 회사",
      value: companiesQuery.data?.totalElements ?? 0,
      icon: Building2,
      color: "bg-purple-100 text-purple-600",
      isLoading: companiesQuery.isLoading,
    },
    {
      title: "총 정산액",
      value: statsQuery.data?.totalAmount ?? 0,
      icon: DollarSign,
      color: "bg-orange-100 text-orange-600",
      isLoading: statsQuery.isLoading,
      isMoney: true,
    },
  ];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">통계</h1>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {cards.map((card) => {
          const Icon = card.icon;
          return (
            <div
              key={card.title}
              className="rounded-xl border border-gray-200 bg-white p-5"
            >
              <div className="flex items-center gap-3">
                <div className={`rounded-lg p-2.5 ${card.color}`}>
                  <Icon className="h-5 w-5" />
                </div>
                <div>
                  <p className="text-xs text-gray-500">{card.title}</p>
                  <p className="text-xl font-bold text-gray-900">
                    {card.isLoading
                      ? "-"
                      : card.isMoney
                      ? formatMoney(card.value)
                      : card.value.toLocaleString()}
                  </p>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="rounded-xl border border-gray-200 bg-white p-6">
        <h2 className="mb-4 text-lg font-semibold text-gray-900">
          회사별 정산 현황
        </h2>
        <DataTable
          columns={columns}
          data={companySettlements}
          isLoading={settlementsQuery.isLoading}
          isError={settlementsQuery.isError}
          searchPlaceholder="회사명 검색..."
        />
      </div>
    </div>
  );
}
