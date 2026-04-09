import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { type ColumnDef } from "@tanstack/react-table";
import { ShieldCheck, ShieldX } from "lucide-react";
import toast from "react-hot-toast";
import { documentsApi, queryKeys } from "@/api/endpoints";
import type { Document } from "@/types";
import { DataTable } from "@/components/common/DataTable";
import { StatusBadge } from "@/components/common/StatusBadge";
import { formatDate } from "@/utils/formatDate";

type TabKey = "license" | "business" | "cargo" | "batch";

const TABS: { key: TabKey; label: string; ownerType: string }[] = [
  { key: "license", label: "면허 검증", ownerType: "LICENSE" },
  { key: "business", label: "사업자 검증", ownerType: "BUSINESS" },
  { key: "cargo", label: "화물 검증", ownerType: "CARGO" },
  { key: "batch", label: "일괄 검증", ownerType: "BATCH" },
];

export default function Verification() {
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState<TabKey>("license");

  const expiringQuery = useQuery({
    queryKey: queryKeys.documents.expiring(365),
    queryFn: () => documentsApi.getExpiring(365),
  });

  const verifyMutation = useMutation({
    mutationFn: (id: string) => documentsApi.verify(id),
    onSuccess: () => {
      toast.success("검증이 완료되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["documents"] });
    },
    onError: () => {
      toast.error("검증에 실패했습니다.");
    },
  });

  const unverifyMutation = useMutation({
    mutationFn: (id: string) => documentsApi.unverify(id),
    onSuccess: () => {
      toast.success("검증이 해제되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["documents"] });
    },
    onError: () => {
      toast.error("검증 해제에 실패했습니다.");
    },
  });

  const filteredDocs = useMemo(() => {
    const docs = expiringQuery.data ?? [];
    const currentTab = TABS.find((t) => t.key === activeTab);
    if (activeTab === "batch") return docs;
    return docs.filter((d) =>
      d.typeName.toLowerCase().includes(currentTab?.ownerType.toLowerCase() ?? "")
    );
  }, [expiringQuery.data, activeTab]);

  const columns = useMemo<ColumnDef<Document, unknown>[]>(
    () => [
      { accessorKey: "typeName", header: "서류 유형" },
      { accessorKey: "ownerName", header: "소유자" },
      { accessorKey: "fileName", header: "파일명" },
      {
        accessorKey: "expiryDate",
        header: "만료일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        accessorKey: "verified",
        header: "검증 상태",
        cell: ({ getValue }) => (
          <StatusBadge status={getValue() ? "APPROVED" : "PENDING"} />
        ),
      },
      {
        accessorKey: "verifiedAt",
        header: "검증일",
        cell: ({ getValue }) => formatDate(getValue() as string),
      },
      {
        id: "actions",
        header: "작업",
        enableSorting: false,
        cell: ({ row }) => (
          <div className="flex items-center gap-1">
            {!row.original.verified ? (
              <button
                type="button"
                onClick={() => verifyMutation.mutate(row.original.id)}
                className="flex items-center gap-1 rounded-lg bg-green-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-green-700 transition-colors"
              >
                <ShieldCheck className="h-3.5 w-3.5" />
                검증
              </button>
            ) : (
              <button
                type="button"
                onClick={() => unverifyMutation.mutate(row.original.id)}
                className="flex items-center gap-1 rounded-lg bg-red-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-red-700 transition-colors"
              >
                <ShieldX className="h-3.5 w-3.5" />
                해제
              </button>
            )}
          </div>
        ),
      },
    ],
    []
  );

  return (
    <div className="space-y-4 p-6">
      <h1 className="text-2xl font-bold text-gray-900">서류 검증</h1>

      {/* Tabs */}
      <div className="flex border-b border-gray-200">
        {TABS.map((tab) => (
          <button
            key={tab.key}
            type="button"
            onClick={() => setActiveTab(tab.key)}
            className={`px-4 py-2 text-sm font-medium transition-colors ${
              activeTab === tab.key
                ? "border-b-2 border-blue-600 text-blue-600"
                : "text-gray-500 hover:text-gray-700"
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <DataTable
        columns={columns}
        data={filteredDocs}
        isLoading={expiringQuery.isLoading}
        isError={expiringQuery.isError}
        searchPlaceholder="서류, 소유자 검색..."
      />
    </div>
  );
}
