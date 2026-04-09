import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { useForm, useFieldArray } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import toast from "react-hot-toast";
import {
  Plus,
  Send,
  Check,
  X as XIcon,
  Trash2,
} from "lucide-react";
import {
  quotationRequestsApi,
  quotationsApi,
  sitesApi,
  equipmentApi,
  queryKeys,
} from "@/api/endpoints";
import type { QuotationRequest, Quotation } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { FormDialog } from "@/components/common/FormDialog";
import { formatDate } from "@/utils/formatDate";
import { formatMoney } from "@/utils/formatDate";

// --- Schemas ---

const requestSchema = z.object({
  siteId: z.string().min(1, "현장을 선택하세요"),
  equipmentTypeId: z.string().min(1, "장비 유형을 선택하세요"),
  quantity: z.coerce.number().min(1, "수량을 입력하세요"),
  startDate: z.string().min(1, "시작일을 입력하세요"),
  endDate: z.string().min(1, "종료일을 입력하세요"),
  description: z.string().optional(),
});

type RequestFormValues = z.infer<typeof requestSchema>;

const quotationItemSchema = z.object({
  equipmentTypeId: z.string().min(1),
  unitPrice: z.coerce.number().min(0),
  quantity: z.coerce.number().min(1),
  description: z.string().optional(),
});

const quotationSchema = z.object({
  requestId: z.string().min(1, "견적 요청을 선택하세요"),
  validUntil: z.string().min(1, "유효기한을 입력하세요"),
  notes: z.string().optional(),
  items: z.array(quotationItemSchema).min(1, "항목을 1개 이상 추가하세요"),
});

type QuotationFormValues = z.infer<typeof quotationSchema>;

// --- Tabs ---

type TabKey = "requests" | "quotations";

