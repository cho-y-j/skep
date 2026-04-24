// 장비 공급사 서류 검증 페이지 (Step 1)
// - 공급사 선택 → 소속 장비/인원의 서류 전체 나열
// - 각 서류: 썸네일 + 카테고리 + 검증 상태 + [OCR 검증] / [직접 전환] 버튼
// - 완료 시 Step 2 작업계획서 생성으로 이동
import { useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import toast from "react-hot-toast";
import { ShieldCheck, CheckCircle2, CircleAlert, Loader2, ArrowRight, Upload } from "lucide-react";
import client from "@/api/client";
import { companiesApi, equipmentApi, documentsApi } from "@/api/endpoints";
import { CompanyType } from "@/types";
import { AuthImage } from "@/components/common/AuthImage";

interface DocItem {
  id: string;
  ownerId: string;
  ownerType: "EQUIPMENT" | "PERSON";
  ownerLabel: string;
  category: string;
  documentTypeId: string;
  fileName: string;
  verified: boolean;
  status: string;
  createdAt: string;
}

async function fetchAllDocsForSupplier(supplierId: string): Promise<DocItem[]> {
  // equipment + persons 병렬로 가져와서 서류 합치기
  const [eqs, persons] = await Promise.all([
    equipmentApi.getAll({ supplier_id: supplierId } as any),
    equipmentApi.getPersons({ supplier_id: supplierId } as any),
  ]);
  const eqList: any[] = Array.isArray(eqs) ? eqs : (eqs as any)?.content ?? [];
  const personList: any[] = Array.isArray(persons) ? persons : (persons as any)?.content ?? [];

  const docPromises: Promise<DocItem[]>[] = [];
  for (const e of eqList) {
    docPromises.push(
      documentsApi
        .getByOwner("EQUIPMENT", e.id)
        .then((docs: any[]) =>
          (docs || []).map((d: any) => ({
            id: d.id,
            ownerId: e.id,
            ownerType: "EQUIPMENT" as const,
            ownerLabel: `장비 · ${e.vehicle_number || e.vehicleNumber || e.model_name || "(무명)"}`,
            category: d.document_type_name ?? d.typeName ?? "서류",
            documentTypeId: d.document_type_id ?? d.typeId ?? "",
            fileName: d.original_filename ?? d.fileName ?? "",
            verified: !!d.verified,
            status: d.status ?? "PENDING",
            createdAt: d.created_at ?? d.createdAt ?? "",
          })),
        )
        .catch(() => []),
    );
  }
  for (const p of personList) {
    const typeLabel: Record<string, string> = { DRIVER: "조종원", GUIDE: "유도원", SAFETY_INSPECTOR: "점검원" };
    const pt = p.person_type ?? p.personType ?? "";
    docPromises.push(
      documentsApi
        .getByOwner("PERSON", p.id)
        .then((docs: any[]) =>
          (docs || []).map((d: any) => ({
            id: d.id,
            ownerId: p.id,
            ownerType: "PERSON" as const,
            ownerLabel: `${typeLabel[pt] || pt || "인원"} · ${p.name}`,
            category: d.document_type_name ?? d.typeName ?? "서류",
            documentTypeId: d.document_type_id ?? d.typeId ?? "",
            fileName: d.original_filename ?? d.fileName ?? "",
            verified: !!d.verified,
            status: d.status ?? "PENDING",
            createdAt: d.created_at ?? d.createdAt ?? "",
          })),
        )
        .catch(() => []),
    );
  }
  const all = (await Promise.all(docPromises)).flat();
  return all.sort((a, b) => a.ownerLabel.localeCompare(b.ownerLabel));
}

export default function SupplierDocVerification() {
  const qc = useQueryClient();
  const [supplierId, setSupplierId] = useState<string>("");
  const [filter, setFilter] = useState<"all" | "unverified" | "verified">("all");
  const [ownerFilter, setOwnerFilter] = useState<string>("__all__"); // ownerId or __all__
  const [previewDoc, setPreviewDoc] = useState<DocItem | null>(null);
  const [ocrDoc, setOcrDoc] = useState<DocItem | null>(null);
  const [ocrFields, setOcrFields] = useState<Record<string, string>>({});
  const [ocrLoading, setOcrLoading] = useState(false);
  const [verifyResult, setVerifyResult] = useState<any>(null);
  const [verifyRunning, setVerifyRunning] = useState(false);
  const [uploadOpen, setUploadOpen] = useState(false);
  const [uploadForm, setUploadForm] = useState<{
    ownerType: "EQUIPMENT" | "PERSON";
    ownerId: string;
    typeId: string;
    file: File | null;
  }>({ ownerType: "EQUIPMENT", ownerId: "", typeId: "", file: null });

  const suppliersQuery = useQuery({
    queryKey: ["companies", "type", CompanyType.SUPPLIER],
    queryFn: () => companiesApi.getByType(CompanyType.SUPPLIER, { size: 500 }),
  });
  const suppliers = useMemo(() => {
    const raw = suppliersQuery.data as any;
    return (Array.isArray(raw) ? raw : raw?.content ?? []) as any[];
  }, [suppliersQuery.data]);

  const docsQuery = useQuery({
    queryKey: ["supplier-docs", supplierId],
    queryFn: () => fetchAllDocsForSupplier(supplierId),
    enabled: !!supplierId,
  });

  // 업로드 다이얼로그용 — 공급사의 장비 + 인원 목록, 서류 유형 목록
  const equipsQuery = useQuery({
    queryKey: ["supplier-equips-list", supplierId],
    queryFn: () => equipmentApi.getAll({ supplier_id: supplierId } as any),
    enabled: !!supplierId,
  });
  const personsQuery = useQuery({
    queryKey: ["supplier-persons-list", supplierId],
    queryFn: () => equipmentApi.getPersons({ supplier_id: supplierId } as any),
    enabled: !!supplierId,
  });
  const docTypesQuery = useQuery({
    queryKey: ["doc-types"],
    queryFn: () => documentsApi.getTypes(),
  });

  const uploadMut = useMutation({
    mutationFn: async (f: typeof uploadForm) => {
      if (!f.file || !f.ownerId || !f.typeId) throw new Error("모두 선택해주세요");
      const fd = new FormData();
      fd.append("file", f.file);
      fd.append("owner_id", f.ownerId);
      fd.append("owner_type", f.ownerType);
      fd.append("document_type_id", f.typeId);
      return client.post("/api/documents/upload", fd, {
        headers: { "Content-Type": "multipart/form-data" },
      });
    },
    onSuccess: () => {
      toast.success("업로드 완료");
      setUploadOpen(false);
      setUploadForm({ ownerType: "EQUIPMENT", ownerId: "", typeId: "", file: null });
      qc.invalidateQueries({ queryKey: ["supplier-docs", supplierId] });
    },
    onError: (e: any) => toast.error(e?.message || "업로드 실패"),
  });

  // 카테고리로 실제 verify 엔드포인트 선택
  const resolveVerifyEndpoint = (category: string): { path: string; fields: string[] } | null => {
    if (category.includes("운전면허") || category.includes("조종사면허"))
      return { path: "/api/documents/verify/driver-license", fields: ["licenseNumber", "name", "licenseTypeCode"] };
    if (category.includes("사업자"))
      return { path: "/api/documents/verify/business-registration", fields: ["businessNumber"] };
    if (category.includes("화물운송"))
      return { path: "/api/documents/verify/cargo", fields: ["name", "birth", "lcnsNo"] };
    return null;
  };

  // 마스킹된 base64 이미지를 업로드 + 기존 doc 삭제 → 해당 서류 파일을 마스킹본으로 교체
  // (워크시트도 doc.id로 AuthImage를 불러오므로 교체 후 자동으로 마스킹본이 표시됨)
  const replaceDocWithMasked = async (doc: DocItem, b64: string): Promise<DocItem> => {
    const bin = atob(b64);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    const blob = new Blob([bytes], { type: "image/png" });
    const nameBase = (doc.fileName || "document").replace(/\.[^.]+$/, "");
    const fd = new FormData();
    fd.append("file", blob, `${nameBase}_masked.png`);
    fd.append("owner_id", doc.ownerId);
    fd.append("owner_type", doc.ownerType);
    fd.append("document_type_id", doc.documentTypeId);
    const resp: any = await client.post("/api/documents/upload", fd, {
      headers: { "Content-Type": "multipart/form-data" },
    });
    await client.delete(`/api/documents/${doc.id}`);
    const newId = resp?.id || resp?.data?.id || doc.id;
    const newDoc: DocItem = { ...doc, id: newId, fileName: `${nameBase}_masked.png` };
    qc.invalidateQueries({ queryKey: ["supplier-docs", supplierId] });
    return newDoc;
  };

  // 실제 OCR 실행 — 서버가 파일 읽어서 Google Vision으로 추출
  // 운전면허 등은 verify-api가 maskedImageBase64도 함께 반환 → 자동 교체
  const runOcrAutoExtract = async () => {
    if (!ocrDoc) return;
    setOcrLoading(true);
    try {
      const res: any = await client.post(`/api/documents/${ocrDoc.id}/run-ocr`);
      const flat: Record<string, string> = {};
      let maskedB64: string | null = null;
      Object.entries(res || {}).forEach(([k, v]) => {
        if (k === "maskedImageBase64") { maskedB64 = v as string; return; }
        flat[k] = v == null ? "" : String(v);
      });
      setOcrFields(flat);
      toast.success(`OCR 추출 완료: ${Object.keys(flat).length}개 필드`);

      if (maskedB64) {
        try {
          const newDoc = await replaceDocWithMasked(ocrDoc, maskedB64);
          setOcrDoc(newDoc);
          toast.success("주민번호 마스킹 이미지로 교체 완료");
        } catch (err: any) {
          toast.error("마스킹 교체 실패: " + (err?.message || ""));
        }
      }
    } catch (e: any) {
      toast.error(e?.response?.data?.message || "OCR 추출 실패");
    } finally {
      setOcrLoading(false);
    }
  };

  const runRealVerify = async () => {
    if (!ocrDoc) return;
    const ep = resolveVerifyEndpoint(ocrDoc.category);
    if (!ep) {
      toast.error(`"${ocrDoc.category}" 유형은 실제 검증 대상이 아닙니다. 직접 검증 처리를 사용하세요.`);
      return;
    }
    // fields 매핑: OCR 필드 이름(camelCase) → verify API 요구 이름
    const aliasMap: Record<string, string[]> = {
      licenseNumber: ["licenseNumber", "licenseNo", "license_number", "DL", "registrationNumber"],
      name: ["name", "ownerName", "holderName"],
      businessNumber: ["businessNumber", "bizNo", "business_number", "businessRegistrationNumber"],
      birth: ["birth", "birthDate", "dateOfBirth"],
      lcnsNo: ["lcnsNo", "licenseNo", "licenseNumber", "certificateNo"],
      licenseTypeCode: ["licenseTypeCode", "licenseConditionCode", "f_licn_con_code"],
    };
    const body: Record<string, string> = {};
    for (const want of ep.fields) {
      const candidates = aliasMap[want] || [want];
      for (const c of candidates) {
        if (ocrFields[c]) { body[want] = ocrFields[c]; break; }
      }
    }
    // licenseTypeCode는 누락 허용 (기본값 서버에서 처리)
    const requiredOnly = ep.fields.filter((f) => f !== "licenseTypeCode");
    const missing = requiredOnly.filter((f) => !body[f]);
    if (missing.length) {
      toast.error(`필수 필드 누락: ${missing.join(", ")}`);
      return;
    }
    setVerifyRunning(true);
    setVerifyResult(null);
    try {
      const res: any = await client.post(ep.path, body);
      setVerifyResult(res?.data || res);
    } catch (e: any) {
      setVerifyResult({ valid: false, message: e?.response?.data?.message || String(e) });
    } finally {
      setVerifyRunning(false);
    }
  };

  // OCR 결과 조회 (편집 다이얼로그 열기)
  const openOcrReview = async (doc: DocItem) => {
    setOcrDoc(doc);
    setVerifyResult(null);
    setOcrLoading(true);
    try {
      const res: any = await client.get(`/api/documents/${doc.id}/ocr-result`);
      const raw = res?.ocrResult ?? {};
      // extractedFields 있으면 그걸 쓰고, 없으면 최상위 그대로
      const fields = raw?.extractedFields ?? (typeof raw === "object" ? raw : {});
      const flat: Record<string, string> = {};
      Object.entries(fields || {}).forEach(([k, v]) => {
        flat[k] = v == null ? "" : String(v);
      });
      setOcrFields(flat);
    } catch (e: any) {
      toast.error(e?.response?.data?.message || "OCR 결과 조회 실패");
    } finally {
      setOcrLoading(false);
    }
  };

  const saveOcrMut = useMutation({
    mutationFn: (args: { doc: DocItem; fields: Record<string, string>; verified: boolean }) =>
      client.post(`/api/documents/${args.doc.id}/save-ocr`, {
        ocrResult: { extractedFields: args.fields, manuallyEdited: true },
        verified: args.verified,
      }),
    onSuccess: () => {
      toast.success("OCR 검증 저장 완료");
      setOcrDoc(null);
      qc.invalidateQueries({ queryKey: ["supplier-docs", supplierId] });
    },
    onError: (e: any) => toast.error(e?.response?.data?.message || "저장 실패"),
  });

  // 사진 교체 — 기존 DELETE + 같은 owner/type으로 새 파일 upload
  const replaceMut = useMutation({
    mutationFn: async (args: { doc: DocItem; file: File }) => {
      const fd = new FormData();
      fd.append("file", args.file);
      fd.append("owner_id", args.doc.ownerId);
      fd.append("owner_type", args.doc.ownerType);
      fd.append("document_type_id", args.doc.documentTypeId);
      // upload 먼저 (실패하면 기존 유지)
      await client.post("/api/documents/upload", fd, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      // 기존 doc 삭제
      await client.delete(`/api/documents/${args.doc.id}`);
    },
    onSuccess: () => {
      toast.success("사진 교체 완료");
      qc.invalidateQueries({ queryKey: ["supplier-docs", supplierId] });
    },
    onError: (e: any) => toast.error(e?.message || "교체 실패"),
  });

  const markVerifiedMut = useMutation({
    mutationFn: (args: { id: string; verified: boolean }) =>
      client.post(`/api/documents/${args.id}/mark-verified`, { verified: args.verified }),
    onSuccess: () => {
      toast.success("상태 변경 완료");
      qc.invalidateQueries({ queryKey: ["supplier-docs", supplierId] });
    },
  });

  const docs = docsQuery.data ?? [];
  // owner 목록 (ownerId → 라벨)
  const ownerList = useMemo(() => {
    const map = new Map<string, { ownerId: string; ownerType: "EQUIPMENT" | "PERSON"; label: string; count: number }>();
    for (const d of docs) {
      const key = d.ownerType + ":" + d.ownerId;
      const prev = map.get(key);
      if (prev) prev.count += 1;
      else map.set(key, { ownerId: d.ownerId, ownerType: d.ownerType, label: d.ownerLabel, count: 1 });
    }
    return [...map.values()].sort((a, b) => a.label.localeCompare(b.label));
  }, [docs]);

  const visible = docs.filter((d) => {
    if (ownerFilter !== "__all__" && d.ownerId !== ownerFilter) return false;
    if (filter === "verified") return d.verified;
    if (filter === "unverified") return !d.verified;
    return true;
  });
  const verifiedCount = visible.filter((d) => d.verified).length;
  const unverifiedCount = visible.length - verifiedCount;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-2">
        <div className="flex items-center gap-2">
          <ShieldCheck className="h-5 w-5 text-indigo-600" />
          <h1 className="text-2xl font-bold text-gray-900">
            <span className="text-xs text-indigo-500 block">Step 1</span>
            공급사 서류 검증
          </h1>
        </div>
        <Link
          to="/worksheet/new"
          className="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-indigo-600 text-white text-sm hover:bg-indigo-700"
        >
          검증 완료 · 작업계획서 생성으로
          <ArrowRight className="h-4 w-4" />
        </Link>
      </div>

      {/* Supplier picker */}
      <div className="rounded-xl border border-gray-200 bg-white p-4">
        <label className="block text-xs font-medium text-gray-600 mb-1">
          장비 공급사 선택 ({suppliers.length}개)
        </label>
        <select
          value={supplierId}
          onChange={(e) => { setSupplierId(e.target.value); setOwnerFilter("__all__"); }}
          className="w-full max-w-md rounded-lg border border-gray-300 px-3 py-2 text-sm"
        >
          <option value="">-- 공급사 선택 --</option>
          {suppliers.map((s: any) => (
            <option key={s.id} value={s.id}>
              {s.name}
              {s.businessNumber ? ` · ${s.businessNumber}` : ""}
            </option>
          ))}
        </select>
      </div>

      {supplierId && (
        <>
          {/* Summary + Filter */}
          <div className="flex items-center gap-3 flex-wrap">
            <div className="rounded-lg bg-white border border-gray-200 px-4 py-2 text-sm">
              <span className="text-gray-500">총 </span>
              <b>{visible.length}</b>
              <span className="text-gray-500"> 건 · 검증 </span>
              <b className="text-emerald-600">{verifiedCount}</b>
              <span className="text-gray-500"> / 미검증 </span>
              <b className="text-amber-600">{unverifiedCount}</b>
              <span className="text-[10px] text-gray-400 ml-2">(전체 {docs.length})</span>
            </div>
            <select
              value={ownerFilter}
              onChange={(e) => setOwnerFilter(e.target.value)}
              className="rounded-md border border-gray-300 px-3 py-1.5 text-xs bg-white max-w-xs"
            >
              <option value="__all__">— 인원/장비 전체 보기 ({ownerList.length}건)</option>
              <optgroup label="장비">
                {ownerList.filter(o => o.ownerType === "EQUIPMENT").map(o => (
                  <option key={o.ownerId} value={o.ownerId}>{o.label} ({o.count}개 서류)</option>
                ))}
              </optgroup>
              <optgroup label="인원">
                {ownerList.filter(o => o.ownerType === "PERSON").map(o => (
                  <option key={o.ownerId} value={o.ownerId}>{o.label} ({o.count}개 서류)</option>
                ))}
              </optgroup>
            </select>
            <div className="flex gap-1 text-xs">
              {(["all", "unverified", "verified"] as const).map((k) => (
                <button
                  key={k}
                  onClick={() => setFilter(k)}
                  className={`px-3 py-1.5 rounded-md border ${
                    filter === k
                      ? "bg-indigo-600 text-white border-indigo-600"
                      : "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                  }`}
                >
                  {k === "all" ? "전체" : k === "unverified" ? "미검증만" : "검증됨만"}
                </button>
              ))}
            </div>
            {docsQuery.isFetching && <Loader2 className="h-4 w-4 animate-spin text-indigo-500" />}
            <button
              onClick={() => setUploadOpen(true)}
              className="ml-auto inline-flex items-center gap-1.5 px-3 py-1.5 rounded-md bg-emerald-600 text-white text-xs hover:bg-emerald-700"
            >
              <Upload className="h-3.5 w-3.5" />
              서류 업로드
            </button>
          </div>

          {/* Docs grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">
            {visible.map((d) => (
              <div
                key={d.id}
                className={`rounded-xl border bg-white p-3 flex gap-3 ${
                  d.verified ? "border-emerald-200" : "border-amber-300"
                }`}
              >
                <div
                  className="w-28 h-28 shrink-0 overflow-hidden rounded-lg bg-gray-100 cursor-zoom-in"
                  onClick={() => setPreviewDoc(d)}
                  title="클릭하면 크게 보기"
                >
                  <AuthImage docId={d.id} alt={d.category} className="w-full h-full object-cover" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-xs text-gray-500 truncate">{d.ownerLabel}</div>
                  <div className="text-sm font-semibold text-gray-900 truncate">{d.category}</div>
                  <div className="text-[10px] text-gray-400 truncate">{d.fileName}</div>
                  <div className="mt-1 flex items-center gap-1.5">
                    {d.verified ? (
                      <>
                        <CheckCircle2 className="h-4 w-4 text-emerald-500" />
                        <span className="text-xs font-medium text-emerald-700">검증됨</span>
                      </>
                    ) : (
                      <>
                        <CircleAlert className="h-4 w-4 text-amber-500" />
                        <span className="text-xs font-medium text-amber-700">미검증</span>
                      </>
                    )}
                  </div>
                  <div className="mt-2 flex flex-wrap gap-1.5">
                    <button
                      onClick={() => openOcrReview(d)}
                      className="text-xs px-2 py-1 rounded-md bg-indigo-600 text-white hover:bg-indigo-700"
                    >
                      OCR 결과 보기 · 편집
                    </button>
                    {!d.verified && (
                      <button
                        onClick={() => markVerifiedMut.mutate({ id: d.id, verified: true })}
                        disabled={markVerifiedMut.isPending}
                        className="text-xs px-2 py-1 rounded-md border border-emerald-500 text-emerald-700 hover:bg-emerald-50 disabled:opacity-50"
                      >
                        직접 검증 처리
                      </button>
                    )}
                    {d.verified && (
                      <button
                        onClick={() => markVerifiedMut.mutate({ id: d.id, verified: false })}
                        disabled={markVerifiedMut.isPending}
                        className="text-xs px-2 py-1 rounded-md border border-gray-300 text-gray-600 hover:bg-gray-50 disabled:opacity-50"
                      >
                        검증 취소
                      </button>
                    )}
                    {/* 사진 교체 — 모든 상태에서 가능 */}
                    <label className="text-xs px-2 py-1 rounded-md border border-indigo-300 text-indigo-700 hover:bg-indigo-50 cursor-pointer">
                      사진 교체
                      <input
                        type="file"
                        accept=".jpg,.jpeg,.png,.pdf"
                        className="hidden"
                        onChange={(e) => {
                          const f = e.target.files?.[0];
                          if (f) replaceMut.mutate({ doc: d, file: f });
                          e.target.value = "";
                        }}
                      />
                    </label>
                  </div>
                </div>
              </div>
            ))}
          </div>
          {docsQuery.isSuccess && visible.length === 0 && (
            <div className="text-center text-sm text-gray-500 py-10">표시할 서류 없음</div>
          )}
        </>
      )}

      {!supplierId && (
        <div className="rounded-xl border border-dashed border-gray-300 bg-white p-10 text-center text-sm text-gray-500">
          공급사를 선택하면 소속 장비/인원의 모든 서류가 나타납니다.
        </div>
      )}

      {/* OCR 결과 검토/편집 모달 */}
      {ocrDoc && (
        <div
          className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4"
          onClick={() => setOcrDoc(null)}
        >
          <div
            className="bg-white rounded-xl max-w-5xl w-full max-h-[90vh] overflow-hidden flex flex-col lg:flex-row"
            onClick={(e) => e.stopPropagation()}
          >
            {/* 좌측: 이미지 */}
            <div className="lg:w-1/2 bg-gray-100 p-3 flex items-center justify-center min-h-[300px]">
              <AuthImage
                docId={ocrDoc.id}
                alt={ocrDoc.category}
                className="max-w-full max-h-[80vh] object-contain"
              />
            </div>

            {/* 우측: OCR 필드 편집 */}
            <div className="lg:w-1/2 p-5 flex flex-col overflow-auto">
              <div className="flex items-start justify-between gap-3 mb-3">
                <div className="min-w-0">
                  <h3 className="text-lg font-bold">OCR 추출 결과 검토</h3>
                  <div className="text-xs text-gray-500">
                    {ocrDoc.ownerLabel} · {ocrDoc.category}
                  </div>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <button
                    onClick={runOcrAutoExtract}
                    disabled={ocrLoading}
                    className="whitespace-nowrap text-xs px-3 py-1.5 rounded-md bg-amber-500 text-white hover:bg-amber-600 disabled:opacity-50"
                  >
                    {ocrLoading ? "추출 중..." : "OCR 자동 추출"}
                  </button>
                  <button
                    onClick={() => setOcrDoc(null)}
                    className="text-gray-400 hover:text-gray-600 text-sm"
                  >
                    ✕
                  </button>
                </div>
              </div>

              {ocrLoading ? (
                <div className="text-sm text-gray-500">OCR 결과 로드 중...</div>
              ) : (
                <>
                  <div className="text-xs text-gray-500 mb-2">
                    필요하면 필드 값을 직접 수정 후 저장하세요.
                  </div>
                  <div className="space-y-2 flex-1">
                    {Object.keys(ocrFields).length === 0 ? (
                      <div className="text-sm text-gray-400 italic py-4">
                        추출된 필드가 없습니다. 아래에서 필드를 직접 추가할 수 있습니다.
                      </div>
                    ) : (
                      Object.entries(ocrFields).map(([k, v]) => (
                        <div key={k} className="grid grid-cols-[120px_1fr_auto] gap-2 items-center">
                          <input
                            value={k}
                            readOnly
                            className="text-xs px-2 py-1.5 bg-gray-50 border border-gray-200 rounded-md text-gray-600"
                          />
                          <input
                            value={v}
                            onChange={(e) =>
                              setOcrFields((f) => ({ ...f, [k]: e.target.value }))
                            }
                            className="text-sm px-2 py-1.5 border border-gray-300 rounded-md"
                          />
                          <button
                            onClick={() =>
                              setOcrFields((f) => {
                                const n = { ...f };
                                delete n[k];
                                return n;
                              })
                            }
                            className="text-xs text-gray-400 hover:text-rose-500"
                            title="삭제"
                          >
                            ✕
                          </button>
                        </div>
                      ))
                    )}

                    {/* 필드 추가 */}
                    <AddFieldRow
                      onAdd={(k, v) =>
                        setOcrFields((f) => ({ ...f, [k]: v }))
                      }
                    />
                  </div>

                  {/* 실제 검증 결과 — 판정 우선순위:
                        1) result 문자열: VALID/INVALID/UNKNOWN
                        2) valid boolean (legacy)
                        3) reasonCode: SUCCESS → 성공 */}
                  {verifyResult && (() => {
                    const r = (verifyResult.result || "").toString().toUpperCase();
                    const rc = (verifyResult.reasonCode || "").toString().toUpperCase();
                    const isValid = r === "VALID" || verifyResult.valid === true || rc === "SUCCESS";
                    const isInvalid = r === "INVALID";
                    const ok = isValid && !isInvalid;
                    return (
                      <div className={`mt-3 p-3 rounded-lg text-sm ${
                        ok ? "bg-emerald-50 border border-emerald-200"
                           : isInvalid ? "bg-rose-50 border border-rose-200"
                                       : "bg-amber-50 border border-amber-200"
                      }`}>
                        <div className="font-semibold">
                          {ok ? "✓ 검증 성공" : isInvalid ? "✗ 검증 실패" : "⚠ 확인 불가"}
                          {verifyResult.result && <span className="ml-2 text-xs font-normal text-gray-500">({verifyResult.result})</span>}
                          {verifyResult.provider && <span className="ml-2 text-[10px] bg-white px-1.5 py-0.5 rounded border text-gray-600">{verifyResult.provider}</span>}
                        </div>
                        {verifyResult.message && <div className="text-xs mt-1">{verifyResult.message}</div>}
                        {verifyResult.reasonCode && <div className="text-[10px] text-gray-500 mt-0.5">code: {verifyResult.reasonCode}</div>}
                      </div>
                    );
                  })()}

                  <div className="mt-4 pt-3 border-t flex flex-wrap justify-end gap-2">
                    <button
                      onClick={() => setOcrDoc(null)}
                      className="px-4 py-2 rounded-md border border-gray-300 text-sm"
                    >
                      취소
                    </button>
                    <button
                      onClick={runRealVerify}
                      disabled={verifyRunning}
                      className="px-4 py-2 rounded-md bg-indigo-600 text-white text-sm hover:bg-indigo-700 disabled:opacity-50"
                    >
                      {verifyRunning ? "검증 중..." : "실제 검증 실행"}
                    </button>
                    <button
                      onClick={() =>
                        saveOcrMut.mutate({
                          doc: ocrDoc,
                          fields: ocrFields,
                          verified: false,
                        })
                      }
                      disabled={saveOcrMut.isPending}
                      className="px-4 py-2 rounded-md border border-gray-300 text-gray-700 text-sm hover:bg-gray-50 disabled:opacity-50"
                    >
                      저장만 (미검증)
                    </button>
                    <button
                      onClick={() =>
                        saveOcrMut.mutate({
                          doc: ocrDoc,
                          fields: ocrFields,
                          verified: true,
                        })
                      }
                      disabled={saveOcrMut.isPending}
                      className="px-4 py-2 rounded-md bg-emerald-600 text-white text-sm hover:bg-emerald-700 disabled:opacity-50"
                    >
                      {saveOcrMut.isPending ? "저장 중..." : "저장 + 검증 완료"}
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>
      )}

      {/* 사진 미리보기 모달 */}
      {previewDoc && (
        <div
          className="fixed inset-0 bg-black/85 flex items-center justify-center z-50 p-4"
          onClick={() => setPreviewDoc(null)}
        >
          <div className="relative max-w-4xl max-h-[90vh]" onClick={(e) => e.stopPropagation()}>
            <button
              onClick={() => setPreviewDoc(null)}
              className="absolute -top-10 right-0 text-white text-sm hover:text-gray-300"
            >
              ✕ 닫기
            </button>
            <div className="bg-white rounded-lg overflow-hidden">
              <AuthImage
                docId={previewDoc.id}
                alt={previewDoc.category}
                className="max-w-full max-h-[80vh] object-contain"
              />
              <div className="px-4 py-3 border-t border-gray-200">
                <div className="text-sm font-semibold">{previewDoc.category}</div>
                <div className="text-xs text-gray-500">{previewDoc.ownerLabel}</div>
                <div className="text-xs text-gray-400 truncate">{previewDoc.fileName}</div>
                <div className="mt-1 text-xs">
                  {previewDoc.verified ? (
                    <span className="text-emerald-700">✓ 검증됨</span>
                  ) : (
                    <span className="text-amber-700">! 미검증</span>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 업로드 모달 */}
      {uploadOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4" onClick={() => setUploadOpen(false)}>
          <div className="bg-white rounded-xl p-6 max-w-md w-full space-y-4" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-lg font-bold">서류 업로드</h3>
            <div>
              <label className="text-xs font-medium text-gray-600 block mb-1">소유자 유형</label>
              <div className="flex gap-2">
                {(["EQUIPMENT", "PERSON"] as const).map((t) => (
                  <button
                    key={t}
                    onClick={() => setUploadForm((f) => ({ ...f, ownerType: t, ownerId: "" }))}
                    className={`px-3 py-1.5 rounded-md border text-sm ${
                      uploadForm.ownerType === t
                        ? "bg-indigo-600 text-white border-indigo-600"
                        : "bg-white text-gray-700 border-gray-300"
                    }`}
                  >
                    {t === "EQUIPMENT" ? "장비" : "인원"}
                  </button>
                ))}
              </div>
            </div>
            <div>
              <label className="text-xs font-medium text-gray-600 block mb-1">소유자 선택</label>
              <select
                value={uploadForm.ownerId}
                onChange={(e) => setUploadForm((f) => ({ ...f, ownerId: e.target.value }))}
                className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              >
                <option value="">-- 선택 --</option>
                {uploadForm.ownerType === "EQUIPMENT"
                  ? ((equipsQuery.data as any[]) || []).map((e: any) => (
                      <option key={e.id} value={e.id}>{e.vehicle_number || e.model_name}</option>
                    ))
                  : ((personsQuery.data as any[]) || []).map((p: any) => (
                      <option key={p.id} value={p.id}>{p.name} ({p.person_type})</option>
                    ))}
              </select>
            </div>
            <div>
              <label className="text-xs font-medium text-gray-600 block mb-1">서류 유형</label>
              <select
                value={uploadForm.typeId}
                onChange={(e) => setUploadForm((f) => ({ ...f, typeId: e.target.value }))}
                className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              >
                <option value="">-- 선택 --</option>
                {((docTypesQuery.data as any[]) || []).map((t: any) => (
                  <option key={t.id} value={t.id}>{t.name}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="text-xs font-medium text-gray-600 block mb-1">파일 (jpg/png/pdf)</label>
              <input
                type="file"
                accept=".jpg,.jpeg,.png,.pdf"
                onChange={(e) => setUploadForm((f) => ({ ...f, file: e.target.files?.[0] || null }))}
                className="w-full text-sm"
              />
            </div>
            <div className="flex gap-2 justify-end pt-2">
              <button
                onClick={() => setUploadOpen(false)}
                className="px-4 py-2 rounded-md border border-gray-300 text-sm"
              >
                취소
              </button>
              <button
                onClick={() => uploadMut.mutate(uploadForm)}
                disabled={uploadMut.isPending || !uploadForm.file || !uploadForm.ownerId || !uploadForm.typeId}
                className="px-4 py-2 rounded-md bg-emerald-600 text-white text-sm hover:bg-emerald-700 disabled:opacity-50"
              >
                {uploadMut.isPending ? "업로드 중..." : "업로드"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function AddFieldRow({ onAdd }: { onAdd: (key: string, val: string) => void }) {
  const [k, setK] = useState("");
  const [v, setV] = useState("");
  return (
    <div className="grid grid-cols-[120px_1fr_auto] gap-2 items-center pt-2 border-t border-dashed border-gray-200">
      <input
        placeholder="새 필드명"
        value={k}
        onChange={(e) => setK(e.target.value)}
        className="text-xs px-2 py-1.5 border border-gray-300 rounded-md"
      />
      <input
        placeholder="값"
        value={v}
        onChange={(e) => setV(e.target.value)}
        className="text-sm px-2 py-1.5 border border-gray-300 rounded-md"
      />
      <button
        onClick={() => {
          if (k.trim()) {
            onAdd(k.trim(), v);
            setK("");
            setV("");
          }
        }}
        disabled={!k.trim()}
        className="text-xs px-2 py-1 rounded-md bg-gray-600 text-white hover:bg-gray-700 disabled:opacity-40"
      >
        + 추가
      </button>
    </div>
  );
}
