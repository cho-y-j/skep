import { useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { Trash2 } from "lucide-react";
import toast from "react-hot-toast";
import { equipmentApi, queryKeys } from "@/api/endpoints";
import type { Equipment } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate } from "@/utils/formatDate";

export default function EquipmentList() {
  const queryClient = useQueryClient();

  const { data, isLoading, isError } = useQuery({
    queryKey: queryKeys.equipment.all({ size: 100 }),
    queryFn: () => equipmentApi.getAll({ size: 100 }),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => equipmentApi.delete(id),
    onSuccess: () => {
      toast.success("장비가 삭제되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["equipment"] });
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

  const columns = useMemo<ColumnDef<Equipment, unknown>[]>(
    () => [
      { accessorKey: "name", header: "장비명" },
      { accessorKey: "typeName", header: "유형" },
      { accessorKey: "model", header: "모델" },
      { accessorKey: "manufacturer", header: "제조사" },
      { accessorKey: "year", header: "연식" },
      { accessorKey: "serialNumber", header: "일련번호" },
      {
        accessorKey: "status",
        header: "상태",
        cell: ({ getValue }) => (
          <StatusBadge status={getValue() as string} />
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
      <h1 className="text-2xl font-bold text-gray-900">장비 목록</h1>
      <DataTable
        columns={columns}
        data={data?.content ?? []}
        isLoading={isLoading}
        isError={isError}
        searchPlaceholder="장비명, 모델 검색..."
      />
    </div>
  );
}
