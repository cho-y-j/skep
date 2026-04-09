import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import toast from "react-hot-toast";
import { Plus, ToggleLeft, ToggleRight } from "lucide-react";
import { companiesApi, queryKeys } from "@/api/endpoints";
import type { Company } from "@/types";
import { CompanyType, CompanyStatus } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { FormDialog } from "@/components/common/FormDialog";

const companySchema = z.object({
  name: z.string().min(1, "회사명을 입력하세요"),
  businessNumber: z.string().min(1, "사업자번호를 입력하세요"),
  representativeName: z.string().min(1, "대표자를 입력하세요"),
  type: z.nativeEnum(CompanyType),
  phone: z.string().min(1, "전화번호를 입력하세요"),
  email: z.string().email("유효한 이메일을 입력하세요"),
  address: z.string().min(1, "주소를 입력하세요"),
});

type CompanyFormValues = z.infer<typeof companySchema>;

export default function CompanyList() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [filterType, setFilterType] = useState<string>("");
  const [filterStatus, setFilterStatus] = useState<string>("");
  const queryClient = useQueryClient();

  const companiesQuery = useQuery({
    queryKey: queryKeys.companies.all({ size: 200 }),
    queryFn: () => companiesApi.getAll({ size: 200 }),
  });

  const createMutation = useMutation({
    mutationFn: (data: CompanyFormValues) => companiesApi.create(data),
    onSuccess: () => {
      toast.success("회사가 추가되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["companies"] });
      setDialogOpen(false);
      reset();
    },
    onError: () => toast.error("회사 추가에 실패했습니다."),
  });

  const statusMutation = useMutation({
    mutationFn: ({ id, status }: { id: string; status: string }) =>
      companiesApi.updateStatus(id, status),
    onSuccess: () => {
      toast.success("상태가 변경되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["companies"] });
    },
    onError: () => toast.error("상태 변경에 실패했습니다."),
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<CompanyFormValues>({
    resolver: zodResolver(companySchema),
    defaultValues: { type: CompanyType.SUPPLIER },
  });

  const filteredData = useMemo(() => {
    let data = companiesQuery.data?.content ?? [];
    if (filterType) data = data.filter((c) => c.type === filterType);
    if (filterStatus) data = data.filter((c) => c.status === filterStatus);
    return data;
  }, [companiesQuery.data, filterType, filterStatus]);

  const columns = useMemo<ColumnDef<Company, unknown>[]>(
    () => [
      { accessorKey: "name", header: "회사명" },
      { accessorKey: "businessNumber", header: "사업자번호" },
      {
        accessorKey: "type",
        header: "유형",
        cell: ({ getValue }) => (
          <span className="text-sm">
            {getValue() === "SUPPLIER" ? "공급사" : "BP"}
          </span>
        ),
      },
      { accessorKey: "representativeName", header: "대표자" },
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
          const company = row.original;
          const isActive = company.status === CompanyStatus.ACTIVE;
          return (
            <button
              type="button"
              onClick={() =>
                statusMutation.mutate({
                  id: company.id,
                  status: isActive
                    ? CompanyStatus.SUSPENDED
                    : CompanyStatus.ACTIVE,
                })
              }
              className={`inline-flex items-center gap-1 rounded px-2 py-1 text-xs font-medium transition-colors ${
                isActive
                  ? "text-red-700 hover:bg-red-50"
                  : "text-green-700 hover:bg-green-50"
              }`}
            >
              {isActive ? (
                <>
                  <ToggleRight className="h-3.5 w-3.5" />
                  정지
                </>
              ) : (
                <>
                  <ToggleLeft className="h-3.5 w-3.5" />
                  활성화
                </>
              )}
            </button>
          );
        },
      },
    ],
    [statusMutation]
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">회사 관리</h1>
        <button
          type="button"
          onClick={() => setDialogOpen(true)}
          className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
        >
          <Plus className="h-4 w-4" />
          회사 추가
        </button>
      </div>

      {/* Filters */}
      <div className="flex gap-3">
        <select
          value={filterType}
          onChange={(e) => setFilterType(e.target.value)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
        >
          <option value="">전체 유형</option>
          <option value="SUPPLIER">공급사</option>
          <option value="BP">BP</option>
        </select>
        <select
          value={filterStatus}
          onChange={(e) => setFilterStatus(e.target.value)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
        >
          <option value="">전체 상태</option>
          <option value="ACTIVE">활성</option>
          <option value="PENDING">대기</option>
          <option value="SUSPENDED">정지</option>
          <option value="INACTIVE">비활성</option>
        </select>
      </div>

      <DataTable
        columns={columns}
        data={filteredData}
        isLoading={companiesQuery.isLoading}
        isError={companiesQuery.isError}
        searchPlaceholder="회사명 또는 사업자번호 검색..."
      />

      <FormDialog
        open={dialogOpen}
        onClose={() => {
          setDialogOpen(false);
          reset();
        }}
        title="회사 추가"
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
              유형
            </label>
            <select
              {...register("type")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="SUPPLIER">공급사</option>
              <option value="BP">BP</option>
            </select>
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
