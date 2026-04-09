import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import toast from "react-hot-toast";
import { Plus, FileText, AlertTriangle } from "lucide-react";
import { documentsApi, queryKeys } from "@/api/endpoints";
import type { DocumentType, Document } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { FormDialog } from "@/components/common/FormDialog";
import { formatDate } from "@/utils/formatDate";

type TabKey = "types" | "expiring";

const docTypeSchema = z.object({
  name: z.string().min(1, "유형명을 입력하세요"),
  category: z.string().min(1, "카테고리를 입력하세요"),
  requiredForEquipment: z.boolean(),
  requiredForPerson: z.boolean(),
  validityDays: z.coerce.number().nullable(),
});

type DocTypeFormValues = z.infer<typeof docTypeSchema>;

export default function DocumentManagement() {
  const [tab, setTab] = useState<TabKey>("types");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [expiryDays, setExpiryDays] = useState(30);
  const queryClient = useQueryClient();

  const typesQuery = useQuery({
    queryKey: queryKeys.documents.types,
    queryFn: () => documentsApi.getTypes(),
  });

  const expiringQuery = useQuery({
    queryKey: queryKeys.documents.expiring(expiryDays),
    queryFn: () => documentsApi.getExpiring(expiryDays),
  });

  const createTypeMutation = useMutation({
    mutationFn: (data: DocTypeFormValues) => documentsApi.createType(data),
    onSuccess: () => {
      toast.success("서류 유형이 추가되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["documents", "types"] });
      setDialogOpen(false);
      reset();
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

  const typeColumns = useMemo<ColumnDef<DocumentType, unknown>[]>(
    () => [
      { accessorKey: "name", header: "유형명" },
      { accessorKey: "category", header: "카테고리" },
      {
        accessorKey: "requiredForEquipment",
        header: "장비 필수",
        cell: ({ getValue }) => (getValue() ? "Y" : "N"),
      },
      {
        accessorKey: "requiredForPerson",
        header: "인원 필수",
        cell: ({ getValue }) => (getValue() ? "Y" : "N"),
      },
      {
        accessorKey: "validityDays",
        header: "유효기간",
        cell: ({ getValue }) => {
          const v = getValue() as number | null;
          return v ? `${v}일` : "-";
        },
      },
    ],
    []
  );

  const expiringColumns = useMemo<ColumnDef<Document, unknown>[]>(
    () => [
      { accessorKey: "typeName", header: "서류 유형" },
      { accessorKey: "ownerName", header: "소유자" },
      { accessorKey: "ownerType", header: "소유자 유형" },
      {
        accessorKey: "expiryDate",
        header: "만료일",
        cell: ({ getValue }) => (
          <span className="text-amber-600 font-medium">
            {formatDate(getValue() as string)}
          </span>
        ),
      },
      {
        accessorKey: "verified",
        header: "검증",
        cell: ({ getValue }) => (
          <StatusBadge status={getValue() ? "APPROVED" : "PENDING"} />
        ),
      },
    ],
    []
  );

  const TABS: { key: TabKey; label: string; icon: React.ElementType }[] = [
    { key: "types", label: "서류 유형", icon: FileText },
    { key: "expiring", label: "만료 서류", icon: AlertTriangle },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">서류 관리</h1>
        {tab === "types" && (
          <button
            type="button"
            onClick={() => {
              reset();
              setDialogOpen(true);
            }}
            className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
          >
            <Plus className="h-4 w-4" />
            유형 추가
          </button>
        )}
      </div>

      {/* Tabs */}
      <div className="flex border-b border-gray-200">
        {TABS.map((t) => {
          const Icon = t.icon;
          return (
            <button
              key={t.key}
              type="button"
              onClick={() => setTab(t.key)}
              className={`flex items-center gap-1.5 px-4 py-2.5 text-sm font-medium transition-colors ${
                tab === t.key
                  ? "border-b-2 border-blue-600 text-blue-600"
                  : "text-gray-500 hover:text-gray-700"
              }`}
            >
              <Icon className="h-4 w-4" />
              {t.label}
            </button>
          );
        })}
      </div>

      {tab === "types" && (
        <DataTable
          columns={typeColumns}
          data={typesQuery.data ?? []}
          isLoading={typesQuery.isLoading}
          isError={typesQuery.isError}
          searchPlaceholder="유형명 검색..."
        />
      )}

      {tab === "expiring" && (
        <>
          <div className="flex items-center gap-3">
            <label className="text-sm text-gray-600">만료 기간:</label>
            <select
              value={expiryDays}
              onChange={(e) => setExpiryDays(Number(e.target.value))}
              className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
            >
              <option value={7}>7일 이내</option>
              <option value={14}>14일 이내</option>
              <option value={30}>30일 이내</option>
              <option value={60}>60일 이내</option>
              <option value={90}>90일 이내</option>
            </select>
          </div>
          <DataTable
            columns={expiringColumns}
            data={expiringQuery.data ?? []}
            isLoading={expiringQuery.isLoading}
            isError={expiringQuery.isError}
            searchPlaceholder="소유자 검색..."
          />
        </>
      )}

      <FormDialog
        open={dialogOpen}
        onClose={() => {
          setDialogOpen(false);
          reset();
        }}
        title="서류 유형 추가"
        onSave={handleSubmit((data) => createTypeMutation.mutate(data))}
        isSaving={createTypeMutation.isPending}
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
              placeholder="무제한이면 비워두세요"
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
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
