import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { Check, X, CheckCheck } from "lucide-react";
import toast from "react-hot-toast";
import { rostersApi, queryKeys } from "@/api/endpoints";
import type { DailyRoster as DailyRosterType } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate } from "@/utils/formatDate";

export default function DailyRoster() {
  const queryClient = useQueryClient();
  const [selectedDate, setSelectedDate] = useState(
    new Date().toISOString().slice(0, 10)
  );

  const rostersQuery = useQuery({
    queryKey: queryKeys.dispatch.rosters({ date: selectedDate, size: 100 }),
    queryFn: () => rostersApi.getAll({ date: selectedDate, size: 100 }),
  });

  const approveMutation = useMutation({
    mutationFn: (id: string) => rostersApi.approve(id),
    onSuccess: () => {
      toast.success("승인되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["dispatch", "rosters"] });
    },
    onError: () => toast.error("승인에 실패했습니다."),
  });

  const rejectMutation = useMutation({
    mutationFn: (id: string) => rostersApi.reject(id, "BP 반려"),
    onSuccess: () => {
      toast.success("반려되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["dispatch", "rosters"] });
    },
    onError: () => toast.error("반려에 실패했습니다."),
  });

  const approveAllMutation = useMutation({
    mutationFn: async () => {
      const pending = (rostersQuery.data?.content ?? []).filter(
        (r) => r.status === "PENDING"
      );
      await Promise.all(pending.map((r) => rostersApi.approve(r.id)));
    },
    onSuccess: () => {
      toast.success("전체 승인되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["dispatch", "rosters"] });
    },
    onError: () => toast.error("전체 승인에 실패했습니다."),
  });

  const pendingCount = (rostersQuery.data?.content ?? []).filter(
    (r) => r.status === "PENDING"
  ).length;

  const columns = useMemo<ColumnDef<DailyRosterType, unknown>[]>(
    () => [
      { accessorKey: "driverName", header: "운전원" },
      { accessorKey: "equipmentName", header: "장비" },
      { accessorKey: "siteName", header: "현장" },
      {
        accessorKey: "date",
        header: "날짜",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        accessorKey: "status",
        header: "상태",
        cell: ({ getValue }) => <StatusBadge status={getValue() as string} />,
      },
      {
        accessorKey: "approvedAt",
        header: "승인일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        id: "actions",
        header: "작업",
        enableSorting: false,
        cell: ({ row }) => (
          <div className="flex items-center gap-1">
            <button
              type="button"
              onClick={() => approveMutation.mutate(row.original.id)}
              className="rounded p-1.5 text-green-600 hover:bg-green-50 transition-colors"
              title="승인"
            >
              <Check className="h-4 w-4" />
            </button>
            <button
              type="button"
              onClick={() => rejectMutation.mutate(row.original.id)}
              className="rounded p-1.5 text-red-500 hover:bg-red-50 transition-colors"
              title="반려"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        ),
      },
    ],
    []
  );

  return (
    <div className="space-y-4 p-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">일일 배치표</h1>
        {pendingCount > 0 && (
          <button
            type="button"
            onClick={() => approveAllMutation.mutate()}
            disabled={approveAllMutation.isPending}
            className="flex items-center gap-2 rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700 transition-colors disabled:opacity-50"
          >
            <CheckCheck className="h-4 w-4" />
            전체 승인 ({pendingCount}건)
          </button>
        )}
      </div>

      <div className="flex items-center gap-4">
        <input
          type="date"
          value={selectedDate}
          onChange={(e) => setSelectedDate(e.target.value)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
        />
      </div>

      <DataTable
        columns={columns}
        data={rostersQuery.data?.content ?? []}
        isLoading={rostersQuery.isLoading}
        isError={rostersQuery.isError}
        searchPlaceholder="운전원, 장비, 현장 검색..."
      />
    </div>
  );
}
