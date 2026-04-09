import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { FileSignature } from "lucide-react";
import toast from "react-hot-toast";
import { workRecordsApi, confirmationsApi, queryKeys } from "@/api/endpoints";
import type { WorkRecord } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate, formatDateTime } from "@/utils/formatDate";

type TabKey = "daily" | "monthly";

export default function WorkerWorkConfirmation() {
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState<TabKey>("daily");

  const workRecordsQuery = useQuery({
    queryKey: queryKeys.dispatch.workRecords({ size: 100 }),
    queryFn: () => workRecordsApi.getAll({ size: 100 }),
  });

  const confirmMutation = useMutation({
    mutationFn: (id: string) => confirmationsApi.confirm(id),
    onSuccess: () => {
      toast.success("서명 요청이 전송되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["dispatch", "workRecords"] });
    },
    onError: () => toast.error("요청에 실패했습니다."),
  });

  const dailyColumns = useMemo<ColumnDef<WorkRecord, unknown>[]>(
    () => [
      { accessorKey: "siteName", header: "현장" },
      {
        accessorKey: "date",
        header: "날짜",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        accessorKey: "clockInTime",
        header: "출근",
        cell: ({ getValue }) => formatDateTime(getValue() as string),
      },
      {
        accessorKey: "totalHours",
        header: "근무시간",
        cell: ({ getValue }) => {
          const h = getValue() as number | null;
          return h != null ? `${h.toFixed(1)}h` : "-";
        },
      },
      {
        accessorKey: "status",
        header: "상태",
        cell: ({ getValue }) => <StatusBadge status={getValue() as string} />,
      },
      {
        id: "actions",
        header: "서명",
        enableSorting: false,
        cell: ({ row }) => (
          <button
            type="button"
            onClick={() => confirmMutation.mutate(row.original.id)}
            className="flex items-center gap-1 rounded-lg bg-blue-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-blue-700 transition-colors"
          >
            <FileSignature className="h-3.5 w-3.5" />
            서명
          </button>
        ),
      },
    ],
    []
  );

  return (
    <div className="space-y-4 p-6">
      <h1 className="text-2xl font-bold text-gray-900">작업 확인서</h1>

      <div className="flex border-b border-gray-200">
        <button
          type="button"
          onClick={() => setActiveTab("daily")}
          className={`px-4 py-2 text-sm font-medium transition-colors ${
            activeTab === "daily"
              ? "border-b-2 border-blue-600 text-blue-600"
              : "text-gray-500 hover:text-gray-700"
          }`}
        >
          일일 확인
        </button>
        <button
          type="button"
          onClick={() => setActiveTab("monthly")}
          className={`px-4 py-2 text-sm font-medium transition-colors ${
            activeTab === "monthly"
              ? "border-b-2 border-blue-600 text-blue-600"
              : "text-gray-500 hover:text-gray-700"
          }`}
        >
          월별 확인
        </button>
      </div>

      {activeTab === "daily" && (
        <DataTable
          columns={dailyColumns}
          data={workRecordsQuery.data?.content ?? []}
          isLoading={workRecordsQuery.isLoading}
          isError={workRecordsQuery.isError}
          searchPlaceholder="현장 검색..."
        />
      )}

      {activeTab === "monthly" && (
        <div className="rounded-xl border border-gray-200 bg-white p-6">
          <p className="text-sm text-gray-600">
            월별 작업 확인서를 확인하고 서명할 수 있습니다.
          </p>
          <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-3">
            {["2026-01", "2026-02", "2026-03"].map((month) => (
              <div
                key={month}
                className="rounded-lg border border-gray-200 p-4"
              >
                <p className="text-sm font-medium text-gray-900">{month}</p>
                <p className="mt-1 text-xs text-gray-500">작업일수: - / 총 근무시간: -</p>
                <button
                  type="button"
                  onClick={() => toast.success("서명 요청이 전송되었습니다.")}
                  className="mt-3 flex items-center gap-1 rounded-lg bg-blue-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-blue-700 transition-colors"
                >
                  <FileSignature className="h-3.5 w-3.5" />
                  서명 요청
                </button>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
