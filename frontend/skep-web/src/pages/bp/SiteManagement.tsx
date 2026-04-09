import { useState, useMemo, useEffect, useRef } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { type ColumnDef } from "@tanstack/react-table";
import { Plus, Trash2 } from "lucide-react";
import toast from "react-hot-toast";
import { sitesApi, queryKeys } from "@/api/endpoints";
import type { Site } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate } from "@/utils/formatDate";
import { FormDialog } from "@/components/common/FormDialog";

const siteSchema = z.object({
  name: z.string().min(1, "현장명을 입력하세요"),
  address: z.string().min(1, "주소를 입력하세요"),
  latitude: z.coerce.number(),
  longitude: z.coerce.number(),
  boundaryType: z.string().default("CIRCLE"),
  boundaryRadius: z.coerce.number().optional(),
});

type SiteFormData = z.infer<typeof siteSchema>;

export default function SiteManagement() {
  const queryClient = useQueryClient();
  const [dialogOpen, setDialogOpen] = useState(false);
  const mapRef = useRef<HTMLDivElement>(null);

  const { data, isLoading, isError } = useQuery({
    queryKey: queryKeys.dispatch.sites({ size: 100 }),
    queryFn: () => sitesApi.getAll({ size: 100 }),
  });

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    formState: { errors },
  } = useForm<SiteFormData>({
    resolver: zodResolver(siteSchema),
    defaultValues: { latitude: 37.5665, longitude: 126.978, boundaryType: "CIRCLE", boundaryRadius: 100 },
  });

  const createMutation = useMutation({
    mutationFn: (data: SiteFormData) => sitesApi.create(data),
    onSuccess: () => {
      toast.success("현장이 등록되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["dispatch", "sites"] });
      setDialogOpen(false);
      reset();
    },
    onError: () => toast.error("등록에 실패했습니다."),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => sitesApi.delete(id),
    onSuccess: () => {
      toast.success("현장이 삭제되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["dispatch", "sites"] });
    },
    onError: () => toast.error("삭제에 실패했습니다."),
  });

  // Initialize map in dialog
  useEffect(() => {
    if (!dialogOpen || !mapRef.current) return;

    let map: L.Map | null = null;

    const loadMap = async () => {
      const L = await import("leaflet");
      await import("leaflet/dist/leaflet.css");

      map = L.map(mapRef.current!, {
        center: [37.5665, 126.978],
        zoom: 12,
      });

      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution: "OpenStreetMap",
      }).addTo(map);

      map.on("click", (e: L.LeafletMouseEvent) => {
        setValue("latitude", e.latlng.lat);
        setValue("longitude", e.latlng.lng);
      });
    };

    loadMap();

    return () => {
      map?.remove();
    };
  }, [dialogOpen, setValue]);

  const columns = useMemo<ColumnDef<Site, unknown>[]>(
    () => [
      { accessorKey: "name", header: "현장명" },
      { accessorKey: "address", header: "주소" },
      { accessorKey: "companyName", header: "소속 업체" },
      {
        accessorKey: "active",
        header: "상태",
        cell: ({ getValue }) => (
          <StatusBadge status={getValue() ? "ACTIVE" : "INACTIVE"} />
        ),
      },
      {
        accessorKey: "createdAt",
        header: "등록일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        id: "actions",
        header: "작업",
        enableSorting: false,
        cell: ({ row }) => (
          <button
            type="button"
            onClick={() => {
              if (window.confirm("정말 삭제하시겠습니까?")) {
                deleteMutation.mutate(row.original.id);
              }
            }}
            className="rounded p-1.5 text-red-500 hover:bg-red-50 transition-colors"
            title="삭제"
          >
            <Trash2 className="h-4 w-4" />
          </button>
        ),
      },
    ],
    []
  );

  return (
    <div className="space-y-4 p-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">현장 관리</h1>
        <button
          type="button"
          onClick={() => setDialogOpen(true)}
          className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
        >
          <Plus className="h-4 w-4" />
          현장 등록
        </button>
      </div>

      <DataTable
        columns={columns}
        data={data?.content ?? []}
        isLoading={isLoading}
        isError={isError}
        searchPlaceholder="현장명, 주소 검색..."
      />

      <FormDialog
        open={dialogOpen}
        onClose={() => {
          setDialogOpen(false);
          reset();
        }}
        title="현장 등록"
        hideFooter
        className="max-w-2xl"
      >
        <form
          onSubmit={handleSubmit((d) => createMutation.mutate(d))}
          className="space-y-4"
        >
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
              지도에서 위치 선택
            </label>
            <div
              ref={mapRef}
              className="h-[250px] w-full rounded-lg border border-gray-200"
            />
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
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                경계 유형
              </label>
              <select
                {...register("boundaryType")}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              >
                <option value="CIRCLE">원형</option>
                <option value="POLYGON">다각형</option>
              </select>
            </div>
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
