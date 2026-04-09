import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { type ColumnDef } from "@tanstack/react-table";
import { Plus } from "lucide-react";
import toast from "react-hot-toast";
import { maintenanceApi, equipmentApi, queryKeys } from "@/api/endpoints";
import type { MaintenanceRecord } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate, formatMoney } from "@/utils/formatDate";
import { FormDialog } from "@/components/common/FormDialog";

const formSchema = z.object({
  equipmentId: z.string().min(1, "장비를 선택하세요"),
  type: z.string().min(1, "점검 유형을 선택하세요"),
  description: z.string().min(1, "내용을 입력하세요"),
  scheduledDate: z.string().min(1, "날짜를 입력하세요"),
  cost: z.coerce.number().optional(),
});

type FormData = z.infer<typeof formSchema>;

export default function WorkerMaintenanceCheck() {
  const queryClient = useQueryClient();
  const [dialogOpen, setDialogOpen] = useState(false);

  const equipmentQuery = useQuery({
    queryKey: queryKeys.equipment.all({ size: 200 }),
    queryFn: () => equipmentApi.getAll({ size: 200 }),
  });

  const maintenanceQuery = useQuery({
    queryKey: queryKeys.inspection.maintenance({ size: 100 }),
    queryFn: () => maintenanceApi.getAll({ size: 100 }),
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(formSchema),
  });

  const createMutation = useMutation({
    mutationFn: (data: FormData) => maintenanceApi.create(data),
    onSuccess: () => {
      toast.success("정비 기록이 등록되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["inspection", "maintenance"] });
      setDialogOpen(false);
      reset();
    },
    onError: () => toast.error("등록에 실패했습니다."),
  });

  const columns = useMemo<ColumnDef<MaintenanceRecord, unknown>[]>(
    () => [
      { accessorKey: "equipmentName", header: "장비" },
      { accessorKey: "type", header: "유형" },
      {
        accessorKey: "description",
        header: "내용",
        cell: ({ getValue }) => (
          <span className="max-w-xs truncate block">
            {getValue() as string}
          </span>
        ),
      },
      {
        accessorKey: "scheduledDate",
        header: "예정일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        accessorKey: "completedDate",
        header: "완료일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        accessorKey: "cost",
        header: "비용",
        cell: ({ getValue }) => formatMoney(getValue() as number | null),
      },
      {
        accessorKey: "status",
        header: "상태",
        cell: ({ getValue }) => <StatusBadge status={getValue() as string} />,
      },
    ],
    []
  );

  return (
    <div className="space-y-4 p-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">정비 점검</h1>
        <button
          type="button"
          onClick={() => setDialogOpen(true)}
          className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
        >
          <Plus className="h-4 w-4" />
          기록 추가
        </button>
      </div>

      <DataTable
        columns={columns}
        data={maintenanceQuery.data?.content ?? []}
        isLoading={maintenanceQuery.isLoading}
        isError={maintenanceQuery.isError}
        searchPlaceholder="장비, 유형 검색..."
      />

      <FormDialog
        open={dialogOpen}
        onClose={() => {
          setDialogOpen(false);
          reset();
        }}
        title="정비 기록 추가"
        hideFooter
      >
        <form
          onSubmit={handleSubmit((d) => createMutation.mutate(d))}
          className="space-y-4"
        >
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
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              점검 유형
            </label>
            <select
              {...register("type")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="">선택</option>
              <option value="주행거리 점검">주행거리 점검</option>
              <option value="엔진오일 교환">엔진오일 교환</option>
              <option value="연료 점검">연료 점검</option>
              <option value="타이어 점검">타이어 점검</option>
              <option value="브레이크 점검">브레이크 점검</option>
              <option value="기타">기타</option>
            </select>
            {errors.type && (
              <p className="mt-1 text-xs text-red-500">{errors.type.message}</p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              내용
            </label>
            <textarea
              {...register("description")}
              rows={3}
              placeholder="주행거리, 오일 상태, 연료량 등"
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.description && (
              <p className="mt-1 text-xs text-red-500">
                {errors.description.message}
              </p>
            )}
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                날짜
              </label>
              <input
                type="date"
                {...register("scheduledDate")}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              />
              {errors.scheduledDate && (
                <p className="mt-1 text-xs text-red-500">
                  {errors.scheduledDate.message}
                </p>
              )}
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                비용 (원)
              </label>
              <input
                type="number"
                {...register("cost")}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              />
            </div>
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
              {createMutation.isPending ? "등록 중..." : "등록"}
            </button>
          </div>
        </form>
      </FormDialog>
    </div>
  );
}
