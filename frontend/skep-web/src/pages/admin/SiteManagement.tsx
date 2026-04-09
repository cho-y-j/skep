import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import toast from "react-hot-toast";
import { Plus, ChevronDown, ChevronRight, MapPin } from "lucide-react";
import { sitesApi, companiesApi, queryKeys } from "@/api/endpoints";
import type { Site } from "@/types";
import { CompanyType, BoundaryType } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { FormDialog } from "@/components/common/FormDialog";

const siteSchema = z.object({
  name: z.string().min(1, "현장명을 입력하세요"),
  address: z.string().min(1, "주소를 입력하세요"),
  companyId: z.string().min(1, "BP사를 선택하세요"),
  boundaryType: z.nativeEnum(BoundaryType),
  latitude: z.coerce.number().min(-90).max(90),
  longitude: z.coerce.number().min(-180).max(180),
  boundaryRadius: z.coerce.number().nullable().optional(),
});

type SiteFormValues = z.infer<typeof siteSchema>;

export default function SiteManagement() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const queryClient = useQueryClient();

  const sitesQuery = useQuery({
    queryKey: queryKeys.dispatch.sites({ size: 200 }),
    queryFn: () => sitesApi.getAll({ size: 200 }),
  });

  const bpQuery = useQuery({
    queryKey: queryKeys.companies.byType(CompanyType.BP),
    queryFn: () => companiesApi.getByType(CompanyType.BP, { size: 200 }),
  });

  const createMutation = useMutation({
    mutationFn: (data: SiteFormValues) => sitesApi.create(data),
    onSuccess: () => {
      toast.success("현장이 등록되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["dispatch", "sites"] });
      setDialogOpen(false);
      reset();
    },
    onError: () => toast.error("현장 등록에 실패했습니다."),
  });

  const {
    register,
    handleSubmit,
    reset,
    watch,
    formState: { errors },
  } = useForm<SiteFormValues>({
    resolver: zodResolver(siteSchema),
    defaultValues: {
      boundaryType: BoundaryType.CIRCLE,
      latitude: 37.5665,
      longitude: 126.978,
      boundaryRadius: 100,
    },
  });

  const boundaryType = watch("boundaryType");

  const columns = useMemo<ColumnDef<Site, unknown>[]>(
    () => [
      {
        id: "expand",
        header: "",
        enableSorting: false,
        cell: ({ row }) => (
          <button
            type="button"
            onClick={() =>
              setExpandedId((prev) =>
                prev === row.original.id ? null : row.original.id
              )
            }
            className="p-1 text-gray-400 hover:text-gray-600"
          >
            {expandedId === row.original.id ? (
              <ChevronDown className="h-4 w-4" />
            ) : (
              <ChevronRight className="h-4 w-4" />
            )}
          </button>
        ),
      },
      { accessorKey: "name", header: "현장명" },
      { accessorKey: "address", header: "주소" },
      { accessorKey: "companyName", header: "BP사" },
      {
        accessorKey: "boundaryType",
        header: "경계 유형",
        cell: ({ getValue }) => (
          <span className="text-sm">
            {getValue() === "CIRCLE" ? "원형" : "다각형"}
          </span>
        ),
      },
      {
        accessorKey: "active",
        header: "상태",
        cell: ({ getValue }) => (
          <StatusBadge status={getValue() ? "ACTIVE" : "INACTIVE"} />
        ),
      },
    ],
    [expandedId]
  );

  const expandedSite = (sitesQuery.data?.content ?? []).find(
    (s) => s.id === expandedId
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">현장 관리</h1>
        <button
          type="button"
          onClick={() => {
            reset();
            setDialogOpen(true);
          }}
          className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
        >
          <Plus className="h-4 w-4" />
          현장 등록
        </button>
      </div>

      <DataTable
        columns={columns}
        data={sitesQuery.data?.content ?? []}
        isLoading={sitesQuery.isLoading}
        isError={sitesQuery.isError}
        searchPlaceholder="현장명 또는 주소 검색..."
      />

      {/* Map preview for expanded site */}
      {expandedSite && (
        <div className="rounded-xl border border-gray-200 bg-white p-4">
          <div className="mb-2 flex items-center gap-2">
            <MapPin className="h-4 w-4 text-gray-500" />
            <span className="text-sm font-medium text-gray-700">
              {expandedSite.name} 위치
            </span>
          </div>
          <div className="flex h-64 items-center justify-center rounded-lg bg-gray-100 text-sm text-gray-500">
            위도: {expandedSite.latitude}, 경도: {expandedSite.longitude}
            {expandedSite.boundaryRadius &&
              ` / 반경: ${expandedSite.boundaryRadius}m`}
          </div>
        </div>
      )}

      <FormDialog
        open={dialogOpen}
        onClose={() => {
          setDialogOpen(false);
          reset();
        }}
        title="현장 등록"
        onSave={handleSubmit((data) => createMutation.mutate(data))}
        isSaving={createMutation.isPending}
        className="max-w-2xl"
      >
        <form className="space-y-4" onSubmit={(e) => e.preventDefault()}>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              현장명
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
              주소
            </label>
            <input
              {...register("address")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.address && (
              <p className="mt-1 text-xs text-red-500">
                {errors.address.message}
              </p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              BP사
            </label>
            <select
              {...register("companyId")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="">선택하세요</option>
              {(bpQuery.data?.content ?? []).map((c) => (
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
              경계 유형
            </label>
            <select
              {...register("boundaryType")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="CIRCLE">원형 (CIRCLE)</option>
              <option value="POLYGON">다각형 (POLYGON)</option>
            </select>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                위도
              </label>
              <input
                type="number"
                step="any"
                {...register("latitude")}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              />
              {errors.latitude && (
                <p className="mt-1 text-xs text-red-500">
                  {errors.latitude.message}
                </p>
              )}
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                경도
              </label>
              <input
                type="number"
                step="any"
                {...register("longitude")}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              />
              {errors.longitude && (
                <p className="mt-1 text-xs text-red-500">
                  {errors.longitude.message}
                </p>
              )}
            </div>
          </div>
          {boundaryType === BoundaryType.CIRCLE && (
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                반경 (m)
              </label>
              <input
                type="number"
                {...register("boundaryRadius")}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              />
            </div>
          )}
        </form>
      </FormDialog>
    </div>
  );
}
