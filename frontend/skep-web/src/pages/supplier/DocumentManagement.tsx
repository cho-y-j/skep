import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { FileText, AlertTriangle } from "lucide-react";
import { documentsApi, equipmentApi, queryKeys } from "@/api/endpoints";
import type { Document } from "@/types";
import { formatDate } from "@/utils/formatDate";
import { StatusBadge } from "@/components/common/StatusBadge";

export default function DocumentManagement() {
  const [ownerType, setOwnerType] = useState<"EQUIPMENT" | "PERSON">(
    "EQUIPMENT"
  );
  const [ownerId, setOwnerId] = useState("");
  const [expiryDays, setExpiryDays] = useState(30);

  const equipmentQuery = useQuery({
    queryKey: queryKeys.equipment.all({ size: 200 }),
    queryFn: () => equipmentApi.getAll({ size: 200 }),
  });

  const personsQuery = useQuery({
    queryKey: queryKeys.equipment.persons({ size: 200 }),
    queryFn: () => equipmentApi.getPersons({ size: 200 }),
  });

  const expiringQuery = useQuery({
    queryKey: queryKeys.documents.expiring(expiryDays),
    queryFn: () => documentsApi.getExpiring(expiryDays),
  });

  const ownerDocsQuery = useQuery({
    queryKey: queryKeys.documents.byOwner(ownerType, ownerId),
    queryFn: () => documentsApi.getByOwner(ownerType, ownerId),
    enabled: !!ownerId,
  });

  const ownerOptions =
    ownerType === "EQUIPMENT"
      ? (equipmentQuery.data?.content ?? []).map((e) => ({
          id: e.id,
          label: e.name,
        }))
      : (personsQuery.data?.content ?? []).map((p) => ({
          id: p.id,
          label: p.name,
        }));

  return (
    <div className="space-y-6 p-6">
      <h1 className="text-2xl font-bold text-gray-900">서류 관리</h1>

      {/* Expiring documents section */}
      <div className="rounded-xl border border-gray-200 bg-white p-6">
        <div className="mb-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-amber-500" />
            <h2 className="text-lg font-semibold text-gray-900">
              만료 예정 서류
            </h2>
          </div>
          <select
            value={expiryDays}
            onChange={(e) => setExpiryDays(Number(e.target.value))}
            className="rounded-lg border border-gray-300 px-3 py-1.5 text-sm focus:border-blue-500 focus:outline-none"
          >
            <option value={7}>7일 이내</option>
            <option value={14}>14일 이내</option>
            <option value={30}>30일 이내</option>
            <option value={60}>60일 이내</option>
            <option value={90}>90일 이내</option>
          </select>
        </div>
        {expiringQuery.isLoading ? (
          <p className="text-sm text-gray-500">불러오는 중...</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase text-gray-600">
                    서류 유형
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase text-gray-600">
                    소유자
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase text-gray-600">
                    만료일
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase text-gray-600">
                    검증
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {(expiringQuery.data ?? []).map((doc: Document) => (
                  <tr key={doc.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-gray-900">{doc.typeName}</td>
                    <td className="px-4 py-3 text-gray-700">{doc.ownerName}</td>
                    <td className="px-4 py-3 text-amber-600">
                      {formatDate(doc.expiryDate)}
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge
                        status={doc.verified ? "APPROVED" : "PENDING"}
                      />
                    </td>
                  </tr>
                ))}
                {(expiringQuery.data ?? []).length === 0 && (
                  <tr>
                    <td
                      colSpan={4}
                      className="py-8 text-center text-gray-500"
                    >
                      만료 예정 서류가 없습니다.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Owner-based document search */}
      <div className="rounded-xl border border-gray-200 bg-white p-6">
        <div className="mb-4 flex items-center gap-2">
          <FileText className="h-5 w-5 text-gray-500" />
          <h2 className="text-lg font-semibold text-gray-900">
            장비/인력별 서류 조회
          </h2>
        </div>
        <div className="mb-4 flex items-center gap-4">
          <select
            value={ownerType}
            onChange={(e) => {
              setOwnerType(e.target.value as "EQUIPMENT" | "PERSON");
              setOwnerId("");
            }}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
          >
            <option value="EQUIPMENT">장비</option>
            <option value="PERSON">인력</option>
          </select>
          <select
            value={ownerId}
            onChange={(e) => setOwnerId(e.target.value)}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
          >
            <option value="">선택하세요</option>
            {ownerOptions.map((o) => (
              <option key={o.id} value={o.id}>
                {o.label}
              </option>
            ))}
          </select>
        </div>
        {ownerId && ownerDocsQuery.isLoading && (
          <p className="text-sm text-gray-500">불러오는 중...</p>
        )}
        {ownerId && !ownerDocsQuery.isLoading && (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase text-gray-600">
                    서류 유형
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase text-gray-600">
                    파일명
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase text-gray-600">
                    만료일
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase text-gray-600">
                    검증
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase text-gray-600">
                    등록일
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {(ownerDocsQuery.data ?? []).map((doc: Document) => (
                  <tr key={doc.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-gray-900">{doc.typeName}</td>
                    <td className="px-4 py-3 text-gray-700">{doc.fileName}</td>
                    <td className="px-4 py-3 text-gray-700">
                      {formatDate(doc.expiryDate)}
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge
                        status={doc.verified ? "APPROVED" : "PENDING"}
                      />
                    </td>
                    <td className="px-4 py-3 text-gray-500">
                      {formatDate(doc.createdAt)}
                    </td>
                  </tr>
                ))}
                {(ownerDocsQuery.data ?? []).length === 0 && (
                  <tr>
                    <td
                      colSpan={5}
                      className="py-8 text-center text-gray-500"
                    >
                      서류가 없습니다.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
