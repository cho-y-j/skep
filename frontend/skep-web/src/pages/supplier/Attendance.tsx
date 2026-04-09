import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { Clock } from "lucide-react";
import toast from "react-hot-toast";
import { rostersApi, workRecordsApi, queryKeys } from "@/api/endpoints";
import type { DailyRoster } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate } from "@/utils/formatDate";
import { FormDialog } from "@/components/common/FormDialog";

export default function Attendance() {
  const queryClient = useQueryClient();
  const [selectedDate, setSelectedDate] = useState(
    new Date().toISOString().slice(0, 10)
  );
  const [clockInTarget, setClockInTarget] = useState<DailyRoster | null>(null);

  const rostersQuery = useQuery({
    queryKey: queryKeys.dispatch.rosters({ date: selectedDate, size: 100 }),
    queryFn: () => rostersApi.getAll({ date: selectedDate, size: 100 }),
  });

  const clockInMutation = useMutation({
    mutationFn: (rosterId: string) => {
      return new Promise<GeolocationPosition>((resolve, reject) =>
        navigator.geolocation.getCurrentPosition(resolve, reject)
      ).then((pos) =>
        workRecordsApi.clockIn(rosterId, {
          latitude: pos.coords.latitude,
          longitude: pos.coords.longitude,
        })
      );
    },
    onSuccess: () => {
      toast.success("출근이 기록되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["dispatch", "rosters"] });
      setClockInTarget(null);
    },
    onError: () => {
      toast.error("출근 기록에 실패했습니다. 위치 권한을 확인하세요.");
    },
  });

  const columns = useMemo<ColumnDef<DailyRoster, unknown>[]>(
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
        id: "actions",
        header: "출근",
        enableSorting: false,
        cell: ({ row }) => (
          <button
            type="button"
            onClick={() => setClockInTarget(row.original)}
            className="flex items-center gap-1 rounded-lg bg-green-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-green-700 transition-colors"
          >
            <Clock className="h-3.5 w-3.5" />
            출근
          </button>
        ),
      },
    ],
    []
  );

  return (
    <div className="space-y-4 p-6">
      <h1 className="text-2xl font-bold text-gray-900">출근 관리</h1>

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

      <FormDialog
        open={!!clockInTarget}
        onClose={() => setClockInTarget(null)}
        title="출근 확인"
        onSave={() => {
          if (clockInTarget) clockInMutation.mutate(clockInTarget.id);
        }}
        saveLabel="출근 기록"
        isSaving={clockInMutation.isPending}
      >
        {clockInTarget && (
          <div className="space-y-2 text-sm">
            <p>
              <span className="text-gray-500">운전원:</span>{" "}
              {clockInTarget.driverName}
            </p>
            <p>
              <span className="text-gray-500">장비:</span>{" "}
              {clockInTarget.equipmentName}
            </p>
            <p>
              <span className="text-gray-500">현장:</span>{" "}
              {clockInTarget.siteName}
            </p>
            <p className="mt-3 text-xs text-gray-400">
              현재 위치 (GPS)를 기반으로 출근이 기록됩니다.
            </p>
          </div>
        )}
      </FormDialog>
    </div>
  );
}
