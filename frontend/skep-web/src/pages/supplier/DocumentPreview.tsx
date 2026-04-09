import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { FileText, Eye } from "lucide-react";
import { documentsApi, equipmentApi, queryKeys } from "@/api/endpoints";
import type { Document } from "@/types";
import { formatDate } from "@/utils/formatDate";
import { StatusBadge } from "@/components/common/StatusBadge";

export default function DocumentPreview() {
  const [ownerType, setOwnerType] = useState<"EQUIPMENT" | "PERSON">(
    "EQUIPMENT"
  );
  const [ownerId, setOwnerId] = useState("");
  const [selectedDoc, setSelectedDoc] = useState<Document | null>(null);

  const equipmentQuery = useQuery({
    queryKey: queryKeys.equipment.all({ size: 200 }),
    queryFn: () => equipmentApi.getAll({ size: 200 }),
  });

  const personsQuery = useQuery({
    queryKey: queryKeys.equipment.persons({ size: 200 }),
    queryFn: () => equipmentApi.getPersons({ size: 200 }),
  });

  const docsQuery = useQuery({
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

  const previewUrl = selectedDoc?.fileUrl ?? null;
  const isImage =
    previewUrl &&
    /\.(jpg|jpeg|png|gif|webp|bmp)$/i.test(previewUrl);
  const isPdf = previewUrl && /\.pdf$/i.test(previewUrl);

  return (
    <div className="space-y-4 p-6">
      <h1 className="text-2xl font-bold text-gray-900">서류 미리보기</h1>

      <div className="flex items-center gap-4">
        <select
          value={ownerType}
          onChange={(e) => {
            setOwnerType(e.target.value as "EQUIPMENT" | "PERSON");
            setOwnerId("");
            setSelectedDoc(null);
          }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
        >
          <option value="EQUIPMENT">장비</option>
          <option value="PERSON">인력</option>
        </select>
        <select
          value={ownerId}
          onChange={(e) => {
            setOwnerId(e.target.value);
            setSelectedDoc(null);
          }}
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

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2" style={{ minHeight: 500 }}>
        {/* Left panel: doc list */}
        <div className="rounded-xl border border-gray-200 bg-white">
          <div className="border-b border-gray-200 px-4 py-3">
            <h2 className="text-sm font-semibold text-gray-900">서류 목록</h2>
          </div>
          <div className="divide-y divide-gray-100">
            {docsQuery.isLoading && (
              <p className="px-4 py-8 text-center text-sm text-gray-500">
                불러오는 중...
              </p>
            )}
            {!ownerId && (
              <p className="px-4 py-8 text-center text-sm text-gray-400">
                장비 또는 인력을 선택하세요.
              </p>
            )}
            {ownerId &&
              !docsQuery.isLoading &&
              (docsQuery.data ?? []).length === 0 && (
                <p className="px-4 py-8 text-center text-sm text-gray-500">
                  서류가 없습니다.
                </p>
              )}
            {(docsQuery.data ?? []).map((doc: Document) => (
              <button
                key={doc.id}
                type="button"
                onClick={() => setSelectedDoc(doc)}
                className={`flex w-full items-center gap-3 px-4 py-3 text-left transition-colors hover:bg-gray-50 ${
                  selectedDoc?.id === doc.id ? "bg-blue-50" : ""
                }`}
              >
                <FileText className="h-5 w-5 shrink-0 text-gray-400" />
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium text-gray-900">
                    {doc.typeName}
                  </p>
                  <p className="truncate text-xs text-gray-500">
                    {doc.fileName}
                  </p>
                  <div className="mt-1 flex items-center gap-2">
                    <span className="text-xs text-gray-400">
                      {formatDate(doc.createdAt)}
                    </span>
                    <StatusBadge
                      status={doc.verified ? "APPROVED" : "PENDING"}
                    />
                  </div>
                </div>
                <Eye className="h-4 w-4 shrink-0 text-gray-300" />
              </button>
            ))}
          </div>
        </div>

        {/* Right panel: preview */}
        <div className="flex items-center justify-center rounded-xl border border-gray-200 bg-white">
          {!selectedDoc && (
            <p className="text-sm text-gray-400">
              서류를 선택하면 미리보기가 표시됩니다.
            </p>
          )}
          {selectedDoc && isImage && (
            <img
              src={selectedDoc.fileUrl}
              alt={selectedDoc.fileName}
              className="max-h-full max-w-full object-contain p-4"
            />
          )}
          {selectedDoc && isPdf && (
            <iframe
              src={selectedDoc.fileUrl}
              title={selectedDoc.fileName}
              className="h-full w-full"
            />
          )}
          {selectedDoc && !isImage && !isPdf && (
            <div className="text-center text-sm text-gray-500">
              <FileText className="mx-auto mb-2 h-12 w-12 text-gray-300" />
              <p>미리보기를 지원하지 않는 파일 형식입니다.</p>
              <a
                href={selectedDoc.fileUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="mt-2 inline-block text-blue-600 hover:underline"
              >
                다운로드
              </a>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
