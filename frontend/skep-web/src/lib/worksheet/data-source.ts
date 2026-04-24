// 작업계획서 화면의 데이터 소스
// - 실제 skep API(companies/equipment/persons/documents)에서 데이터를 받아
//   WorksheetPerson / WorksheetEquipment 형태로 변환해주는 어댑터 레이어.
// - 공급사 미선택 상태에서는 mock JSON(Public)으로 fallback.
import { companiesApi, equipmentApi, documentsApi } from "@/api/endpoints";
import type { Company, Equipment, Person, Document } from "@/types";
import { CompanyType } from "@/types";
import type { WorksheetEquipment, WorksheetPerson, DocumentRef, Role } from "./types";

// ─── Companies ────────────────────────────────────────────────────────
// 주의: 이 엔드포인트들은 PageResponse가 아니라 plain array를 돌려준다
function unwrap<T>(res: any): T[] {
  if (Array.isArray(res)) return res;
  if (res?.content && Array.isArray(res.content)) return res.content;
  return [];
}

export async function loadBpCompanies(): Promise<Company[]> {
  const res = await companiesApi.getByType(CompanyType.BP, { size: 500 });
  return unwrap<Company>(res);
}

export async function loadSupplierCompanies(): Promise<Company[]> {
  const res = await companiesApi.getByType(CompanyType.SUPPLIER, { size: 500 });
  return unwrap<Company>(res);
}

// ─── Document adapter ─────────────────────────────────────────────────
function adaptDocument(raw: any): DocumentRef {
  // 백엔드 snake_case / camelCase 둘 다 대응
  const fileName = raw.original_filename ?? raw.fileName ?? "document";
  const fileUrl = raw.file_url ?? raw.fileUrl ?? "";
  const category = raw.document_type_name ?? raw.typeName ?? "서류";
  const expiresAt = raw.expiry_date ?? raw.expiryDate;
  return {
    id: raw.id,
    originalName: fileName,
    // storageKey에 document id를 그대로 넣고 엔진/썸네일은 /api/documents/{id}/file 로 fetch
    storageKey: raw.id,
    mimeType: /\.(jpg|jpeg|png)$/i.test(fileName) ? "image/jpeg" : "application/octet-stream",
    category,
    expiresAt: expiresAt || undefined,
    verified: raw.verified === true,
    _fileUrl: fileUrl, // debug용
  } as any;
}

// ─── Equipment: 공급사별 리스트 + 각 장비의 서류 ─────────────────────
export async function loadSupplierEquipment(supplierId: string): Promise<WorksheetEquipment[]> {
  // 백엔드 파라미터명은 snake_case: supplier_id
  const res = await equipmentApi.getAll({ supplier_id: supplierId });
  const list: Equipment[] = unwrap<Equipment>(res);
  const results = await Promise.all(
    list.map(async (raw: any): Promise<WorksheetEquipment> => {
      // 백엔드 응답은 snake_case
      let docs: DocumentRef[] = [];
      try {
        const rawDocs = await documentsApi.getByOwner("EQUIPMENT", raw.id);
        docs = (rawDocs || []).map(adaptDocument);
      } catch {
        docs = [];
      }
      const year = raw.manufacture_year ?? raw.year;
      return {
        id: raw.id,
        equipmentType: raw.equipment_type_name ?? raw.typeName,
        vehicleNo: raw.vehicle_number ?? raw.serialNumber ?? raw.name,
        name: raw.model_name ?? raw.name ?? "",
        model: raw.model_name ?? raw.model,
        manufacturer: raw.manufacturer,
        year: year ? String(year) : "",
        upperPartYear: year ? String(year) : "",
        serialNo: raw.serial_number ?? raw.serialNumber,
        capacity: "",
        documents: docs,
      };
    })
  );
  return results;
}

// ─── Persons: 공급사별 리스트 + 각 인원의 서류 ───────────────────────
export async function loadSupplierPersons(supplierId: string): Promise<WorksheetPerson[]> {
  const res = await equipmentApi.getPersons({ supplier_id: supplierId });
  const list: Person[] = unwrap<Person>(res);
  const results = await Promise.all(
    list.map(async (raw: any): Promise<WorksheetPerson> => {
      let docs: DocumentRef[] = [];
      try {
        const rawDocs = await documentsApi.getByOwner("PERSON", raw.id);
        docs = (rawDocs || []).map(adaptDocument);
      } catch {
        docs = [];
      }
      // skep 백엔드는 person_type (DRIVER/GUIDE/SAFETY_INSPECTOR) → 작업계획서용 역할명으로 매핑
      const typeMap: Record<string, Role> = {
        DRIVER: "조종원",
        GUIDE: "유도원",
        SAFETY_INSPECTOR: "화기감시자",
      };
      const personType = (raw.person_type ?? raw.personType ?? raw.role ?? "").toString().trim();
      const mapped = typeMap[personType] as Role | undefined;
      const roles: Role[] = mapped ? [mapped] : (personType ? [personType as Role] : []);
      return {
        id: raw.id,
        name: raw.name,
        phone: raw.phone,
        company: raw.company_name ?? raw.companyName,
        roles,
        documents: docs,
      };
    })
  );
  return results;
}
