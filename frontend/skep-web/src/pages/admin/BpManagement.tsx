import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import toast from "react-hot-toast";
import { Plus, ChevronDown, ChevronRight, MapPin } from "lucide-react";
import { companiesApi, sitesApi, queryKeys } from "@/api/endpoints";
import type { Company, Site } from "@/types";
import { CompanyType } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { FormDialog } from "@/components/common/FormDialog";

const bpSchema = z.object({
  name: z.string().min(1, "회사명을 입력하세요"),
  businessNumber: z.string().min(1, "사업자번호를 입력하세요"),
  representativeName: z.string().min(1, "대표자를 입력하세요"),
  phone: z.string().min(1, "전화번호를 입력하세요"),
  email: z.string().email("유효한 이메일을 입력하세요"),
  address: z.string().min(1, "주소를 입력하세요"),
});

type BpFormValues = z.infer<typeof bpSchema>;

function BpSitesRow({ companyId }: { companyId: string }) {
  const sitesQuery = useQuery({
    queryKey: queryKeys.dispatch.sites({ companyId, size: 50 }),
    queryFn: () => sitesApi.getAll({ companyId, size: 50 }),
  });

  const sites = sitesQuery.data?.content ?? [];

  if (sitesQuery.isLoading) {
    return (
      <div className="px-8 py-3 text-sm text-gray-500">불러오는 중...</div>
    );
  }

  if (sites.length === 0) {
    return (
      <div className="px-8 py-3 text-sm text-gray-400">
        등록된 현장이 없습니다.
      </div>
    );
  }

  return (
    <div className="bg-gray-50 px-8 py-3">
      <p className="mb-2 text-xs font-semibold uppercase text-gray-500">
        현장 목록
      </p>
      <ul className="space-y-1">
        {sites.map((site: Site) => (
          <li
            key={site.id}
            className="flex items-center gap-2 text-sm text-gray-700"
          >
            <MapPin className="h-3.5 w-3.5 text-gray-400" />
            <span className="font-medium">{site.name}</span>
            <span className="text-gray-400">-</span>
            <span className="text-gray-500">{site.address}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default function BpManagement() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const queryClient = useQueryClient();

  const bpQuery = useQuery({
    queryKey: queryKeys.companies.byType(CompanyType.BP),
    queryFn: () => companiesApi.getByType(CompanyType.BP, { size: 200 }),
  });

  const createMutation = useMutation({
    mutationFn: (data: BpFormValues) =>
      companiesApi.create({ ...data, type: CompanyType.BP }),
    onSuccess: () => {
      toast.success("BP사가 등록되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["companies"] });
      setDialogOpen(false);
      reset();
    },
    onError: () => toast.error("BP사 등록에 실패했습니다."),
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<BpFormValues>({ resolver: zodResolver(bpSchema) });

  const columns = useMemo<ColumnDef<Company, unknown>[]>(
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
      { accessorKey: "name", header: "BP사명" },
      { accessorKey: "businessNumber", header: "사업자번호" },
      { accessorKey: "representativeName", header: "대표자" },
      { accessorKey: "phone", header: "연락처" },
      {
        accessorKey: "status",
        header: "상태",
        cell: ({ getValue }) => <StatusBadge status={getValue() as string} />,
      },
    ],
    [expandedId]
  );

  const bpList = bpQuery.data?.content ?? [];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">BP사 관리</h1>
        <button
          type="button"
          onClick={() => setDialogOpen(true)}
          className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
        >
          <Plus className="h-4 w-4" />
          BP사 등록
        </button>
      </div>

      <DataTable
        columns={columns}
        data={bpList}
        isLoading={bpQuery.isLoading}
        isError={bpQuery.isError}
        searchPlaceholder="BP사명 검색..."
      />

      {/* Expandable site rows rendered below the table */}
      {expandedId && <BpSitesRow companyId={expandedId} />}

      <FormDialog
        open={dialogOpen}
        onClose={() => {
          setDialogOpen(false);
          reset();
        }}
        title="BP사 등록"
        onSave={handleSubmit((data) => createMutation.mutate(data))}
        isSaving={createMutation.isPending}
      >
        <form className="space-y-4" onSubmit={(e) => e.preventDefault()}>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              회사명
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
              사업자번호
            </label>
            <input
              {...register("businessNumber")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.businessNumber && (
              <p className="mt-1 text-xs text-red-500">
                {errors.businessNumber.message}
              </p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              대표자
            </label>
            <input
              {...register("representativeName")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.representativeName && (
              <p className="mt-1 text-xs text-red-500">
                {errors.representativeName.message}
              </p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              전화번호
            </label>
            <input
              {...register("phone")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.phone && (
              <p className="mt-1 text-xs text-red-500">
                {errors.phone.message}
              </p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              이메일
            </label>
            <input
              type="email"
              {...register("email")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.email && (
              <p className="mt-1 text-xs text-red-500">
                {errors.email.message}
              </p>
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
        </form>
      </FormDialog>
    </div>
  );
}
