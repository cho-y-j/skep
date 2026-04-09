import { useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { Trash2 } from "lucide-react";
import toast from "react-hot-toast";
import { equipmentApi, queryKeys } from "@/api/endpoints";
import type { Person } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { formatDate } from "@/utils/formatDate";

export default function PersonnelList() {
  const queryClient = useQueryClient();

  const { data, isLoading, isError } = useQuery({
    queryKey: queryKeys.equipment.persons({ size: 100 }),
    queryFn: () => equipmentApi.getPersons({ size: 100 }),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) =>
      equipmentApi.updatePerson(id, { active: false }),
    onSuccess: () => {
      toast.success("인력이 삭제되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["equipment", "persons"] });
    },
    onError: () => {
      toast.error("삭제에 실패했습니다.");
    },
  });

  const handleDelete = (id: string) => {
    if (window.confirm("정말 삭제하시겠습니까?")) {
      deleteMutation.mutate(id);
    }
  };

  const columns = useMemo<ColumnDef<Person, unknown>[]>(
    () => [
      { accessorKey: "name", header: "이름" },
      { accessorKey: "phone", header: "연락처" },
      { accessorKey: "role", header: "역할" },
      { accessorKey: "companyName", header: "소속" },
      { accessorKey: "equipmentName", header: "배정 장비" },
      {
        accessorKey: "active",
        header: "상태",
        cell: ({ getValue }) => (
          <span
            className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
              getValue()
                ? "bg-green-100 text-green-800"
                : "bg-gray-100 text-gray-600"
            }`}
          >
            {getValue() ? "활성" : "비활성"}
          </span>
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
            onClick={() => handleDelete(row.original.id)}
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
      <h1 className="text-2xl font-bold text-gray-900">인력 목록</h1>
      <DataTable
        columns={columns}
        data={data?.content ?? []}
        isLoading={isLoading}
        isError={isError}
        searchPlaceholder="이름, 연락처 검색..."
      />
    </div>
  );
}