export default function QuotationManagement() {
  const [tab, setTab] = useState<TabKey>("requests");
  const [reqDialogOpen, setReqDialogOpen] = useState(false);
  const [quotDialogOpen, setQuotDialogOpen] = useState(false);
  const queryClient = useQueryClient();

  // Data queries
  const requestsQuery = useQuery({
    queryKey: queryKeys.dispatch.quotationRequests({ size: 200 }),
    queryFn: () => quotationRequestsApi.getAll({ size: 200 }),
  });

  const quotationsQuery = useQuery({
    queryKey: queryKeys.dispatch.quotations({ size: 200 }),
    queryFn: () => quotationsApi.getAll({ size: 200 }),
  });

  const sitesQuery = useQuery({
    queryKey: queryKeys.dispatch.sites({ size: 200 }),
    queryFn: () => sitesApi.getAll({ size: 200 }),
  });

  const typesQuery = useQuery({
    queryKey: queryKeys.equipment.types,
    queryFn: () => equipmentApi.getTypes(),
  });

  // Mutations
  const createRequestMutation = useMutation({
    mutationFn: (data: RequestFormValues) =>
      quotationRequestsApi.create(data),
    onSuccess: () => {
      toast.success("견적 요청이 생성되었습니다.");
      queryClient.invalidateQueries({
        queryKey: ["dispatch", "quotationRequests"],
      });
      setReqDialogOpen(false);
      reqForm.reset();
    },
    onError: () => toast.error("견적 요청 생성에 실패했습니다."),
  });

  const createQuotationMutation = useMutation({
    mutationFn: (data: QuotationFormValues) => quotationsApi.create(data),
    onSuccess: () => {
      toast.success("견적서가 생성되었습니다.");
      queryClient.invalidateQueries({
        queryKey: ["dispatch", "quotations"],
      });
      setQuotDialogOpen(false);
      quotForm.reset();
    },
    onError: () => toast.error("견적서 생성에 실패했습니다."),
  });

  const submitMutation = useMutation({
    mutationFn: (id: string) => quotationsApi.submit(id),
    onSuccess: () => {
      toast.success("견적서가 제출되었습니다.");
      queryClient.invalidateQueries({
        queryKey: ["dispatch", "quotations"],
      });
    },
  });

  const acceptMutation = useMutation({
    mutationFn: (id: string) => quotationsApi.accept(id),
    onSuccess: () => {
      toast.success("견적서가 승인되었습니다.");
      queryClient.invalidateQueries({
        queryKey: ["dispatch", "quotations"],
      });
    },
  });

  const rejectMutation = useMutation({
    mutationFn: (id: string) => quotationsApi.reject(id, "관리자 반려"),
    onSuccess: () => {
      toast.success("견적서가 반려되었습니다.");
      queryClient.invalidateQueries({
        queryKey: ["dispatch", "quotations"],
      });
    },
  });

  // Forms
  const reqForm = useForm<RequestFormValues>({
    resolver: zodResolver(requestSchema),
  });

  const quotForm = useForm<QuotationFormValues>({
    resolver: zodResolver(quotationSchema),
    defaultValues: { items: [{ equipmentTypeId: "", unitPrice: 0, quantity: 1, description: "" }] },
  });

  const { fields, append, remove } = useFieldArray({
    control: quotForm.control,
    name: "items",
  });

  // Columns
  const requestColumns = useMemo<ColumnDef<QuotationRequest, unknown>[]>(
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
    ],
    []
  );

  const quotationColumns = useMemo<ColumnDef<Quotation, unknown>[]>(
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
        id: "actions",
        header: "관리",
        enableSorting: false,
        cell: ({ row }) => {
          const q = row.original;
          return (
            <div className="flex gap-1">
              {q.status === "DRAFT" && (
                <button
                  type="button"
                  onClick={() => submitMutation.mutate(q.id)}
                  className="rounded p-1 text-blue-600 hover:bg-blue-50"
                  title="제출"
                >
                  <Send className="h-4 w-4" />
                </button>
              )}
              {q.status === "SUBMITTED" && (
                <>
                  <button
                    type="button"
                    onClick={() => acceptMutation.mutate(q.id)}
                    className="rounded p-1 text-green-600 hover:bg-green-50"
                    title="승인"
                  >
                    <Check className="h-4 w-4" />
                  </button>
                  <button
                    type="button"
                    onClick={() => rejectMutation.mutate(q.id)}
                    className="rounded p-1 text-red-600 hover:bg-red-50"
                    title="반려"
                  >
                    <XIcon className="h-4 w-4" />
                  </button>
                </>
              )}
            </div>
          );
        },
      },
    ],
    [submitMutation, acceptMutation, rejectMutation]
  );

  const TABS: { key: TabKey; label: string }[] = [
    { key: "requests", label: "견적 요청" },
    { key: "quotations", label: "견적서" },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">견적 관리</h1>
        <button
          type="button"
          onClick={() =>
            tab === "requests"
              ? (reqForm.reset(), setReqDialogOpen(true))
              : (quotForm.reset({ items: [{ equipmentTypeId: "", unitPrice: 0, quantity: 1, description: "" }] }), setQuotDialogOpen(true))
          }
          className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
        >
          <Plus className="h-4 w-4" />
          {tab === "requests" ? "견적 요청" : "견적서 작성"}
        </button>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-gray-200">
        {TABS.map((t) => (
          <button
            key={t.key}
            type="button"
            onClick={() => setTab(t.key)}
            className={`px-4 py-2.5 text-sm font-medium transition-colors ${
              tab === t.key
                ? "border-b-2 border-blue-600 text-blue-600"
                : "text-gray-500 hover:text-gray-700"
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      {tab === "requests" && (
        <DataTable
          columns={requestColumns}
          data={requestsQuery.data?.content ?? []}
          isLoading={requestsQuery.isLoading}
          isError={requestsQuery.isError}
          searchPlaceholder="현장명 검색..."
        />
      )}

      {tab === "quotations" && (
        <DataTable
          columns={quotationColumns}
          data={quotationsQuery.data?.content ?? []}
          isLoading={quotationsQuery.isLoading}
          isError={quotationsQuery.isError}
          searchPlaceholder="공급사 검색..."
        />
      )}

      {/* Request dialog */}
      <FormDialog
        open={reqDialogOpen}
        onClose={() => {
          setReqDialogOpen(false);
          reqForm.reset();
        }}
        title="견적 요청"
        onSave={reqForm.handleSubmit((data) =>
          createRequestMutation.mutate(data)
        )}
        isSaving={createRequestMutation.isPending}
      >
        <form className="space-y-4" onSubmit={(e) => e.preventDefault()}>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              현장
            </label>
            <select
              {...reqForm.register("siteId")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="">선택하세요</option>
              {(sitesQuery.data?.content ?? []).map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              장비 유형
            </label>
            <select
              {...reqForm.register("equipmentTypeId")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="">선택하세요</option>
              {(typesQuery.data ?? []).map((t) => (
                <option key={t.id} value={t.id}>
                  {t.name}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              수량
            </label>
            <input
              type="number"
              {...reqForm.register("quantity")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                시작일
              </label>
              <input
                type="date"
                {...reqForm.register("startDate")}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              />
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                종료일
              </label>
              <input
                type="date"
                {...reqForm.register("endDate")}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              />
            </div>
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              비고
            </label>
            <textarea
              {...reqForm.register("description")}
              rows={2}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>
        </form>
      </FormDialog>

      {/* Quotation dialog */}
      <FormDialog
        open={quotDialogOpen}
        onClose={() => {
          setQuotDialogOpen(false);
          quotForm.reset();
        }}
        title="견적서 작성"
        onSave={quotForm.handleSubmit((data) =>
          createQuotationMutation.mutate(data)
        )}
        isSaving={createQuotationMutation.isPending}
        className="max-w-2xl"
      >
        <form className="space-y-4" onSubmit={(e) => e.preventDefault()}>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              견적 요청
            </label>
            <select
              {...quotForm.register("requestId")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="">선택하세요</option>
              {(requestsQuery.data?.content ?? []).map((r) => (
                <option key={r.id} value={r.id}>
                  {r.siteName} - {r.equipmentTypeName} x{r.quantity}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              유효기한
            </label>
            <input
              type="date"
              {...quotForm.register("validUntil")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>

          {/* Dynamic items */}
          <div>
            <div className="mb-2 flex items-center justify-between">
              <label className="text-sm font-medium text-gray-700">
                견적 항목
              </label>
              <button
                type="button"
                onClick={() =>
                  append({
                    equipmentTypeId: "",
                    unitPrice: 0,
                    quantity: 1,
                    description: "",
                  })
                }
                className="text-xs text-blue-600 hover:underline"
              >
                + 항목 추가
              </button>
            </div>
            <div className="space-y-3">
              {fields.map((field, idx) => (
                <div
                  key={field.id}
                  className="flex items-start gap-2 rounded-lg border border-gray-200 p-3"
                >
                  <div className="flex-1 space-y-2">
                    <select
                      {...quotForm.register(`items.${idx}.equipmentTypeId`)}
                      className="w-full rounded border border-gray-300 px-2 py-1 text-sm"
                    >
                      <option value="">장비 유형</option>
                      {(typesQuery.data ?? []).map((t) => (
                        <option key={t.id} value={t.id}>
                          {t.name}
                        </option>
                      ))}
                    </select>
                    <div className="flex gap-2">
                      <input
                        type="number"
                        placeholder="단가"
                        {...quotForm.register(`items.${idx}.unitPrice`)}
                        className="w-1/2 rounded border border-gray-300 px-2 py-1 text-sm"
                      />
                      <input
                        type="number"
                        placeholder="수량"
                        {...quotForm.register(`items.${idx}.quantity`)}
                        className="w-1/2 rounded border border-gray-300 px-2 py-1 text-sm"
                      />
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={() => remove(idx)}
                    className="mt-1 rounded p-1 text-gray-400 hover:bg-red-50 hover:text-red-600"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              ))}
            </div>
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              비고
            </label>
            <textarea
              {...quotForm.register("notes")}
              rows={2}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>
        </form>
      </FormDialog>
    </div>
  );
}
