import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import toast from "react-hot-toast";
import { Plus, Pencil, Trash2, FileText } from "lucide-react";
import { documentsApi, queryKeys } from "@/api/endpoints";
import type { DocumentType } from "@/types";
import { FormDialog } from "@/components/common/FormDialog";

const docTypeSchema = z.object({
  name: z.string().min(1, "유형명을 입력하세요"),
  category: z.string().min(1, "카테고리를 입력하세요"),
  requiredForEquipment: z.boolean(),
  requiredForPerson: z.boolean(),
  validityDays: z.coerce.number().nullable(),
});

type DocTypeFormValues = z.infer<typeof docTypeSchema>;

export default function DocumentTypeManagement() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editItem, setEditItem] = useState<DocumentType | null>(null);
  const queryClient = useQueryClient();

  const typesQuery = useQuery({
    queryKey: queryKeys.documents.types,
    queryFn: () => documentsApi.getTypes(),
  });

  const createMutation = useMutation({
    mutationFn: (data: DocTypeFormValues) => documentsApi.createType(data),
    onSuccess: () => {
      toast.success("서류 유형이 추가되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["documents", "types"] });
      closeDialog();
    },
    onError: () => toast.error("서류 유형 추가에 실패했습니다."),
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<DocTypeFormValues>({
    resolver: zodResolver(docTypeSchema),
    defaultValues: {
      requiredForEquipment: false,
      requiredForPerson: false,
      validityDays: null,
    },
  });

  function closeDialog() {
    setDialogOpen(false);
    setEditItem(null);
    reset({
      name: "",
      category: "",
      requiredForEquipment: false,
      requiredForPerson: false,
      validityDays: null,
    });
  }

  function openCreate() {
    setEditItem(null);
    reset({
      name: "",
      category: "",
      requiredForEquipment: false,
      requiredForPerson: false,
      validityDays: null,
    });
    setDialogOpen(true);
  }

  function openEdit(item: DocumentType) {
    setEditItem(item);
    reset({
      name: item.name,
      category: item.category,
      requiredForEquipment: item.requiredForEquipment,
      requiredForPerson: item.requiredForPerson,
      validityDays: item.validityDays,
    });
    setDialogOpen(true);
  }

  const types = typesQuery.data ?? [];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">서류 유형 관리</h1>
        <button
          type="button"
          onClick={openCreate}
          className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
        >
          <Plus className="h-4 w-4" />
          유형 추가
        </button>
      </div>

      {typesQuery.isLoading && (
        <p className="text-sm text-gray-500">불러오는 중...</p>
      )}

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {types.map((dt) => (
          <div
            key={dt.id}
            className="rounded-xl border border-gray-200 bg-white p-5"
          >
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-blue-100 p-2">
                  <FileText className="h-5 w-5 text-blue-600" />
                </div>
                <div>
                  <p className="font-semibold text-gray-900">{dt.name}</p>
                  <p className="text-xs text-gray-500">{dt.category}</p>
                </div>
              </div>
              <div className="flex gap-1">
                <button
                  type="button"
                  onClick={() => openEdit(dt)}
                  className="rounded p-1 text-gray-400 hover:bg-gray-100 hover:text-gray-600"
                >
                  <Pencil className="h-4 w-4" />
                </button>
                <button
                  type="button"
                  className="rounded p-1 text-gray-400 hover:bg-red-50 hover:text-red-600"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            </div>
            <div className="mt-3 flex flex-wrap gap-2">
              {dt.requiredForEquipment && (
                <span className="rounded-full bg-green-100 px-2 py-0.5 text-xs text-green-700">
                  장비 필수
                </span>
              )}
              {dt.requiredForPerson && (
                <span className="rounded-full bg-purple-100 px-2 py-0.5 text-xs text-purple-700">
                  인원 필수
                </span>
              )}
              {dt.validityDays && (
                <span className="rounded-full bg-amber-100 px-2 py-0.5 text-xs text-amber-700">
                  유효기간 {dt.validityDays}일
                </span>
              )}
            </div>
          </div>
        ))}
      </div>

      <FormDialog
        open={dialogOpen}
        onClose={closeDialog}
        title={editItem ? "서류 유형 수정" : "서류 유형 추가"}
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
              유효기간 (일)
            </label>
            <input
              type="number"
              {...register("validityDays")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              placeholder="무제한이면 비워두세요"
            />
          </div>
          <div className="flex gap-6">
            <label className="flex items-center gap-2 text-sm text-gray-700">
              <input
                type="checkbox"
                {...register("requiredForEquipment")}
                className="h-4 w-4 rounded border-gray-300 text-blue-600"
              />
              장비 필수
            </label>
            <label className="flex items-center gap-2 text-sm text-gray-700">
              <input
                type="checkbox"
                {...register("requiredForPerson")}
                className="h-4 w-4 rounded border-gray-300 text-blue-600"
              />
              인원 필수
            </label>
          </div>
        </form>
      </FormDialog>
    </div>
  );
}
