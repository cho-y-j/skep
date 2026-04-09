import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { authApi, queryKeys } from "@/api/endpoints";
import type { User } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate } from "@/utils/formatDate";
import { getStatusLabel } from "@/utils/statusLabels";

export default function EmployeeManagement() {
  const { data, isLoading, isError } = useQuery({
    queryKey: queryKeys.auth.users({ size: 100 }),
    queryFn: () => authApi.getUsers({ size: 100 }),
  });

  const columns = useMemo<ColumnDef<User, unknown>[]>(
    () => [
      { accessorKey: "name", header: "이름" },
      { accessorKey: "email", header: "이메일" },
      { accessorKey: "phone", header: "연락처" },
      {
        accessorKey: "role",
        header: "역할",
        cell: ({ getValue }) => getStatusLabel(getValue() as string),
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
        header: "등록일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
    ],
    []
  );

  return (
    <div className="space-y-4 p-6">
      <h1 className="text-2xl font-bold text-gray-900">직원 관리</h1>
      <DataTable
        columns={columns}
        data={data?.content ?? []}
        isLoading={isLoading}
        isError={isError}
        searchPlaceholder="이름, 이메일 검색..."
      />
    </div>
  );
}
