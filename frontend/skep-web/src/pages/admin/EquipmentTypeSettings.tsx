import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import toast from "react-hot-toast";
import { Plus, Pencil, Trash2, GripVertical, Wrench } from "lucide-react";
import { equipmentApi, queryKeys } from "@/api/endpoints";
import type { EquipmentType } from "@/types";
import { FormDialog } from "@/components/common/FormDialog";

const typeSchema = z.object({
  name: z.string().min(1, "유형명을 입력하세요"),
  category: z.string().min(1, "카테고리를 입력하세요"),
  description: z.string().optional(),
});

type TypeFormValues = z.infer<typeof typeSchema>;

export default function EquipmentTypeSettings() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const queryClient = useQueryClient();

  const typesQuery = useQuery({
    queryKey: queryKeys.equipment.types,
    queryFn: () => equipmentApi.getTypes(),
  });

  const createMutation = useMutation({
    mutationFn: (data: TypeFormValues) => equipmentApi.createType(data),
    onSuccess: () => {
      toast.success("장비 유형이 추가되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["equipment", "types"] });
      setDialogOpen(false);
      reset();
    },
    onError: () => toast.error("장비 유형 추가에 실패했습니다."),
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<TypeFormValues>({ resolver: zodResolver(typeSchema) });

  const types = typesQuery.data ?? [];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">장비 유형 설정</h1>
        <button
          type="button"
          onClick={() => {
            reset({ name: "", category: "", description: "" });
            setDialogOpen(true);
          }}
          className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
        >
          <Plus className="h-4 w-4" />
          유형 추가
        </button>
      </div>

      {typesQuery.isLoading && (
        <p className="text-sm text-gray-500">불러오는 중...</p>
      )}

      <div className="rounded-xl border border-gray-200 bg-white">
        <ul className="divide-y divide-gray-100">
          {types.map((et) => (
            <li
              key={et.id}
              className="flex items-center gap-4 px-5 py-4 hover:bg-gray-50 transition-colors"
            >
              <GripVertical className="h-4 w-4 cursor-grab text-gray-300" />
              <div className="rounded-lg bg-orange-100 p-2">
                <Wrench className="h-4 w-4 text-orange-600" />
              </div>
              <div className="flex-1">
                <p className="font-medium text-gray-900">{et.name}</p>
                <p className="text-xs text-gray-500">
                  {et.category}
                  {et.description ? ` - ${et.description}` : ""}
                </p>
              </div>
              <div className="flex gap-1">
                <button
                  type="button"
                  className="rounded p-1.5 text-gray-400 hover:bg-gray-100 hover:text-gray-600"
                >
                  <Pencil className="h-4 w-4" />
                </button>
                <button
                  type="button"
                  className="rounded p-1.5 text-gray-400 hover:bg-red-50 hover:text-red-600"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            </li>
          ))}
          {types.length === 0 && !typesQuery.isLoading && (
            <li className="py-10 text-center text-sm text-gray-500">
              등록된 장비 유형이 없습니다.
            </li>
          )}
        </ul>
      </div>

      <FormDialog
        open={dialogOpen}
        onClose={() => {
          setDialogOpen(false);
          reset();
        }}
        title="장비 유형 추가"
        onSave={handleSubmit((data) => createMutation.mutate(data))}
        isSaving={createMutation.isPending}
      >
        <form className="space-y-4" onSubmit={(e) => e.preventDefault()}>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              유형명
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
              카테고리
            </label>
            <input
              {...register("category")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.category && (
              <p className="mt-1 text-xs text-red-500">
                {errors.category.message}
              </p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              설명
            </label>
            <textarea
              {...register("description")}
              rows={3}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>
        </form>
      </FormDialog>
    </div>
  );
}
