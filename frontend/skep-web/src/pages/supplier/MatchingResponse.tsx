import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { type ColumnDef } from "@tanstack/react-table";
import { Check, X, FileText } from "lucide-react";
import toast from "react-hot-toast";
import {
  quotationRequestsApi,
  quotationsApi,
  queryKeys,
} from "@/api/endpoints";
import type { QuotationRequest } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate } from "@/utils/formatDate";
import { FormDialog } from "@/components/common/FormDialog";

const quoteSchema = z.object({
  totalAmount: z.coerce.number().min(1, "금액을 입력하세요"),
  validUntil: z.string().min(1, "유효기한을 입력하세요"),
  notes: z.string().optional(),
});

type QuoteFormData = z.infer<typeof quoteSchema>;

export default function MatchingResponse() {
  const queryClient = useQueryClient();
  const [quoteTarget, setQuoteTarget] = useState<QuotationRequest | null>(null);

  const { data, isLoading, isError } = useQuery({
    queryKey: queryKeys.dispatch.quotationRequests({ size: 100 }),
    queryFn: () => quotationRequestsApi.getAll({ size: 100 }),
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<QuoteFormData>({
    resolver: zodResolver(quoteSchema),
  });

  const createQuoteMutation = useMutation({
    mutationFn: (data: QuoteFormData & { requestId: string }) =>
      quotationsApi.create({
        requestId: data.requestId,
        totalAmount: data.totalAmount,
        validUntil: data.validUntil,
        notes: data.notes ?? "",
      }),
    onSuccess: () => {
      toast.success("견적이 제출되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["dispatch", "quotations"] });
      setQuoteTarget(null);
      reset();
    },
    onError: () => {
      toast.error("견적 제출에 실패했습니다.");
    },
  });

  const onSubmitQuote = (data: QuoteFormData) => {
    if (!quoteTarget) return;
    createQuoteMutation.mutate({ ...data, requestId: quoteTarget.id });
  };

  const columns = useMemo<ColumnDef<QuotationRequest, unknown>[]>(
    () => [
      { accessorKey: "siteName", header: "현장" },
      { accessorKey: "equipmentTypeName", header: "장비 유형" },
      { accessorKey: "quantity", header: "수량" },
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
      { accessorKey: "requesterName", header: "요청자" },
      {
        id: "actions",
        header: "작업",
        enableSorting: false,
        cell: ({ row }) => (
          <div className="flex items-center gap-1">
            <button
              type="button"
              onClick={() => setQuoteTarget(row.original)}
              className="rounded p-1.5 text-blue-600 hover:bg-blue-50 transition-colors"
              title="견적 제출"
            >
              <FileText className="h-4 w-4" />
            </button>
          </div>
        ),
      },
    ],
    []
  );

  return (
    <div className="space-y-4 p-6">
      <h1 className="text-2xl font-bold text-gray-900">매칭 요청 응답</h1>

      <DataTable
        columns={columns}
        data={data?.content ?? []}
        isLoading={isLoading}
        isError={isError}
        searchPlaceholder="현장, 장비 유형 검색..."
      />

      {/* Quote dialog */}
      <FormDialog
        open={!!quoteTarget}
        onClose={() => {
          setQuoteTarget(null);
          reset();
        }}
        title="견적 제출"
        hideFooter
      >
        {quoteTarget && (
          <form onSubmit={handleSubmit(onSubmitQuote)} className="space-y-4">
            <div className="rounded-lg bg-gray-50 p-3 text-sm">
              <p>
                <span className="text-gray-500">현장:</span>{" "}
                {quoteTarget.siteName}
              </p>
              <p>
                <span className="text-gray-500">장비 유형:</span>{" "}
                {quoteTarget.equipmentTypeName} x {quoteTarget.quantity}
              </p>
              <p>
                <span className="text-gray-500">기간:</span>{" "}
                {formatDate(quoteTarget.startDate)} ~{" "}
                {formatDate(quoteTarget.endDate)}
              </p>
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                견적 금액 (원)
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
                  setQuoteTarget(null);
                  reset();
                }}
                className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
              >
                취소
              </button>
              <button
                type="submit"
                disabled={createQuoteMutation.isPending}
                className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors disabled:opacity-50"
              >
                {createQuoteMutation.isPending ? "제출 중..." : "제출"}
              </button>
            </div>
          </form>
        )}
      </FormDialog>
    </div>
  );
}
