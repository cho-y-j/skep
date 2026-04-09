import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Shield, Check, X, Loader2 } from "lucide-react";
import toast from "react-hot-toast";
import { safetyApi, equipmentApi, queryKeys } from "@/api/endpoints";
import type { SafetyInspection as SafetyInspectionType, SafetyInspectionItem } from "@/types";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate } from "@/utils/formatDate";

export default function WorkerSafetyInspection() {
  const queryClient = useQueryClient();
  const [selectedId, setSelectedId] = useState("");

  const inspectionsQuery = useQuery({
    queryKey: queryKeys.inspection.safety({ size: 100 }),
    queryFn: () => safetyApi.getAll({ size: 100 }),
  });

  const detailQuery = useQuery({
    queryKey: queryKeys.inspection.safetyById(selectedId),
    queryFn: () => safetyApi.getById(selectedId),
    enabled: !!selectedId,
  });

  const recordItemMutation = useMutation({
    mutationFn: ({
      inspectionId,
      itemId,
      passed,
    }: {
      inspectionId: string;
      itemId: string;
      passed: boolean;
    }) => safetyApi.recordItem(inspectionId, itemId, { passed }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["inspection", "safety"] });
    },
    onError: () => toast.error("기록에 실패했습니다."),
  });

  const completeMutation = useMutation({
    mutationFn: (id: string) => safetyApi.complete(id),
    onSuccess: () => {
      toast.success("점검이 완료되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["inspection", "safety"] });
      setSelectedId("");
    },
    onError: () => toast.error("완료 처리에 실패했습니다."),
  });

  const failMutation = useMutation({
    mutationFn: (id: string) => safetyApi.fail(id, "점검 불합격"),
    onSuccess: () => {
      toast.success("불합격 처리되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["inspection", "safety"] });
      setSelectedId("");
    },
    onError: () => toast.error("처리에 실패했습니다."),
  });

  const inspection = detailQuery.data;
  const items = inspection?.items ?? [];

  return (
    <div className="space-y-6 p-6">
      <h1 className="text-2xl font-bold text-gray-900">안전 점검</h1>

      {/* Inspection selector */}
      <div className="flex items-center gap-4">
        <select
          value={selectedId}
          onChange={(e) => setSelectedId(e.target.value)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
        >
          <option value="">점검 선택</option>
          {(inspectionsQuery.data?.content ?? []).map(
            (insp: SafetyInspectionType) => (
              <option key={insp.id} value={insp.id}>
                {insp.siteName} - {formatDate(insp.scheduledDate)}
              </option>
            )
          )}
        </select>
      </div>

      {/* Checklist items */}
      {selectedId && detailQuery.isLoading && (
        <div className="flex items-center justify-center py-12 text-gray-500">
          <Loader2 className="mr-2 h-5 w-5 animate-spin" />
          불러오는 중...
        </div>
      )}

      {inspection && (
        <div className="space-y-4">
          <div className="rounded-lg bg-gray-50 p-4 text-sm">
            <div className="flex items-center justify-between">
              <div>
                <p>
                  <span className="text-gray-500">현장:</span>{" "}
                  {inspection.siteName}
                </p>
                <p>
                  <span className="text-gray-500">예정일:</span>{" "}
                  {formatDate(inspection.scheduledDate)}
                </p>
              </div>
              <StatusBadge status={inspection.status} />
            </div>
          </div>

          <div className="divide-y divide-gray-100 rounded-xl border border-gray-200 bg-white">
            {items.map((item: SafetyInspectionItem) => (
              <div
                key={item.id}
                className="flex items-center justify-between px-4 py-3"
              >
                <div>
                  <p className="text-sm font-medium text-gray-900">
                    {item.item}
                  </p>
                  <p className="text-xs text-gray-500">
                    {item.category} / 심각도: {item.severity}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  {item.passed === null ? (
                    <>
                      <button
                        type="button"
                        onClick={() =>
                          recordItemMutation.mutate({
                            inspectionId: inspection.id,
                            itemId: item.id,
                            passed: true,
                          })
                        }
                        className="flex items-center gap-1 rounded-lg bg-green-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-green-700 transition-colors"
                      >
                        <Check className="h-3.5 w-3.5" />
                        OK
                      </button>
                      <button
                        type="button"
                        onClick={() =>
                          recordItemMutation.mutate({
                            inspectionId: inspection.id,
                            itemId: item.id,
                            passed: false,
                          })
                        }
                        className="flex items-center gap-1 rounded-lg bg-red-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-red-700 transition-colors"
                      >
                        <X className="h-3.5 w-3.5" />
                        NG
                      </button>
                    </>
                  ) : (
                    <span
                      className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                        item.passed
                          ? "bg-green-100 text-green-800"
                          : "bg-red-100 text-red-800"
                      }`}
                    >
                      {item.passed ? "OK" : "NG"}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>

          {inspection.status === "IN_PROGRESS" && (
            <div className="flex justify-end gap-3">
              <button
                type="button"
                onClick={() => failMutation.mutate(inspection.id)}
                disabled={failMutation.isPending}
                className="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 transition-colors disabled:opacity-50"
              >
                불합격
              </button>
              <button
                type="button"
                onClick={() => completeMutation.mutate(inspection.id)}
                disabled={completeMutation.isPending}
                className="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700 transition-colors disabled:opacity-50"
              >
                점검 완료
              </button>
            </div>
          )}
        </div>
      )}

      {!selectedId && (
        <div className="flex flex-col items-center justify-center rounded-xl border border-gray-200 bg-white py-16 text-gray-400">
          <Shield className="mb-2 h-12 w-12" />
          <p className="text-sm">점검을 선택하세요.</p>
        </div>
      )}
    </div>
  );
}
