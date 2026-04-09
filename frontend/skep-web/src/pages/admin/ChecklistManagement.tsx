import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import toast from "react-hot-toast";
import { ShieldCheck, RotateCcw } from "lucide-react";
import {
  plansApi,
  checklistsApi,
  equipmentApi,
  queryKeys,
} from "@/api/endpoints";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate } from "@/utils/formatDate";

const DEFAULT_ITEMS = [
  "운전면허 확인",
  "장비 외관 점검",
  "안전벨트 확인",
  "브레이크 작동 확인",
  "경고등 점검",
  "유압장치 점검",
  "안전장구 착용 확인",
];

export default function ChecklistManagement() {
  const [selectedPlanId, setSelectedPlanId] = useState("");
  const [overrideReason, setOverrideReason] = useState("");
  const queryClient = useQueryClient();

  const plansQuery = useQuery({
    queryKey: queryKeys.dispatch.plans({ size: 200 }),
    queryFn: () => plansApi.getAll({ size: 200 }),
  });

  const checklistsQuery = useQuery({
    queryKey: queryKeys.dispatch.checklists(
      selectedPlanId ? { planId: selectedPlanId } : { size: 50 }
    ),
    queryFn: () =>
      checklistsApi.getAll(
        selectedPlanId ? { planId: selectedPlanId, size: 50 } : { size: 50 }
      ),
  });

  const overrideMutation = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) =>
      checklistsApi.override(id, reason),
    onSuccess: () => {
      toast.success("체크리스트가 관리자 승인 처리되었습니다.");
      queryClient.invalidateQueries({
        queryKey: ["dispatch", "checklists"],
      });
      setOverrideReason("");
    },
    onError: () => toast.error("처리에 실패했습니다."),
  });

  const updateMutation = useMutation({
    mutationFn: ({
      id,
      items,
    }: {
      id: string;
      items: Array<{ itemId: string; checked: boolean; note?: string }>;
    }) => checklistsApi.update(id, items),
    onSuccess: () => {
      toast.success("체크리스트가 저장되었습니다.");
      queryClient.invalidateQueries({
        queryKey: ["dispatch", "checklists"],
      });
    },
    onError: () => toast.error("저장에 실패했습니다."),
  });

  const checklists = checklistsQuery.data?.content ?? [];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">체크리스트 관리</h1>

      {/* Plan selector */}
      <div>
        <label className="mb-1 block text-sm font-medium text-gray-700">
          배치 계획 선택
        </label>
        <select
          value={selectedPlanId}
          onChange={(e) => setSelectedPlanId(e.target.value)}
          className="w-full max-w-md rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
        >
          <option value="">전체 체크리스트</option>
          {(plansQuery.data?.content ?? []).map((p) => (
            <option key={p.id} value={p.id}>
              {p.siteName} - {p.equipmentName} ({formatDate(p.startDate)})
            </option>
          ))}
        </select>
      </div>

      {/* Default checklist items */}
      <div className="rounded-xl border border-gray-200 bg-white p-5">
        <h2 className="mb-3 text-sm font-semibold text-gray-700">
          기본 체크항목 (7개)
        </h2>
        <ul className="space-y-2">
          {DEFAULT_ITEMS.map((item, idx) => (
            <li key={idx} className="flex items-center gap-3 text-sm">
              <input
                type="checkbox"
                checked
                readOnly
                className="h-4 w-4 rounded border-gray-300 text-blue-600"
              />
              <span className="text-gray-700">{item}</span>
            </li>
          ))}
        </ul>
      </div>

      {/* Checklists */}
      {checklistsQuery.isLoading && (
        <p className="text-sm text-gray-500">불러오는 중...</p>
      )}

      {checklists.length === 0 && !checklistsQuery.isLoading && (
        <p className="text-sm text-gray-500">해당하는 체크리스트가 없습니다.</p>
      )}

      <div className="space-y-4">
        {checklists.map((cl) => (
          <div
            key={cl.id}
            className="rounded-xl border border-gray-200 bg-white p-5"
          >
            <div className="mb-3 flex items-center justify-between">
              <div>
                <p className="font-medium text-gray-900">
                  {cl.driverName} / {cl.equipmentName}
                </p>
                <p className="text-xs text-gray-500">{formatDate(cl.date)}</p>
              </div>
              <StatusBadge status={cl.status} />
            </div>

            {/* Items */}
            <ul className="mb-4 space-y-2">
              {cl.items.map((item) => (
                <li key={item.id} className="flex items-center gap-3 text-sm">
                  <input
                    type="checkbox"
                    checked={item.checked}
                    onChange={() => {
                      const updatedItems = cl.items.map((it) =>
                        it.id === item.id
                          ? { itemId: it.id, checked: !it.checked, note: it.note ?? undefined }
                          : { itemId: it.id, checked: it.checked, note: it.note ?? undefined }
                      );
                      updateMutation.mutate({ id: cl.id, items: updatedItems });
                    }}
                    className="h-4 w-4 rounded border-gray-300 text-blue-600"
                  />
                  <span
                    className={
                      item.checked ? "text-gray-700" : "text-gray-400"
                    }
                  >
                    {item.item}
                  </span>
                  {item.note && (
                    <span className="text-xs text-gray-400">
                      ({item.note})
                    </span>
                  )}
                </li>
              ))}
            </ul>

            {/* Override */}
            {cl.status === "PENDING" && (
              <div className="flex items-end gap-3 border-t border-gray-100 pt-3">
                <div className="flex-1">
                  <label className="mb-1 block text-xs text-gray-500">
                    관리자 승인 사유
                  </label>
                  <input
                    type="text"
                    value={overrideReason}
                    onChange={(e) => setOverrideReason(e.target.value)}
                    placeholder="사유를 입력하세요"
                    className="w-full rounded border border-gray-300 px-3 py-1.5 text-sm focus:border-blue-500 focus:outline-none"
                  />
                </div>
                <button
                  type="button"
                  onClick={() =>
                    overrideMutation.mutate({
                      id: cl.id,
                      reason: overrideReason,
                    })
                  }
                  disabled={!overrideReason}
                  className="flex items-center gap-1 rounded-lg bg-purple-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-purple-700 disabled:opacity-50 transition-colors"
                >
                  <RotateCcw className="h-3.5 w-3.5" />
                  관리자 승인
                </button>
              </div>
            )}

            {cl.overrideReason && (
              <div className="mt-3 flex items-center gap-2 rounded-lg bg-purple-50 px-3 py-2 text-xs text-purple-700">
                <ShieldCheck className="h-3.5 w-3.5" />
                관리자 승인: {cl.overrideReason}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
