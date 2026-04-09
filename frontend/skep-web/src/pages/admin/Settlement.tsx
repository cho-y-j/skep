import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import toast from "react-hot-toast";
import {
  DollarSign,
  Send,
  CheckCircle,
  AlertCircle,
  BarChart3,
  Calendar,
  List,
} from "lucide-react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from "recharts";
import { settlementApi, queryKeys } from "@/api/endpoints";
import type { Settlement as SettlementType } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate, formatMoney } from "@/utils/formatDate";

type TabKey = "list" | "calendar" | "chart";

const PIE_COLORS = ["#3b82f6", "#22c55e", "#f59e0b", "#ef4444", "#8b5cf6"];

export default function SettlementPage() {
  const [tab, setTab] = useState<TabKey>("list");
  const queryClient = useQueryClient();

  const settlementsQuery = useQuery({
    queryKey: queryKeys.settlement.all({ size: 200 }),
    queryFn: () => settlementApi.getAll({ size: 200 }),
  });

  const statsQuery = useQuery({
    queryKey: queryKeys.settlement.stats,
    queryFn: () => settlementApi.stats(),
  });

  const sendMutation = useMutation({
    mutationFn: (id: string) => settlementApi.send(id),
    onSuccess: () => {
      toast.success("정산서가 발송되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["settlement"] });
    },
  });

  const paidMutation = useMutation({
    mutationFn: (id: string) => settlementApi.markPaid(id),
    onSuccess: () => {
      toast.success("정산완료 처리되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["settlement"] });
    },
  });

  const settlements = settlementsQuery.data?.content ?? [];
  const stats = statsQuery.data;

  // Chart data
  const barData = useMemo(() => {
    const byMonth: Record<string, number> = {};
    settlements.forEach((s) => {
      const month = s.period || formatDate(s.startDate, "yyyy-MM");
      byMonth[month] = (byMonth[month] ?? 0) + s.totalAmount;
    });
    return Object.entries(byMonth)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([month, amount]) => ({ month, amount }));
  }, [settlements]);

  const pieData = useMemo(() => {
    if (!stats) return [];
    return [
      { name: "생성됨", value: stats.totalGenerated },
      { name: "전송됨", value: stats.totalSent },
      { name: "정산완료", value: stats.totalPaid },
      { name: "연체", value: stats.totalOverdue },
    ].filter((d) => d.value > 0);
  }, [stats]);

  const columns = useMemo<ColumnDef<SettlementType, unknown>[]>(
    () => [
      { accessorKey: "companyName", header: "회사" },
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
        id: "actions",
        header: "관리",
        enableSorting: false,
        cell: ({ row }) => {
          const s = row.original;
          return (
            <div className="flex gap-1">
              {(s.status === "GENERATED" || s.status === "DRAFT") && (
                <button
                  type="button"
                  onClick={() => sendMutation.mutate(s.id)}
                  className="rounded p-1 text-blue-600 hover:bg-blue-50"
                  title="발송"
                >
                  <Send className="h-4 w-4" />
                </button>
              )}
              {s.status === "SENT" && (
                <button
                  type="button"
                  onClick={() => paidMutation.mutate(s.id)}
                  className="rounded p-1 text-green-600 hover:bg-green-50"
                  title="정산완료"
                >
                  <CheckCircle className="h-4 w-4" />
                </button>
              )}
            </div>
          );
        },
      },
    ],
    [sendMutation, paidMutation]
  );

  const TABS: { key: TabKey; label: string; icon: React.ElementType }[] = [
    { key: "list", label: "목록", icon: List },
    { key: "calendar", label: "달력", icon: Calendar },
    { key: "chart", label: "차트", icon: BarChart3 },
  ];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">정산 관리</h1>

      {/* Stats cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <div className="flex items-center gap-3">
            <div className="rounded-lg bg-blue-100 p-2">
              <DollarSign className="h-5 w-5 text-blue-600" />
            </div>
            <div>
              <p className="text-xs text-gray-500">총 정산액</p>
              <p className="text-xl font-bold text-gray-900">
                {formatMoney(stats?.totalAmount ?? 0)}
              </p>
            </div>
          </div>
        </div>
        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <div className="flex items-center gap-3">
            <div className="rounded-lg bg-green-100 p-2">
              <CheckCircle className="h-5 w-5 text-green-600" />
            </div>
            <div>
              <p className="text-xs text-gray-500">정산완료</p>
              <p className="text-xl font-bold text-gray-900">
                {formatMoney(stats?.paidAmount ?? 0)}
              </p>
            </div>
          </div>
        </div>
        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <div className="flex items-center gap-3">
            <div className="rounded-lg bg-red-100 p-2">
              <AlertCircle className="h-5 w-5 text-red-600" />
            </div>
            <div>
              <p className="text-xs text-gray-500">미정산</p>
              <p className="text-xl font-bold text-gray-900">
                {formatMoney(
                  (stats?.totalAmount ?? 0) - (stats?.paidAmount ?? 0)
                )}
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-gray-200">
        {TABS.map((t) => {
          const Icon = t.icon;
          return (
            <button
              key={t.key}
              type="button"
              onClick={() => setTab(t.key)}
              className={`flex items-center gap-1.5 px-4 py-2.5 text-sm font-medium transition-colors ${
                tab === t.key
                  ? "border-b-2 border-blue-600 text-blue-600"
                  : "text-gray-500 hover:text-gray-700"
              }`}
            >
              <Icon className="h-4 w-4" />
              {t.label}
            </button>
          );
        })}
      </div>

      {tab === "list" && (
        <DataTable
          columns={columns}
          data={settlements}
          isLoading={settlementsQuery.isLoading}
          isError={settlementsQuery.isError}
          searchPlaceholder="회사명 검색..."
        />
      )}

      {tab === "calendar" && (
        <div className="rounded-xl border border-gray-200 bg-white p-6">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">
            월별 정산 현황
          </h2>
          <div className="space-y-3">
            {barData.map((d) => (
              <div key={d.month} className="flex items-center gap-4">
                <span className="w-20 text-sm font-medium text-gray-600">
                  {d.month}
                </span>
                <div className="flex-1">
                  <div
                    className="h-6 rounded bg-blue-500"
                    style={{
                      width: `${
                        barData.length > 0
                          ? (d.amount /
                              Math.max(...barData.map((b) => b.amount))) *
                            100
                          : 0
                      }%`,
                    }}
                  />
                </div>
                <span className="w-28 text-right text-sm text-gray-600">
                  {formatMoney(d.amount)}
                </span>
              </div>
            ))}
            {barData.length === 0 && (
              <p className="py-8 text-center text-sm text-gray-500">
                데이터가 없습니다.
              </p>
            )}
          </div>
        </div>
      )}

      {tab === "chart" && (
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <div className="rounded-xl border border-gray-200 bg-white p-6">
            <h2 className="mb-4 text-lg font-semibold text-gray-900">
              월별 정산액
            </h2>
            <div className="h-72">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={barData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="month" fontSize={12} />
                  <YAxis fontSize={12} />
                  <Tooltip
                    formatter={(value: number) => formatMoney(value)}
                  />
                  <Bar dataKey="amount" fill="#3b82f6" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div className="rounded-xl border border-gray-200 bg-white p-6">
            <h2 className="mb-4 text-lg font-semibold text-gray-900">
              상태별 분포
            </h2>
            <div className="h-72">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={pieData}
                    cx="50%"
                    cy="50%"
                    outerRadius={100}
                    dataKey="value"
                    label={({ name, value }) => `${name}: ${value}`}
                  >
                    {pieData.map((_, idx) => (
                      <Cell
                        key={idx}
                        fill={PIE_COLORS[idx % PIE_COLORS.length]}
                      />
                    ))}
                  </Pie>
                  <Tooltip />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
