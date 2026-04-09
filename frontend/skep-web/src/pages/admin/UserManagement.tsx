import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import toast from "react-hot-toast";
import { Plus } from "lucide-react";
import { authApi, queryKeys } from "@/api/endpoints";
import type { User } from "@/types";
import { UserRole } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { FormDialog } from "@/components/common/FormDialog";
import { formatDate } from "@/utils/formatDate";

const userSchema = z.object({
  name: z.string().min(1, "이름을 입력하세요"),
  email: z.string().email("유효한 이메일을 입력하세요"),
  password: z.string().min(4, "비밀번호는 4자 이상이어야 합니다"),
  phone: z.string().min(1, "전화번호를 입력하세요"),
  role: z.nativeEnum(UserRole),
});

type UserFormValues = z.infer<typeof userSchema>;

const ROLE_OPTIONS: { value: UserRole; label: string }[] = [
  { value: UserRole.ADMIN, label: "관리자" },
  { value: UserRole.SUPPLIER, label: "공급사" },
  { value: UserRole.BP, label: "BP" },
  { value: UserRole.DRIVER, label: "운전원" },
  { value: UserRole.INSPECTOR, label: "점검관" },
  { value: UserRole.VIEWER, label: "열람자" },
];

export default function UserManagement() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const queryClient = useQueryClient();

  const usersQuery = useQuery({
    queryKey: queryKeys.auth.users(),
    queryFn: () => authApi.getUsers({ size: 100 }),
  });

  const createMutation = useMutation({
    mutationFn: (data: UserFormValues) => authApi.register(data),
    onSuccess: () => {
      toast.success("사용자가 추가되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["auth", "users"] });
      setDialogOpen(false);
      reset();
    },
    onError: () => {
      toast.error("사용자 추가에 실패했습니다.");
    },
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<UserFormValues>({
    resolver: zodResolver(userSchema),
    defaultValues: { role: UserRole.VIEWER },
  });

  const columns = useMemo<ColumnDef<User, unknown>[]>(
    () => [
      { accessorKey: "name", header: "이름" },
      { accessorKey: "email", header: "이메일" },
      {
        accessorKey: "role",
        header: "역할",
        cell: ({ getValue }) => <StatusBadge status={getValue() as string} />,
      },
      {
        accessorKey: "active",
        header: "상태",
        cell: ({ getValue }) => (
          <StatusBadge status={getValue() ? "ACTIVE" : "INACTIVE"} />
        ),
      },
      {
        accessorKey: "createdAt",
        header: "생성일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
    ],
    []
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">사용자 관리</h1>
        <button
          type="button"
          onClick={() => setDialogOpen(true)}
          className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
        >
          <Plus className="h-4 w-4" />
          사용자 추가
        </button>
      </div>

      <DataTable
        columns={columns}
        data={usersQuery.data?.content ?? []}
        isLoading={usersQuery.isLoading}
        isError={usersQuery.isError}
        searchPlaceholder="이름 또는 이메일 검색..."
      />

      <FormDialog
        open={dialogOpen}
        onClose={() => {
          setDialogOpen(false);
          reset();
        }}
        title="사용자 추가"
        onSave={handleSubmit((data) => createMutation.mutate(data))}
        isSaving={createMutation.isPending}
      >
        <form className="space-y-4" onSubmit={(e) => e.preventDefault()}>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              이름
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
              비밀번호
            </label>
            <input
              type="password"
              {...register("password")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            {errors.password && (
              <p className="mt-1 text-xs text-red-500">
                {errors.password.message}
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
              역할
            </label>
            <select
              {...register("role")}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              {ROLE_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
          </div>
        </form>
      </FormDialog>
    </div>
  );
}
