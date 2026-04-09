import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { type ColumnDef } from "@tanstack/react-table";
import { Check, X, Plus } from "lucide-react";
import toast from "react-hot-toast";
import {
  quotationsApi,
  quotationRequestsApi,
  sitesApi,
  equipmentApi,
  queryKeys,
} from "@/api/endpoints";
import type { Quotation } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate, formatMoney } from "@/utils/formatDate";
import { FormDialog } from "@/components/common/FormDialog";

const requestSchema = z.object({
  siteId: z.string().min(1, "현장을 선택하세요"),
  equipmentTypeId: z.string().min(1, "장비 유형을 선택하세요"),
  quantity: z.coerce.number().min(1, "수량을 입력하세요"),
  startDate: z.string().min(1, "시작일을 입력하세요"),
  endDate: z.string().min(1, "종료일을 입력하세요"),
  description: z.string().optional(),
});

type RequestFormData = z.infer<typeof requestSchema>;

export default function BpQuotationManagement() {
  const queryClient = useQueryClient();
  const [dialogOpen, setDialogOpen] = useState(false);

  const quotationsQuery = useQuery({
    queryKey: queryKeys.dispatch.quotations({ size: 100 }),
    queryFn: () => quotationsApi.getAll({ size: 100 }),
  });

  const sitesQuery = useQuery({
    queryKey: queryKeys.dispatch.sites({ size: 200 }),
    queryFn: () => sitesApi.getAll({ size: 200 }),
  });

  const typesQuery = useQuery({
    queryKey: queryKeys.equipment.types,
    queryFn: () => equipmentApi.getTypes(),
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<RequestFormData>({
    resolver: zodResolver(requestSchema),
  });

  const createRequestMutation = useMutation({
    mutationFn: (data: RequestFormData) =>
      quotationRequestsApi.create(data),
    onSuccess: () => {
      toast.success("견적 요청이 등록되었습니다.");
      queryClient.invalidateQueries({
        queryKey: ["dispatch", "quotationRequests"],
      });
      setDialogOpen(false);
      reset();
    },
    onError: () => toast.error("등록에 실패했습니다."),
  });

  const acceptMutation = useMutation({
    mutationFn: (id: string) => quotationsApi.accept(id),
    onSuccess: () => {
      toast.success("견적이 승인되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["dispatch", "quotations"] });
    },
    onError: () => toast.error("승인에 실패했습니다."),
  });

  const rejectMutation = useMutation({
    mutationFn: (id: string) => quotationsApi.reject(id, "BP 반려"),
    onSuccess: () => {
      toast.success("견적이 반려되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["dispatch", "quotations"] });
    },
    onError: () => toast.error("반려에 실패했습니다."),
  });

  const columns = useMemo<ColumnDef<Quotation, unknown>[]>(
    () => [
      { accessorKey: "supplierName", header: "공급사" },
      {
        accessorKey: "totalAmount",
        header: "총액",
        cell: ({ getValue }) => formatMoney(getValue() as number),
      },
      {
        accessorKey: "validUntil",
        header: "유효기한",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        accessorKey: "status",
        header: "상태",
        cell: ({ getValue }) => <StatusBadge status={getValue() as string} />,
      },
      {
        accessorKey: "createdAt",
        header: "생성일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        id: "actions",
        header: "작업",
        enableSorting: false,
        cell: ({ row }) => {
          if (row.original.status === "SUBMITTED") {
            return (
              <div className="flex items-center gap-1">
                <button
                  type="button"
                  onClick={() => acceptMutation.mutate(row.original.id)}
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
            );
          }
          return null;
        },
      },
    ],
    []
  );

  return (
    <div className="space-y-4 p-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">견적 관리</h1>
        <button
          type="button"
          onClick={() => setDialogOpen(true)}
          className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
        >
          <Plus className="h-4 w-4" />
          견적 요청
        </button>
      </div>

      <DataTable
        columns={columns}
        data={quotationsQuery.data?.content ?? []}
        isLoading={quotationsQuery.isLoading}
        isError={quotationsQuery.isError}
        searchPlaceholder="공급사 검색..."
      />

      <FormDialog
        open={dialogOpen}
        onClose={() => {
          setDialogOpen(false);
          reset();
        }}
        title="견적 요청"
        hideFooter
      >
        <form
          onSubmit={handleSubmit((d) => createRequestMutation.mutate(d))}
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
              <p className="mt-1 text-xs text-red-500">{errors.siteId.message}</p>
            )}
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                장비 유형
              </label>
              <select
                {...register("equipmentTypeId")}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              >
                <option value="">선택</option>
                {(typesQuery.data ?? []).map((t) => (
                  <option key={t.id} value={t.id}>
                    {t.name}
                  </option>
                ))}
              </select>
              {errors.equipmentTypeId && (
                <p className="mt-1 text-xs text-red-500">
                  {errors.equipmentTypeId.message}
                </p>
              )}
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                수량
              </label>
              <input
                type="number"
                {...register("quantity")}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              />
              {errors.quantity && (
                <p className="mt-1 text-xs text-red-500">
                  {errors.quantity.message}
                </p>
              )}
            </div>
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
            </div>
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              요청 내용
            </label>
            <textarea
              {...register("description")}
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
              disabled={createRequestMutation.isPending}
              className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors disabled:opacity-50"
            >
              {createRequestMutation.isPending ? "요청 중..." : "요청"}
            </button>
          </div>
        </form>
      </FormDialog>
    </div>
  );
}
