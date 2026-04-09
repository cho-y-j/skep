import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { type ColumnDef } from "@tanstack/react-table";
import { Check, X, Plus } from "lucide-react";
import toast from "react-hot-toast";
import { plansApi, sitesApi, equipmentApi, queryKeys } from "@/api/endpoints";
import type { DeploymentPlan } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate } from "@/utils/formatDate";
import { FormDialog } from "@/components/common/FormDialog";

const requestSchema = z.object({
  siteId: z.string().min(1, "현장을 선택하세요"),
  equipmentId: z.string().min(1, "장비를 선택하세요"),
  driverId: z.string().optional(),
  startDate: z.string().min(1, "시작일을 입력하세요"),
  endDate: z.string().min(1, "종료일을 입력하세요"),
  notes: z.string().optional(),
});

type RequestFormData = z.infer<typeof requestSchema>;

export default function BpDeploymentPlan() {
  const queryClient = useQueryClient();
  const [dialogOpen, setDialogOpen] = useState(false);

  const plansQuery = useQuery({
    queryKey: queryKeys.dispatch.plans({ size: 100 }),
    queryFn: () => plansApi.getAll({ size: 100 }),
  });

  const sitesQuery = useQuery({
    queryKey: queryKeys.dispatch.sites({ size: 200 }),
    queryFn: () => sitesApi.getAll({ size: 200 }),
  });

  const equipmentQuery = useQuery({
    queryKey: queryKeys.equipment.all({ size: 200 }),
    queryFn: () => equipmentApi.getAll({ size: 200 }),
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<RequestFormData>({
    resolver: zodResolver(requestSchema),
  });

  const createMutation = useMutation({
    mutationFn: (data: RequestFormData) => plansApi.create(data),
    onSuccess: () => {
      toast.success("배치 계획이 등록되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["dispatch", "plans"] });
      setDialogOpen(false);
      reset();
    },
    onError: () => {
      toast.error("등록에 실패했습니다.");
    },
  });

  const approveMutation = useMutation({
    mutationFn: (id: string) =>
      plansApi.update(id, { status: "APPROVED" }),
    onSuccess: () => {
      toast.success("승인되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["dispatch", "plans"] });
    },
    onError: () => toast.error("승인에 실패했습니다."),
  });

  const rejectMutation = useMutation({
    mutationFn: (id: string) =>
      plansApi.update(id, { status: "REJECTED" }),
    onSuccess: () => {
      toast.success("반려되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["dispatch", "plans"] });
    },
    onError: () => toast.error("반려에 실패했습니다."),
  });

  const columns = useMemo<ColumnDef<DeploymentPlan, unknown>[]>(
    () => [
      { accessorKey: "siteName", header: "현장" },
      { accessorKey: "equipmentName", header: "장비" },
      { accessorKey: "driverName", header: "운전원" },
      {
        accessorKey: "startDate",
        header: "시작일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        accessorKey: "endDate",
        header: "종료일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        accessorKey: "status",
        header: "상태",
        cell: ({ getValue }) => <StatusBadge status={getValue() as string} />,
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
        <h1 className="text-2xl font-bold text-gray-900">배치 계획</h1>
        <button
          type="button"
          onClick={() => setDialogOpen(true)}
          className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
        >
          <Plus className="h-4 w-4" />
          장비 요청
        </button>
      </div>

      <DataTable
        columns={columns}
        data={plansQuery.data?.content ?? []}
        isLoading={plansQuery.isLoading}
        isError={plansQuery.isError}
        searchPlaceholder="현장, 장비, 운전원 검색..."
      />

      <FormDialog
        open={dialogOpen}
        onClose={() => {
          setDialogOpen(false);
          reset();
        }}
        title="장비 배치 요청"
        hideFooter
      >
        <form
          onSubmit={handleSubmit((d) => createMutation.mutate(d))}
          className="space-y-4"
        >
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              현장
            </label>
            <select
              {...register("siteId")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="">선택</option>
              {(sitesQuery.data?.content ?? []).map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name}
                </option>
              ))}
            </select>
            {errors.siteId && (
              <p className="mt-1 text-xs text-red-500">
                {errors.siteId.message}
              </p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              장비
            </label>
            <select
              {...register("equipmentId")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="">선택</option>
              {(equipmentQuery.data?.content ?? []).map((eq) => (
                <option key={eq.id} value={eq.id}>
                  {eq.name} ({eq.model})
                </option>
              ))}
            </select>
            {errors.equipmentId && (
              <p className="mt-1 text-xs text-red-500">
                {errors.equipmentId.message}
              </p>
            )}
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                시작일
              </label>
              <input
                type="date"
                {...register("startDate")}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              />
              {errors.startDate && (
                <p className="mt-1 text-xs text-red-500">
                  {errors.startDate.message}
                </p>
              )}
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                종료일
              </label>
              <input
                type="date"
                {...register("endDate")}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              />
              {errors.endDate && (
                <p className="mt-1 text-xs text-red-500">
                  {errors.endDate.message}
                </p>
              )}
            </div>
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              비고
            </label>
            <textarea
              {...register("notes")}
              rows={3}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>
          <div className="flex justify-end gap-3">
            <button
              type="button"
              onClick={() => {
                setDialogOpen(false);
                reset();
              }}
              className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
            >
              취소
            </button>
            <button
              type="submit"
              disabled={createMutation.isPending}
              className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors disabled:opacity-50"
            >
              {createMutation.isPending ? "요청 중..." : "요청"}
            </button>
          </div>
        </form>
      </FormDialog>
    </div>
  );
}
