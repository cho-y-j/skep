import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import toast from "react-hot-toast";
import { Plus } from "lucide-react";
import { equipmentApi, companiesApi, queryKeys } from "@/api/endpoints";
import type { Equipment } from "@/types";
import { CompanyType } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { FormDialog } from "@/components/common/FormDialog";

const equipmentSchema = z.object({
  name: z.string().min(1, "차량번호를 입력하세요"),
  typeId: z.string().min(1, "장비 유형을 선택하세요"),
  model: z.string().min(1, "모델명을 입력하세요"),
  companyId: z.string().min(1, "공급사를 선택하세요"),
  year: z.coerce.number().min(1900, "제조년도를 입력하세요"),
  manufacturer: z.string().optional(),
  serialNumber: z.string().optional(),
});

type EquipmentFormValues = z.infer<typeof equipmentSchema>;

export default function EquipmentStatusPage() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const queryClient = useQueryClient();

  const equipmentQuery = useQuery({
    queryKey: queryKeys.equipment.all({ size: 200 }),
    queryFn: () => equipmentApi.getAll({ size: 200 }),
  });

  const typesQuery = useQuery({
    queryKey: queryKeys.equipment.types,
    queryFn: () => equipmentApi.getTypes(),
  });

  const suppliersQuery = useQuery({
    queryKey: queryKeys.companies.byType(CompanyType.SUPPLIER),
    queryFn: () =>
      companiesApi.getByType(CompanyType.SUPPLIER, { size: 200 }),
  });

  const createMutation = useMutation({
    mutationFn: (data: EquipmentFormValues) => equipmentApi.create(data),
    onSuccess: () => {
      toast.success("장비가 추가되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["equipment"] });
      setDialogOpen(false);
      reset();
    },
    onError: () => toast.error("장비 추가에 실패했습니다."),
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<EquipmentFormValues>({
    resolver: zodResolver(equipmentSchema),
  });

  const columns = useMemo<ColumnDef<Equipment, unknown>[]>(
    () => [
      { accessorKey: "name", header: "차량번호" },
      { accessorKey: "typeName", header: "장비 유형" },
      { accessorKey: "model", header: "모델명" },
      { accessorKey: "companyName", header: "공급사" },
      {
        accessorKey: "status",
        header: "상태",
        cell: ({ getValue }) => <StatusBadge status={getValue() as string} />,
      },
    ],
    []
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">장비 현황</h1>
        <button
          type="button"
          onClick={() => {
            reset();
            setDialogOpen(true);
          }}
          className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
        >
          <Plus className="h-4 w-4" />
          장비 추가
        </button>
      </div>

      <DataTable
        columns={columns}
        data={equipmentQuery.data?.content ?? []}
        isLoading={equipmentQuery.isLoading}
        isError={equipmentQuery.isError}
        searchPlaceholder="차량번호 또는 모델 검색..."
      />

      <FormDialog
        open={dialogOpen}
        onClose={() => {
          setDialogOpen(false);
          reset();
        }}
        title="장비 추가"
        onSave={handleSubmit((data) => createMutation.mutate(data))}
        isSaving={createMutation.isPending}
      >
        <form className="space-y-4" onSubmit={(e) => e.preventDefault()}>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              공급사
            </label>
            <select
              {...register("companyId")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="">선택하세요</option>
              {(suppliersQuery.data?.content ?? []).map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
            {errors.companyId && (
              <p className="mt-1 text-xs text-red-500">
                {errors.companyId.message}
              </p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              장비 유형
            </label>
            <select
              {...register("typeId")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="">선택하세요</option>
              {(typesQuery.data ?? []).map((t) => (
                <option key={t.id} value={t.id}>
                  {t.name}
                </option>
              ))}
            </select>
            {errors.typeId && (
              <p className="mt-1 text-xs text-red-500">
                {errors.typeId.message}
              </p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              차량번호
            </label>
            <input
              {...register("name")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.name && (
              <p className="mt-1 text-xs text-red-500">{errors.name.message}</p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              모델명
            </label>
            <input
              {...register("model")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.model && (
              <p className="mt-1 text-xs text-red-500">
                {errors.model.message}
              </p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              제조년도
            </label>
            <input
              type="number"
              {...register("year")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.year && (
              <p className="mt-1 text-xs text-red-500">{errors.year.message}</p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              제조사
            </label>
            <input
              {...register("manufacturer")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>
        </form>
      </FormDialog>
    </div>
  );
}
