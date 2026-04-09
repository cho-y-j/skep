import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { ShieldCheck } from "lucide-react";
import toast from "react-hot-toast";
import { checklistsApi, queryKeys } from "@/api/endpoints";
import type { DeploymentChecklist } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate } from "@/utils/formatDate";
import { FormDialog } from "@/components/common/FormDialog";

export default function Checklist() {
  const queryClient = useQueryClient();
  const [selectedChecklist, setSelectedChecklist] =
    useState<DeploymentChecklist | null>(null);
  const [overrideReason, setOverrideReason] = useState("");

  const { data, isLoading, isError } = useQuery({
    queryKey: queryKeys.dispatch.checklists({ size: 100 }),
    queryFn: () => checklistsApi.getAll({ size: 100 }),
  });

  const overrideMutation = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) =>
      checklistsApi.override(id, reason),
    onSuccess: () => {
      toast.success("관리자 승인이 완료되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["dispatch", "checklists"] });
      setSelectedChecklist(null);
      setOverrideReason("");
    },
    onError: () => toast.error("승인에 실패했습니다."),
  });

  const columns = useMemo<ColumnDef<DeploymentChecklist, unknown>[]>(
    () => [
      { accessorKey: "driverName", header: "운전원" },
      { accessorKey: "equipmentName", header: "장비" },
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
        accessorKey: "completedAt",
        header: "완료일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        id: "items",
        header: "항목",
        cell: ({ row }) => {
          const items = row.original.items ?? [];
          const checked = items.filter((i) => i.checked).length;
          return (
            <span className="text-sm text-gray-600">
              {checked}/{items.length}
            </span>
          );
        },
      },
      {
        id: "actions",
        header: "작업",
        enableSorting: false,
        cell: ({ row }) => (
          <button
            type="button"
            onClick={() => setSelectedChecklist(row.original)}
            className="flex items-center gap-1 rounded-lg bg-purple-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-purple-700 transition-colors"
          >
            <ShieldCheck className="h-3.5 w-3.5" />
            상세/승인
          </button>
        ),
      },
    ],
    []
  );

  return (
    <div className="space-y-4 p-6">
      <h1 className="text-2xl font-bold text-gray-900">체크리스트</h1>

      <DataTable
        columns={columns}
        data={data?.content ?? []}
        isLoading={isLoading}
        isError={isError}
        searchPlaceholder="운전원, 장비 검색..."
      />

      <FormDialog
        open={!!selectedChecklist}
        onClose={() => {
          setSelectedChecklist(null);
          setOverrideReason("");
        }}
        title="체크리스트 상세"
        hideFooter
        className="max-w-2xl"
      >
        {selectedChecklist && (
          <div className="space-y-4">
            <div className="rounded-lg bg-gray-50 p-3 text-sm">
              <p>
                <span className="text-gray-500">운전원:</span>{" "}
                {selectedChecklist.driverName}
              </p>
              <p>
                <span className="text-gray-500">장비:</span>{" "}
                {selectedChecklist.equipmentName}
              </p>
              <p>
                <span className="text-gray-500">상태:</span>{" "}
                <StatusBadge status={selectedChecklist.status} />
              </p>
            </div>

            <div className="divide-y divide-gray-100 rounded-lg border border-gray-200">
              {(selectedChecklist.items ?? []).map((item) => (
                <div
                  key={item.id}
                  className="flex items-center justify-between px-4 py-3"
                >
                  <div>
                    <p className="text-sm font-medium text-gray-900">
                      {item.item}
                    </p>
                    <p className="text-xs text-gray-500">{item.category}</p>
                  </div>
                  <span
                    className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                      item.checked
                        ? "bg-green-100 text-green-800"
                        : "bg-red-100 text-red-800"
                    }`}
                  >
                    {item.checked ? "통과" : "미통과"}
                  </span>
                </div>
              ))}
            </div>

            {selectedChecklist.status !== "APPROVED" &&
              selectedChecklist.status !== "OVERRIDE" && (
                <div className="space-y-3">
                  <label className="block text-sm font-medium text-gray-700">
                    관리자 승인 사유
                  </label>
                  <textarea
                    value={overrideReason}
                    onChange={(e) => setOverrideReason(e.target.value)}
                    rows={3}
                    placeholder="승인 사유를 입력하세요"
                    className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                  />
                  <div className="flex justify-end">
                    <button
                      type="button"
                      onClick={() =>
                        overrideMutation.mutate({
                          id: selectedChecklist.id,
                          reason: overrideReason,
                        })
                      }
                      disabled={
                        !overrideReason || overrideMutation.isPending
                      }
                      className="rounded-lg bg-purple-600 px-4 py-2 text-sm font-medium text-white hover:bg-purple-700 transition-colors disabled:opacity-50"
                    >
                      {overrideMutation.isPending
                        ? "처리 중..."
                        : "관리자 승인"}
                    </button>
                  </div>
                </div>
              )}
          </div>
        )}
      </FormDialog>
    </div>
  );
}
