import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Clock, MapPin, Loader2 } from "lucide-react";
import toast from "react-hot-toast";
import { rostersApi, workRecordsApi, queryKeys } from "@/api/endpoints";
import { formatDate, formatDateTime } from "@/utils/formatDate";
import { StatusBadge } from "@/components/common/StatusBadge";

export default function WorkerAttendance() {
  const queryClient = useQueryClient();
  const today = new Date().toISOString().slice(0, 10);

  const rostersQuery = useQuery({
    queryKey: queryKeys.dispatch.rosters({ date: today, size: 10 }),
    queryFn: () => rostersApi.getAll({ date: today, size: 10 }),
  });

  const workRecordsQuery = useQuery({
    queryKey: queryKeys.dispatch.workRecords({ date: today, size: 10 }),
    queryFn: () => workRecordsApi.getAll({ date: today, size: 10 }),
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
      queryClient.invalidateQueries({ queryKey: ["dispatch"] });
    },
    onError: () => {
      toast.error("출근 기록에 실패했습니다. 위치 권한을 확인하세요.");
    },
  });

  const roster = (rostersQuery.data?.content ?? [])[0];
  const records = workRecordsQuery.data?.content ?? [];

  return (
    <div className="mx-auto max-w-md space-y-6 p-6">
      <h1 className="text-2xl font-bold text-gray-900">출근 기록</h1>
      <p className="text-sm text-gray-500">{formatDate(today, "yyyy년 MM월 dd일 (EEEE)")}</p>

      {/* Clock-in button */}
      <div className="rounded-xl border border-gray-200 bg-white p-6 text-center">
        {roster ? (
          <>
            <p className="mb-2 text-sm text-gray-500">
              {roster.siteName} - {roster.equipmentName}
            </p>
            <button
              type="button"
              onClick={() => clockInMutation.mutate(roster.id)}
              disabled={clockInMutation.isPending}
              className="mx-auto flex h-32 w-32 items-center justify-center rounded-full bg-green-600 text-white shadow-lg transition-transform hover:scale-105 active:scale-95 disabled:opacity-50"
            >
              {clockInMutation.isPending ? (
                <Loader2 className="h-10 w-10 animate-spin" />
              ) : (
                <div className="text-center">
                  <Clock className="mx-auto h-10 w-10" />
                  <span className="mt-1 block text-sm font-medium">출근</span>
                </div>
              )}
            </button>
            <p className="mt-3 flex items-center justify-center gap-1 text-xs text-gray-400">
              <MapPin className="h-3 w-3" />
              GPS 기반 위치가 기록됩니다.
            </p>
          </>
        ) : (
          <p className="text-sm text-gray-500">
            {rostersQuery.isLoading
              ? "배치 정보를 불러오는 중..."
              : "오늘 배치가 없습니다."}
          </p>
        )}
      </div>

      {/* Today's records */}
      <div className="rounded-xl border border-gray-200 bg-white p-6">
        <h2 className="mb-4 text-lg font-semibold text-gray-900">
          오늘 기록
        </h2>
        {records.length === 0 ? (
          <p className="text-center text-sm text-gray-500">기록이 없습니다.</p>
        ) : (
          <ul className="divide-y divide-gray-100">
            {records.map((record) => (
              <li key={record.id} className="py-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium text-gray-900">
                    {record.siteName}
                  </span>
                  <StatusBadge status={record.status} />
                </div>
                <div className="mt-1 flex gap-4 text-xs text-gray-500">
                  <span>
                    출근: {formatDateTime(record.clockInTime)}
                  </span>
                  <span>
                    작업시작: {formatDateTime(record.workStartTime)}
                  </span>
                  <span>
                    작업종료: {formatDateTime(record.workEndTime)}
                  </span>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
