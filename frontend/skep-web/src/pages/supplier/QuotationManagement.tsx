import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { type ColumnDef } from "@tanstack/react-table";
import { Plus, Send } from "lucide-react";
import toast from "react-hot-toast";
import { quotationsApi, queryKeys } from "@/api/endpoints";
import type { Quotation } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate, formatMoney } from "@/utils/formatDate";
import { FormDialog } from "@/components/common/FormDialog";

const quotationSchema = z.object({
  requestId: z.string().min(1, "요청을 선택하세요"),
  totalAmount: z.coerce.number().min(1, "금액을 입력하세요"),
  validUntil: z.string().min(1, "유효기한을 입력하세요"),
  notes: z.string().optional(),
});

type QuotationFormData = z.infer<typeof quotationSchema>;

export default function QuotationManagement() {
  const queryClient = useQueryClient();
  const [dialogOpen, setDialogOpen] = useState(false);

  const { data, isLoading, isError } = useQuery({
    queryKey: queryKeys.dispatch.quotations({ size: 100 }),
    queryFn: () => quotationsApi.getAll({ size: 100 }),
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<QuotationFormData>({
    resolver: zodResolver(quotationSchema),
  });

  const createMutation = useMutation({
    mutationFn: (data: QuotationFormData) => quotationsApi.create(data),
    onSuccess: () => {
      toast.success("견적이 생성되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["dispatch", "quotations"] });
      setDialogOpen(false);
      reset();
    },
    onError: () => {
      toast.error("생성에 실패했습니다.");
    },
  });

  const submitMutation = useMutation({
    mutationFn: (id: string) => quotationsApi.submit(id),
    onSuccess: () => {
      toast.success("견적이 제출되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["dispatch", "quotations"] });
    },
    onError: () => {
      toast.error("제출에 실패했습니다.");
    },
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
          if (row.original.status === "DRAFT") {
            return (
              <button
                type="button"
                onClick={() => submitMutation.mutate(row.original.id)}
                className="flex items-center gap-1 rounded-lg bg-blue-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-blue-700 transition-colors"
              >
                <Send className="h-3.5 w-3.5" />
                제출
              </button>
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
          견적 생성
        </button>
      </div>

      <DataTable
        columns={columns}
        data={data?.content ?? []}
        isLoading={isLoading}
        isError={isError}
        searchPlaceholder="공급사 검색..."
      />

      <FormDialog
        open={dialogOpen}
        onClose={() => {
          setDialogOpen(false);
          reset();
        }}
        title="견적 생성"
        hideFooter
      >
        <form
          onSubmit={handleSubmit((d) => createMutation.mutate(d))}
          className="space-y-4"
        >
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              요청 ID
            </label>
            <input
              {...register("requestId")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.requestId && (
              <p className="mt-1 text-xs text-red-500">
                {errors.requestId.message}
              </p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              총액 (원)
            </label>
            <input
              type="number"
              {...register("totalAmount")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.totalAmount && (
              <p className="mt-1 text-xs text-red-500">
                {errors.totalAmount.message}
              </p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              유효기한
            </label>
            <input
              type="date"
              {...register("validUntil")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.validUntil && (
              <p className="mt-1 text-xs text-red-500">
                {errors.validUntil.message}
              </p>
            )}
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
              {createMutation.isPending ? "생성 중..." : "생성"}
            </button>
          </div>
        </form>
      </FormDialog>
    </div>
  );
}
