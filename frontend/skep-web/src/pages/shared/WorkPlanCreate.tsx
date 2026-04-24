import { useEffect, useState, useRef } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import type { WorksheetPerson as Person, WorksheetEquipment as Equipment } from '@/lib/worksheet/types';
import { SCHEMA as WORKSHEET_SCHEMA, buildDefaultValues, type TemplateSection, type TemplateField } from '@/lib/worksheet/schema';
import { renderWorksheet, extractLabelAliases, scanUploadedTemplate, fillScannedTemplate, autoFillKnownPlaceholders, PLACEHOLDER_CATALOG, type Attachment, type ScannedTemplate, type PersonCtx } from '@/lib/worksheet/engine';
import {
  loadBpCompanies,
  loadSupplierCompanies,
  loadSupplierEquipment,
  loadSupplierPersons,
} from '@/lib/worksheet/data-source';
import type { Company } from '@/types';
import { AuthImage } from '@/components/common/AuthImage';
import { EmbeddedEditor } from '@/components/worksheet/EmbeddedEditor';
import client from '@/api/client';

type RoleKey = 'operator' | 'supervisor' | 'signalman' | 'firewatch' | 'signaler';

const REQUIRED_ROLES: { key: RoleKey; label: string; role: string; required: boolean }[] = [
  { key: 'operator',   label: '조종원',       role: '조종원',       required: true },
  { key: 'supervisor', label: '작업지휘자',   role: '작업지휘자',   required: true },
  { key: 'signalman',  label: '유도원',       role: '유도원',       required: true },
  { key: 'firewatch',  label: '화기감시자',   role: '화기감시자',   required: false },
  { key: 'signaler',   label: '신호수',       role: '신호수',       required: false },
];

export default function WorkPlanCreate() {
  const navigate = useNavigate();
  const routeLoc = useLocation();
  const editBaseUrl = routeLoc.pathname.startsWith('/bp') ? '/bp/worksheet/edit/' : '/worksheet/edit/';
  const [loading, setLoading] = useState(true);
  const [openingEditor, setOpeningEditor] = useState(false);
  const [schema, setSchema] = useState<TemplateSection[]>([]);
  const [values, setValues] = useState<Record<string, any>>({});
  const [persons, setPersons] = useState<Person[]>([]);
  const [equipments, setEquipments] = useState<Equipment[]>([]);
  const [labelAliases, setLabelAliases] = useState<Record<string, string>>({});

  // BP사 / 공급사 선택 단계
  const [bpCompanies, setBpCompanies] = useState<Company[]>([]);
  const [supplierCompanies, setSupplierCompanies] = useState<Company[]>([]);
  const [bpCompanyId, setBpCompanyId] = useState('');
  const [supplierCompanyId, setSupplierCompanyId] = useState('');
  const [loadingSupplierData, setLoadingSupplierData] = useState(false);
  const [companyLoadError, setCompanyLoadError] = useState<string>('');

  const [equipmentId, setEquipmentId] = useState('');
  // 역할당 배정된 인력 ID 배열 (현장마다 여러 명 가능)
  const [roleAssign, setRoleAssign] = useState<Record<RoleKey, string[]>>({
    operator: [], supervisor: [], signalman: [], firewatch: [], signaler: [],
  });
  const [workSiteDiagramKey, setWorkSiteDiagramKey] = useState('');
  const [equipDocIds, setEquipDocIds] = useState<Set<string>>(new Set());
  const [personDocIds, setPersonDocIds] = useState<Set<string>>(new Set());

  const [generating, setGenerating] = useState(false);
  const [openSection, setOpenSection] = useState<string | null>('p1_site');

  // 템플릿 업로드 → 자동 채움 다이얼로그
  const [tplDialog, setTplDialog] = useState<{
    scanned: ScannedTemplate;
    fileName: string;
    values: Record<string, string>;
  } | null>(null);

  // 임베드된 편집기 상태 — null 이면 미리보기 모드, 있으면 편집 모드
  const [embeddedEditor, setEmbeddedEditor] = useState<{
    sessionId: string;
    fileName: string;
    configStr: string;
  } | null>(null);
  const [editorLoading, setEditorLoading] = useState(false);
  const [editorError, setEditorError] = useState<string>('');

  // OnlyOffice 편집 세션 생성 (공통)
  const createEditorSession = async (blob: Blob, baseName: string, fileName: string) => {
    const fd = new FormData();
    fd.append('file', blob, fileName);
    fd.append('name', baseName);
    const res: any = await client.post('/api/worksheet/editor-session', fd, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    const data = res?.data ?? res;
    const sid = data.sessionId;
    const config = data.config;
    const fn = data.fileName || fileName;
    if (!sid || !config) throw new Error('세션 생성 응답 오류');
    return { sessionId: sid, fileName: fn, configStr: JSON.stringify(config) };
  };

  // 기존 별도 페이지 이동 경로 (템플릿 업로드 경로 호환용으로만 유지)
  const openEditorFromBlob = async (blob: Blob, baseName: string, fileName: string) => {
    const s = await createEditorSession(blob, baseName, fileName);
    sessionStorage.setItem(`worksheet-editor-${s.sessionId}-config`, s.configStr);
    sessionStorage.setItem(`worksheet-editor-${s.sessionId}-fileName`, s.fileName);
    navigate(editBaseUrl + s.sessionId);
  };

  // 양식으로 채운 작업계획서를 **미리보기 자리에 임베드**해서 편집
  const openWordEditor = async () => {
    setOpeningEditor(true);
    setEditorError('');
    setEditorLoading(true);
    try {
      const { blob, baseName } = await buildDocxBlob(true);
      const s = await createEditorSession(blob, baseName, `${baseName}.docx`);
      setEmbeddedEditor(s);
    } catch (e: any) {
      alert('편집기 열기 실패: ' + (e?.response?.data?.message || e?.message || e));
      setEditorLoading(false);
    } finally {
      setOpeningEditor(false);
    }
  };

  // 편집 종료 — 편집본 자동 저장(forcesave) 후 편집기 닫기
  const closeEmbeddedEditor = async () => {
    try { (window as any).docEditorEmbedded?.serviceCommand?.('forcesave'); } catch { /* noop */ }
    // 서버 콜백 반영 대기
    await new Promise(r => setTimeout(r, 1200));
    setEmbeddedEditor(null);
    setEditorLoading(false);
    setEditorError('');
  };

  // 편집본 DOCX 다운로드
  const downloadEmbeddedDocx = async () => {
    if (!embeddedEditor) return;
    try { (window as any).docEditorEmbedded?.serviceCommand?.('forcesave'); } catch { /* noop */ }
    await new Promise(r => setTimeout(r, 1200));
    const base = embeddedEditor.fileName.replace(/\.docx$/i, '');
    window.open(
      `/api/worksheet/editor-session/${embeddedEditor.sessionId}/download?name=${encodeURIComponent(base)}`,
      '_blank',
    );
  };

  // 편집본 PDF 다운로드
  const downloadEmbeddedPdf = async () => {
    if (!embeddedEditor) return;
    setOpeningEditor(true);
    try {
      try { (window as any).docEditorEmbedded?.serviceCommand?.('forcesave'); } catch { /* noop */ }
      await new Promise(r => setTimeout(r, 1200));
      const base = embeddedEditor.fileName.replace(/\.docx$/i, '');
      const res = await client.get(
        `/api/worksheet/editor-session/${embeddedEditor.sessionId}/pdf?name=${encodeURIComponent(base)}`,
        { responseType: 'blob' },
      );
      const blob = res.data instanceof Blob ? res.data : new Blob([res.data], { type: 'application/pdf' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url; a.download = `${base}.pdf`; a.click();
      URL.revokeObjectURL(url);
    } catch (e: any) {
      alert('PDF 다운로드 실패: ' + (e?.message || e));
    } finally {
      setOpeningEditor(false);
    }
  };

  // 양식 변경 후 편집기 다시 생성 (현재 편집 내용은 자동저장 후 새 세션으로 교체)
  const refreshEmbeddedEditor = async () => {
    setOpeningEditor(true);
    setEditorError('');
    setEditorLoading(true);
    try {
      try { (window as any).docEditorEmbedded?.serviceCommand?.('forcesave'); } catch { /* noop */ }
      await new Promise(r => setTimeout(r, 800));
      const { blob, baseName } = await buildDocxBlob(true);
      const s = await createEditorSession(blob, baseName, `${baseName}.docx`);
      setEmbeddedEditor(s);
      setFormStaleForEditor(false);
    } catch (e: any) {
      alert('편집기 갱신 실패: ' + (e?.response?.data?.message || e?.message || e));
      setEditorLoading(false);
    } finally {
      setOpeningEditor(false);
    }
  };

  // 양식 변경 감지용 — 편집기 열린 상태에서 값이 바뀌면 "다시 불러오기" 배너 표시
  const [formStaleForEditor, setFormStaleForEditor] = useState(false);

  // 워드 파일 업로드 → {{플레이스홀더}} 스캔 → 있으면 다이얼로그, 없으면 바로 에디터
  const openEditorFromUploadedFile = async (file: File) => {
    setOpeningEditor(true);
    try {
      if (!/\.docx$/i.test(file.name)) {
        alert('.docx 파일만 가능합니다 (구형 .doc는 Word에서 한 번 열어 .docx로 저장해주세요)');
        return;
      }
      const scanned = await scanUploadedTemplate(file);
      if (scanned.placeholders.length === 0) {
        // 플레이스홀더 없음 → 원본 그대로 에디터 오픈
        const baseName = file.name.replace(/\.docx$/i, '');
        await openEditorFromBlob(file, baseName, file.name);
        return;
      }
      // 현재 세션 데이터를 기반으로 자동 매핑할 값 구성
      const curVehicle = equipments.find(e => e.id === equipmentId);
      const personsByRole = (k: RoleKey): PersonCtx[] => roleAssign[k]
        .map(id => persons.find(p => p.id === id))
        .filter(Boolean)
        .map(p => ({
          name: p!.name,
          birth: (p as any)?.birth,
          phone: (p as any)?.phone,
          address: (p as any)?.address,
          licenseNo: (p as any)?.licenseNo,
          licenseType: (p as any)?.licenseType,
          company: (p as any)?.company,
        }));
      const bp = bpCompanies.find(c => c.id === bpCompanyId);
      const sup = supplierCompanies.find(c => c.id === supplierCompanyId);
      const auto = autoFillKnownPlaceholders(scanned.placeholders, {
        equipment: curVehicle ? {
          equipmentType: (curVehicle as any).equipmentType,
          vehicleNo: curVehicle.vehicleNo,
          name: (curVehicle as any).name,
          model: (curVehicle as any).model,
          manufacturer: (curVehicle as any).manufacturer,
          year: (curVehicle as any).year,
          upperPartYear: (curVehicle as any).upperPartYear,
          serialNo: (curVehicle as any).serialNo,
          capacity: (curVehicle as any).capacity,
          insuranceExpiry: (curVehicle as any).insuranceExpiry,
          inspectionExpiry: (curVehicle as any).inspectionExpiry,
          ndtExpiry: (curVehicle as any).ndtExpiry,
        } : undefined,
        supplier: sup ? {
          name: sup.name,
          businessNumber: (sup as any).businessNumber,
          representative: (sup as any).representative,
          address: (sup as any).address,
          phone: (sup as any).phone,
          email: (sup as any).email,
        } : undefined,
        bp: bp ? {
          name: bp.name,
          businessNumber: (bp as any).businessNumber,
          representative: (bp as any).representative,
          address: (bp as any).address,
          phone: (bp as any).phone,
          email: (bp as any).email,
        } : undefined,
        operators: personsByRole('operator'),
        supervisors: personsByRole('supervisor'),
        signalmen: personsByRole('signalman'),
        firewatchers: personsByRole('firewatch'),
        signalers: personsByRole('signaler'),
        siteName: (values.siteName as string) || (values.site as string) || bp?.name,
        siteAddress: (values.siteAddress as string) || (values.address as string) || (bp as any)?.address,
        writer: (values.writer as string) || '',
        startDate: (values.startDate as string) || '',
        endDate: (values.endDate as string) || '',
      });
      // 플레이스홀더 전체에 대해 초기값 채움 (모르는 건 빈문자열)
      const initialValues: Record<string, string> = {};
      for (const p of scanned.placeholders) initialValues[p] = auto[p] ?? '';
      setTplDialog({ scanned, fileName: file.name, values: initialValues });
    } catch (e: any) {
      alert('파일 처리 실패: ' + (e?.response?.data?.message || e?.message || e));
    } finally {
      setOpeningEditor(false);
    }
  };

  const confirmTemplateFill = async () => {
    if (!tplDialog) return;
    setOpeningEditor(true);
    try {
      const filled = fillScannedTemplate(tplDialog.scanned, tplDialog.values);
      const baseName = tplDialog.fileName.replace(/\.docx$/i, '');
      setTplDialog(null);
      await openEditorFromBlob(filled, baseName, tplDialog.fileName);
    } catch (e: any) {
      alert('치환 실패: ' + (e?.message || e));
    } finally {
      setOpeningEditor(false);
    }
  };

  // 이메일 발송 다이얼로그
  const [mailOpen, setMailOpen] = useState(false);
  const [mailForm, setMailForm] = useState({ from: '', to: '', subject: '', body: '' });
  const [mailSending, setMailSending] = useState(false);
  const [mailMsg, setMailMsg] = useState('');
  const [previewMode, setPreviewMode] = useState<'split' | 'full'>('split');
  const [zoom, setZoom] = useState(85); // 줌 %
  const [autoPreview, setAutoPreview] = useState(true);
  const [search, setSearch] = useState('');
  const [showDetail, setShowDetail] = useState(false); // 세부 설정 펼침
  const [previewTab, setPreviewTab] = useState<'body' | 'full'>('body'); // 본문만 / 첨부 포함
  const sectionRefs = useRef<Record<string, HTMLDivElement | null>>({});
  const debounceRef = useRef<any>(null);
  const lastEditedPageRef = useRef<string | null>(null);
  const abortRef = useRef<AbortController | null>(null);
  // 각 탭의 캐시 유효성
  const bodyStaleRef = useRef(true);
  const fullStaleRef = useRef(true);
  // 최신 상태를 항상 읽기 위한 ref (setTimeout closure의 stale state 문제 방지)
  const valuesRef = useRef(values);
  const equipDocIdsRef = useRef(equipDocIds);
  const personDocIdsRef = useRef(personDocIds);
  const equipmentIdRef = useRef(equipmentId);
  const roleAssignRef = useRef(roleAssign);
  const workSiteDiagramKeyRef = useRef(workSiteDiagramKey);
  useEffect(() => { valuesRef.current = values; }, [values]);
  useEffect(() => { equipDocIdsRef.current = equipDocIds; }, [equipDocIds]);
  useEffect(() => { personDocIdsRef.current = personDocIds; }, [personDocIds]);
  useEffect(() => { equipmentIdRef.current = equipmentId; }, [equipmentId]);
  useEffect(() => { roleAssignRef.current = roleAssign; }, [roleAssign]);
  useEffect(() => { workSiteDiagramKeyRef.current = workSiteDiagramKey; }, [workSiteDiagramKey]);

  useEffect(() => {
    (async () => {
      setSchema(WORKSHEET_SCHEMA as any);
      setValues(buildDefaultValues());
      const aliases = await extractLabelAliases();
      setLabelAliases(aliases);
      // 회사 목록은 skep API에서. 실패해도 mock fallback 가능하도록 무시.
      try {
        const [bps, sups] = await Promise.all([loadBpCompanies(), loadSupplierCompanies()]);
        setBpCompanies(bps);
        setSupplierCompanies(sups);
      } catch (err: any) {
        setCompanyLoadError(err?.message || '회사 목록을 불러오지 못했습니다 (로그인 필요)');
      }
      setLoading(false);
    })();
  }, []);

  // 페이지 로드 완료되면 즉시 편집기 자동 오픈 — 장비·인력 선택 전에도 빈 템플릿으로 열어두고
  // 이후 양식 변경되면 헤더의 🔄 버튼으로 반영
  useEffect(() => {
    if (loading || embeddedEditor || openingEditor) return;
    if (!Object.keys(values).length) return; // defaults가 세팅된 후
    const t = setTimeout(() => {
      if (!embeddedEditor && !openingEditor) openWordEditor();
    }, 300);
    return () => clearTimeout(t);
  }, [loading, values]); // eslint-disable-line

  // 편집기 열린 상태에서 양식 주요 데이터(선택류) 바뀌면 자동 반영 — 사용자가 버튼 안 눌러도 됨
  // values(일반 텍스트 필드)는 직접 편집기에서 수정할 수 있으니 자동 refresh 대상에서 제외
  const autoRefreshDebounce = useRef<any>(null);
  useEffect(() => {
    if (!embeddedEditor || openingEditor) return;
    setFormStaleForEditor(true);
    if (autoRefreshDebounce.current) clearTimeout(autoRefreshDebounce.current);
    autoRefreshDebounce.current = setTimeout(() => {
      refreshEmbeddedEditor();
    }, 1500);
    return () => { if (autoRefreshDebounce.current) clearTimeout(autoRefreshDebounce.current); };
  }, [equipmentId, roleAssign, supplierCompanyId, bpCompanyId, equipDocIds, personDocIds]); // eslint-disable-line

  // 공급사 선택 시 그 공급사의 장비/인원 로드
  useEffect(() => {
    if (!supplierCompanyId) {
      setPersons([]); setEquipments([]); return;
    }
    (async () => {
      setLoadingSupplierData(true);
      try {
        const [eqs, ps] = await Promise.all([
          loadSupplierEquipment(supplierCompanyId),
          loadSupplierPersons(supplierCompanyId),
        ]);
        setEquipments(eqs); setPersons(ps);
      } catch (err: any) {
        alert('공급사 데이터 로드 실패: ' + (err?.message || err));
        setEquipments([]); setPersons([]);
      } finally {
        setLoadingSupplierData(false);
      }
    })();
    // 공급사 바꾸면 이전 장비/역할 선택 초기화
    setEquipmentId('');
    setRoleAssign({ operator: [], supervisor: [], signalman: [], firewatch: [], signaler: [] });
    setEquipDocIds(new Set());
    setPersonDocIds(new Set());
  }, [supplierCompanyId]);

  // BP 선택 시 업체명 자동 채움 (편집 가능)
  useEffect(() => {
    const bp = bpCompanies.find(c => c.id === bpCompanyId);
    if (bp) {
      setValues(v => ({ ...v, submitCompany: bp.name }));
    }
  }, [bpCompanyId, bpCompanies]);

  // 장비 선택 시 자동 채움
  useEffect(() => {
    if (!equipmentId) return;
    const eq = equipments.find(e => e.id === equipmentId);
    if (!eq) return;
    const diagram = eq.documents.find(d => d.category === '작업배치도')
      || eq.documents.find(d => d.category === '장비실사사진');
    setWorkSiteDiagramKey(diagram?.storageKey || '');
    // 기본으로 전체 서류 선택
    setEquipDocIds(new Set(eq.documents.map(d => d.id)));
    setValues(v => ({
      ...v,
      equipmentName: eq.name,
      equipmentModel: eq.model || '',
      vehicleNo: eq.vehicleNo,
      equipmentSerialNo: eq.serialNo || '',
      manufacturer: eq.manufacturer || '',
      manufactureYear: eq.upperPartYear || eq.year || '',
      equipmentSpec: eq.capacity || '',
      equipmentCapacity: eq.capacity || '45m',
    }));
  }, [equipmentId, equipments]);

  // 역할 인력 선택 시 자동 채움 + 해당 인력 서류 기본 첨부
  useEffect(() => {
    const ops = roleAssign.operator.map(id => persons.find(p => p.id === id)).filter(Boolean) as Person[];
    const sups = roleAssign.supervisor.map(id => persons.find(p => p.id === id)).filter(Boolean) as Person[];
    const join = (arr: string[]) => arr.filter(Boolean).join(' / ');
    setValues(v => ({
      ...v,
      operatorName: join(ops.map(p => p.name)),
      operatorLicenseNo: join(ops.map(p => p.licenseNo || '')),
      supervisor_company: sups[0]?.company || v.supervisor_company,
      supervisor_name: join(sups.map(p => p.name)),
    }));
    // 지정된 모든 역할자의 서류를 기본 첨부
    const nextIds = new Set<string>();
    (Object.keys(roleAssign) as RoleKey[]).forEach(k => {
      roleAssign[k].forEach(id => {
        const p = persons.find(x => x.id === id);
        p?.documents?.forEach(d => nextIds.add(d.id));
      });
    });
    setPersonDocIds(nextIds);
  }, [roleAssign, persons]);

  const update = (key: string, val: any) => {
    setValues(v => ({ ...v, [key]: val }));
    bodyStaleRef.current = true;
    fullStaleRef.current = true;
    // 어느 페이지에 속하는 필드인지 기록 → 렌더 후 그 페이지로 스크롤
    const owningSec = schema.find(s => s.fields.some(f => f.key === key));
    if (owningSec) {
      lastEditedPageRef.current = owningSec.page;
      // 프리뷰 기다리지 말고 즉시 해당 페이지로 스크롤+하이라이트
      jumpPreviewToPage(owningSec.page);
    }
    if (autoPreview && !embeddedEditor) {
      if (debounceRef.current) clearTimeout(debounceRef.current);
      const isFull = previewTab === 'full';
      // 활성 탭만 재생성
      debounceRef.current = setTimeout(() => generate(false, isFull), isFull ? 500 : 250);
    }
  };

  // 장비/역할/서류 변경 시 — full 탭만 stale
  useEffect(() => {
    fullStaleRef.current = true;
    if (!autoPreview || !Object.keys(values).length || embeddedEditor) return;
    // full 탭이 활성화돼 있을 때만 즉시 재생성
    if (previewTab === 'full') {
      if (debounceRef.current) clearTimeout(debounceRef.current);
      debounceRef.current = setTimeout(() => generate(false, true), 500);
    }
  }, [equipmentId, roleAssign, workSiteDiagramKey, equipDocIds, personDocIds, embeddedEditor]); // eslint-disable-line

  // 탭 전환 + 초기 로드 — 그 탭이 stale이면 즉시 재생성
  // values가 defaults로 채워지는 시점에도 한 번 발동되어 첫 미리보기가 뜸
  useEffect(() => {
    if (!autoPreview || !Object.keys(values).length || embeddedEditor) return;
    const isFull = previewTab === 'full';
    const stale = isFull ? fullStaleRef.current : bodyStaleRef.current;
    if (stale) {
      if (debounceRef.current) clearTimeout(debounceRef.current);
      debounceRef.current = setTimeout(() => generate(false, isFull), 100);
    }
  }, [previewTab, loading, embeddedEditor]); // eslint-disable-line

  // DOCX blob 생성 (미리보기/다운로드 공통)
  const buildDocxBlob = async (includeAttachments: boolean = true): Promise<{ blob: Blob; baseName: string }> => {
    const curValues = valuesRef.current;
    const curEquipId = equipmentIdRef.current;
    const curRoleAssign = roleAssignRef.current;
    const curEquipDocIds = equipDocIdsRef.current;
    const curPersonDocIds = personDocIdsRef.current;
    const curDiagramKey = workSiteDiagramKeyRef.current;
    const attachments: { storageKey: string; category: string; originalName?: string }[] = [];
    if (includeAttachments) {
      const eq = equipments.find(e => e.id === curEquipId);
      if (eq) {
        for (const d of eq.documents) {
          if (curEquipDocIds.has(d.id)) attachments.push({ storageKey: d.storageKey, category: `장비 · ${d.category}`, originalName: d.originalName });
        }
      }
      for (const r of REQUIRED_ROLES) {
        for (const personId of curRoleAssign[r.key]) {
          const p = persons.find(x => x.id === personId);
          if (!p) continue;
          for (const d of (p.documents || [])) {
            if (curPersonDocIds.has(d.id)) attachments.push({ storageKey: d.storageKey, category: `${r.label} ${p.name} · ${d.category}`, originalName: d.originalName });
          }
        }
      }
    }
    const blob = await renderWorksheet(curValues, curDiagramKey, attachments as Attachment[]);
    const baseName = `작업계획서_${curValues.vehicleNo || 'NEW'}`;
    return { blob, baseName };
  };

  // PDF 다운로드 — 서버에 DOCX 보내고 PDF 받아 다운로드
  const downloadPdf = async () => {
    setGenerating(true);
    try {
      const { blob, baseName } = await buildDocxBlob(true);
      const fd = new FormData();
      fd.append('file', blob, `${baseName}.docx`);
      fd.append('name', baseName);
      const res = await client.post('/api/worksheet/to-pdf', fd, {
        responseType: 'blob',
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      const pdfBlob = res.data instanceof Blob ? res.data : new Blob([res.data], { type: 'application/pdf' });
      const url = URL.createObjectURL(pdfBlob);
      const a = document.createElement('a');
      a.href = url; a.download = `${baseName}.pdf`; a.click();
      URL.revokeObjectURL(url);
    } catch (err: any) {
      alert('PDF 다운로드 실패: ' + (err?.response?.data?.message || err?.message || err));
    } finally {
      setGenerating(false);
    }
  };

  // 이메일로 PDF 발송
  const sendMail = async () => {
    if (!mailForm.to.trim()) { setMailMsg('받는 사람 이메일을 입력하세요'); return; }
    setMailSending(true);
    setMailMsg('');
    try {
      const { blob, baseName } = await buildDocxBlob(true);
      const fd = new FormData();
      fd.append('file', blob, `${baseName}.docx`);
      fd.append('name', baseName);
      if (mailForm.from.trim()) fd.append('from', mailForm.from.trim());
      fd.append('to', mailForm.to.trim());
      if (mailForm.subject.trim()) fd.append('subject', mailForm.subject.trim());
      if (mailForm.body.trim()) fd.append('body', mailForm.body);
      const res: any = await client.post('/api/worksheet/send-pdf', fd, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      const payload = res?.data ?? res;
      if (payload?.ok === false) {
        setMailMsg(payload.message || '발송 실패');
      } else {
        setMailMsg(`✓ ${payload?.to} 로 발송 완료`);
        setTimeout(() => { setMailOpen(false); setMailMsg(''); }, 1500);
      }
    } catch (err: any) {
      setMailMsg('발송 실패: ' + (err?.response?.data?.message || err?.message || err));
    } finally {
      setMailSending(false);
    }
  };

  const generate = async (download: boolean, includeAttachments: boolean = true) => {
    setGenerating(true);

    // 항상 최신 state를 ref 경유로 읽음 (setTimeout closure의 stale state 방지)
    const curValues = valuesRef.current;
    const curEquipId = equipmentIdRef.current;
    const curRoleAssign = roleAssignRef.current;
    const curEquipDocIds = equipDocIdsRef.current;
    const curPersonDocIds = personDocIdsRef.current;
    const curDiagramKey = workSiteDiagramKeyRef.current;

    // 첨부 목록 구성: 장비 서류 + 역할별 인력 서류 (includeAttachments=false면 빈 배열)
    const attachments: { storageKey: string; category: string; originalName?: string }[] = [];
    if (includeAttachments) {
      const eq = equipments.find(e => e.id === curEquipId);
      if (eq) {
        for (const d of eq.documents) {
          if (curEquipDocIds.has(d.id)) attachments.push({
            storageKey: d.storageKey,
            category: `장비 · ${d.category}`,
            originalName: d.originalName,
          });
        }
      }
      for (const r of REQUIRED_ROLES) {
        for (const personId of curRoleAssign[r.key]) {
          const p = persons.find(x => x.id === personId);
          if (!p) continue;
          for (const d of (p.documents || [])) {
            if (curPersonDocIds.has(d.id)) attachments.push({
              storageKey: d.storageKey,
              category: `${r.label} ${p.name} · ${d.category}`,
              originalName: d.originalName,
            });
          }
        }
      }
    }

    // 이전 요청 취소
    if (abortRef.current) abortRef.current.abort();
    const ac = new AbortController();
    abortRef.current = ac;

    let blob: Blob;
    try {
      blob = await renderWorksheet(curValues, curDiagramKey, attachments as Attachment[]);
    } catch (err: any) {
      console.error('generate error', err);
      alert('생성 실패: ' + (err?.message || err));
      setGenerating(false);
      return;
    }
    const url = URL.createObjectURL(blob);
    if (download) {
      const a = document.createElement('a');
      a.href = url; a.download = `작업계획서_${curValues.vehicleNo || 'NEW'}.docx`; a.click();
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    } else {
      const { renderAsync } = await import('docx-preview');
      // 첨부 포함 여부에 따라 다른 컨테이너 사용 (탭별 캐시)
      const containerId = includeAttachments ? 'preview-container-full' : 'preview-container-body';
      const container = document.getElementById(containerId);
      if (container) {
        container.innerHTML = '';
        await renderAsync(blob, container, undefined, {
          className: 'docx', inWrapper: true, ignoreWidth: false, ignoreHeight: true,
        });
        // 렌더 완료 → 해당 탭 fresh
        if (includeAttachments) fullStaleRef.current = false;
        else bodyStaleRef.current = false;
        // 재렌더되면 이전 하이라이트 DOM은 사라지니, 편집한 페이지에 하이라이트만 재적용 (스크롤은 편집 시 이미 완료)
        const pageMap: Record<string, number> = { p1: 0, p2: 1, p3: 2, p4: 3, p5: 4 };
        const targetIdx = lastEditedPageRef.current ? pageMap[lastEditedPageRef.current] : undefined;
        const sections = container.querySelectorAll<HTMLElement>('section.docx');
        const scrollParent = document.getElementById('preview-scroll');
        if (targetIdx !== undefined && sections[targetIdx]) {
          const tgt = sections[targetIdx];
          tgt.style.transition = 'outline 0.3s, box-shadow 0.3s';
          tgt.style.outline = '3px solid #3b82f6';
          tgt.style.boxShadow = '0 0 0 6px rgba(59,130,246,0.25), 0 2px 8px rgba(0,0,0,0.15)';
          setTimeout(() => {
            tgt.style.outline = '';
            tgt.style.boxShadow = '0 2px 8px rgba(0,0,0,0.15)';
          }, 900);
        } else if (scrollParent) {
          scrollParent.scrollTop = 0;
        }

        // 미리보기 페이지 클릭 → 해당 페이지 폼 섹션 열기 & 스크롤
        const invPageMap = ['p1', 'p2', 'p3', 'p4', 'p5'];

        const openAndFocus = (secId: string, fieldKey?: string) => {
          // 세부 설정 아코디언 안의 섹션이면 그 그룹도 펼쳐야 DOM에 나옴
          const targetSec = schema.find(s => s.id === secId);
          if (targetSec && !targetSec.essential) setShowDetail(true);
          setOpenSection(secId);
          setTimeout(() => {
            const formCard = sectionRefs.current[secId];
            formCard?.scrollIntoView({ behavior: 'smooth', block: 'start' });
            if (formCard) {
              formCard.style.transition = 'outline 0.3s, box-shadow 0.3s';
              formCard.style.outline = '3px solid #8b5cf6';
              formCard.style.boxShadow = '0 0 0 6px rgba(139,92,246,0.25)';
              setTimeout(() => { formCard.style.outline = ''; formCard.style.boxShadow = ''; }, 1200);
            }
            if (fieldKey) {
              setTimeout(() => {
                const input = document.querySelector<HTMLInputElement | HTMLTextAreaElement>(`[data-field-key="${fieldKey}"]`);
                if (input) {
                  input.focus();
                  input.select?.();
                  input.style.transition = 'box-shadow 0.3s';
                  input.style.boxShadow = '0 0 0 3px rgba(139,92,246,0.35)';
                  setTimeout(() => { input.style.boxShadow = ''; }, 1400);
                }
              }, 400);
            }
          }, 120);
        };

        // 텍스트 노드 ↔ 필드 매핑 — 값 + 라벨 둘 다 매핑, first-wins
        const valuesSnap = valuesRef.current;
        const textToField = new Map<string, string>();
        const pushCandidate = (t: string, key: string) => {
          const s = t.trim();
          if (s.length < 2) return;
          if (!textToField.has(s)) textToField.set(s, key);
        };
        for (const sec of schema) {
          for (const f of sec.fields) {
            // 라벨 매칭 (예: "건설기계 등록원부" 클릭 → attach0 필드)
            if (f.label) pushCandidate(f.label, f.key);
            const v = valuesSnap[f.key];
            if (typeof v !== 'string' || !v) continue;
            pushCandidate(v, f.key);
            if (f.type === 'date') {
              pushCandidate(v.replace(/-/g, '.'), f.key); // 2025-11-11 → 2025.11.11
            }
            if (v.includes(' / ')) {
              v.split(' / ').forEach(x => pushCandidate(x, f.key)); // 조인된 이름
            }
          }
        }
        // 템플릿에서 추출한 실제 라벨 텍스트 → 필드 매핑 추가
        // (예: "기종 / 모델명" 클릭 → equipmentName 필드)
        for (const [labelText, fieldKey] of Object.entries(labelAliases)) {
          if (!textToField.has(labelText)) textToField.set(labelText, fieldKey);
        }

        sections.forEach((secEl, idx) => {
          const pageId = invPageMap[idx];
          if (!pageId) return;
          secEl.style.cursor = 'pointer';
          secEl.title = '클릭하면 가장 가까운 필드로 이동';

          // 페이지 단위 클릭: DOM 구조 기반으로 정확도 높임
          //   1. 클릭 지점에서 부모 방향으로 타고 올라가며, 같은 표(td/tr/table)
          //      안에 매칭된 요소가 있으면 그걸 사용 → 같은 표/행 안의 라벨 ↔ 값 매칭
          //   2. 없으면 전체 페이지에서 유클리드 거리 최단 매칭
          //   3. 그래도 없으면 페이지 essential 섹션
          secEl.addEventListener('click', (ev) => {
            const target = ev.target as HTMLElement | null;
            let cur: HTMLElement | null = target;
            let ancestorWin: HTMLElement | null = null;
            while (cur && cur !== secEl) {
              const m = cur.querySelector<HTMLElement>('[data-pre-matched]');
              if (m) { ancestorWin = m; break; }
              cur = cur.parentElement;
            }
            if (ancestorWin) { ancestorWin.click(); return; }

            const matched = Array.from(secEl.querySelectorAll<HTMLElement>('[data-pre-matched]'));
            if (matched.length > 0) {
              const mx = (ev as MouseEvent).clientX;
              const my = (ev as MouseEvent).clientY;
              let best: HTMLElement | null = null;
              let bestDist = Infinity;
              for (const el of matched) {
                const r = el.getBoundingClientRect();
                const d = Math.hypot(r.left + r.width / 2 - mx, r.top + r.height / 2 - my);
                if (d < bestDist) { bestDist = d; best = el; }
              }
              if (best) { best.click(); return; }
            }
            const targetSec = schema.find(s => s.page === pageId && s.essential) || schema.find(s => s.page === pageId);
            if (targetSec) openAndFocus(targetSec.id);
          });

          // 이 페이지 안의 텍스트 노드를 걸어서 필드 매칭되는 것에 세밀한 핸들러 부여
          const walker = document.createTreeWalker(secEl, NodeFilter.SHOW_TEXT);
          let node: Node | null;
          while ((node = walker.nextNode())) {
            const raw = (node.nodeValue || '').trim();
            if (!raw) continue;
            const fieldKey = textToField.get(raw);
            if (!fieldKey) continue;
            const parent = node.parentElement as HTMLElement | null;
            if (!parent || parent.dataset.preMatched) continue;
            parent.dataset.preMatched = '1';
            parent.dataset.fieldKey = fieldKey;
            parent.style.cursor = 'text';
            parent.style.transition = 'background 0.15s';
            parent.title = '클릭하면 여기서 바로 수정. Shift+클릭으로 폼 이동';
            parent.addEventListener('mouseenter', () => { parent.style.background = 'rgba(139,92,246,0.15)'; });
            parent.addEventListener('mouseleave', () => {
              if (parent.dataset.editing !== '1') parent.style.background = '';
            });
            parent.addEventListener('click', (e) => {
              e.stopPropagation();
              // Shift + 클릭 → 기존 동작(폼 이동 + 하이라이트)
              if ((e as MouseEvent).shiftKey) {
                const sec = schema.find(s => s.fields.some(f => f.key === fieldKey));
                if (sec) openAndFocus(sec.id, fieldKey);
                return;
              }
              // 일반 클릭 → 제자리 편집 (contentEditable)
              if (parent.dataset.editing === '1') return;
              parent.dataset.editing = '1';
              parent.contentEditable = 'true';
              parent.style.background = 'rgba(250,204,21,0.35)';
              parent.style.outline = '2px solid #f59e0b';
              parent.style.borderRadius = '2px';
              const origText = parent.textContent || '';
              // 편집 중에는 debounce가 미리보기를 다시 그리면 DOM이 사라지므로 잠시 미리보기 막기
              const prevAutoRef = autoPreview;
              const restoreUI = () => {
                parent.contentEditable = 'false';
                parent.style.background = '';
                parent.style.outline = '';
                parent.style.borderRadius = '';
                delete parent.dataset.editing;
              };
              const commit = () => {
                const newText = (parent.textContent || '').trim();
                restoreUI();
                if (newText !== origText.trim()) {
                  // 폼 state 업데이트 → 자동 미리보기가 800ms 후 반영
                  update(fieldKey, newText);
                }
              };
              const cancel = () => {
                parent.textContent = origText;
                restoreUI();
              };
              // 전체 선택해서 덮어쓰기 편하게
              setTimeout(() => {
                parent.focus();
                const range = document.createRange();
                range.selectNodeContents(parent);
                const sel = window.getSelection();
                sel?.removeAllRanges();
                sel?.addRange(range);
              }, 0);
              const onKey = (ev: KeyboardEvent) => {
                if (ev.key === 'Enter') { ev.preventDefault(); commit(); cleanup(); }
                else if (ev.key === 'Escape') { ev.preventDefault(); cancel(); cleanup(); }
              };
              const onBlur = () => { commit(); cleanup(); };
              const cleanup = () => {
                parent.removeEventListener('keydown', onKey);
                parent.removeEventListener('blur', onBlur);
              };
              parent.addEventListener('keydown', onKey);
              parent.addEventListener('blur', onBlur);
              void prevAutoRef; // no-op reference to quiet TS
            });
          }
        });
      }
    }
    setGenerating(false);
  };

  const aiRewrite = async (field: TemplateField) => {
    const data = { value: '' };
    alert('AI 재작성은 아직 이 환경에서 지원되지 않습니다. (백엔드 연동 예정)');
    return;
    if (data.value && confirm(`AI 추천:\n\n${data.value}\n\n적용하시겠어요?`)) {
      update(field.key, data.value);
    }
  };

  const jumpToSection = (id: string) => {
    setOpenSection(id);
    setTimeout(() => sectionRefs.current[id]?.scrollIntoView({ behavior: 'smooth', block: 'start' }), 100);
  };

  // 우측 미리보기에서 해당 페이지로 스크롤 (재렌더 없이) — 현재 활성 탭 컨테이너 기준
  const jumpPreviewToPage = (page: string) => {
    const pageMap: Record<string, number> = { p1: 0, p2: 1, p3: 2, p4: 3, p5: 4 };
    const idx = pageMap[page];
    if (idx === undefined) return;
    const activeId = previewTab === 'full' ? 'preview-container-full' : 'preview-container-body';
    const container = document.getElementById(activeId);
    const sections = container?.querySelectorAll<HTMLElement>('section.docx');
    const tgt = sections?.[idx];
    if (!tgt) return;
    tgt.scrollIntoView({ behavior: 'smooth', block: 'start' });
    tgt.style.transition = 'outline 0.3s, box-shadow 0.3s';
    tgt.style.outline = '3px solid #3b82f6';
    tgt.style.boxShadow = '0 0 0 6px rgba(59,130,246,0.25), 0 2px 8px rgba(0,0,0,0.15)';
    setTimeout(() => {
      tgt.style.outline = '';
      tgt.style.boxShadow = '0 2px 8px rgba(0,0,0,0.15)';
    }, 1200);
  };

  if (loading) return <div>로딩 중...</div>;

  const selectedEquip = equipments.find(e => e.id === equipmentId);

  // 배정된 인력들 모으기 (역할당 여러 명)
  const assignedPersons = REQUIRED_ROLES.map(r => {
    const ps = roleAssign[r.key].map(id => persons.find(x => x.id === id)).filter(Boolean) as Person[];
    return { ...r, people: ps };
  });

  // 진행률 계산
  const requiredFilled = assignedPersons.filter(r => r.required && r.people.length > 0).length;
  const requiredTotal = REQUIRED_ROLES.filter(r => r.required).length;
  const equipOk = !!selectedEquip;
  const siteOk = !!values.siteName;
  const overall = Math.round(((requiredFilled + (equipOk ? 1 : 0) + (siteOk ? 1 : 0)) / (requiredTotal + 2)) * 100);

  return (
    <div className="space-y-4">
      {/* ═══ 최상단 요약 & 진행률 ═══ */}
      <div className="card p-4">
        <div className="flex items-center justify-between mb-3">
          <h1 className="text-xl font-bold">작업계획서 생성</h1>
          <div className="flex items-center gap-3">
            <div className="w-48 h-2 bg-slate-200 rounded-full overflow-hidden">
              <div className={`h-full ${overall === 100 ? 'bg-emerald-500' : overall >= 70 ? 'bg-blue-500' : 'bg-yellow-500'}`} style={{ width: overall + '%' }} />
            </div>
            <span className="text-sm font-medium text-slate-700">{overall}% 준비</span>
          </div>
        </div>

        {/* 필수 체크리스트 */}
        <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-2 text-xs">
          <ChecklistItem done={siteOk} label="현장 정보" onClick={() => jumpToSection('p1_site')} />
          <ChecklistItem done={equipOk} label={selectedEquip ? `장비: ${selectedEquip.vehicleNo}` : '장비 선택'} onClick={() => document.getElementById('quick-pick')?.scrollIntoView({ behavior: 'smooth' })} />
          {REQUIRED_ROLES.map(r => {
            const ps = roleAssign[r.key].map(id => persons.find(x => x.id === id)).filter(Boolean) as Person[];
            return (
              <ChecklistItem
                key={r.key}
                done={ps.length > 0}
                required={r.required}
                label={ps.length > 0 ? `${r.label} ${ps.length}명` : r.label}
                onClick={() => document.getElementById('quick-pick')?.scrollIntoView({ behavior: 'smooth' })}
              />
            );
          })}
        </div>
      </div>

      {/* ═══ 첨부 사진 요약 (장비 + 인력) ═══ */}
      {(selectedEquip || assignedPersons.some(a => a.people.length > 0)) && (() => {
        const equipCount = selectedEquip ? equipDocIds.size : 0;
        const personCount = personDocIds.size;
        const total = equipCount + personCount;
        return (
          <div className="card p-4">
            <div className="flex items-center justify-between mb-2">
              <h2 className="font-semibold text-slate-800 text-sm">첨부될 서류 총 <span className="text-blue-600">{total}개</span></h2>
              <div className="text-xs text-slate-500">생성 문서 뒷부분에 이 사진들이 순서대로 삽입됨</div>
            </div>

            {selectedEquip && (
              <div className="mb-3">
                <div className="text-xs font-semibold text-slate-600 mb-1.5 flex items-center gap-1.5">
                  <span className="bg-amber-100 text-amber-700 px-1.5 py-0.5 rounded text-[10px]">장비</span>
                  {selectedEquip.vehicleNo} <span className="text-slate-400">({equipCount}/{selectedEquip.documents.length})</span>
                </div>
                <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8 gap-2">
                  {selectedEquip.documents.map(d => {
                    const included = equipDocIds.has(d.id);
                    return (
                      <label key={d.id} className={`relative cursor-pointer border-2 rounded-lg overflow-hidden transition ${included ? 'border-blue-500 shadow' : 'border-slate-200 opacity-60'}`}>
                        <input type="checkbox" checked={included} onChange={() => {
                          const n = new Set(equipDocIds);
                          if (n.has(d.id)) n.delete(d.id); else n.add(d.id);
                          setEquipDocIds(n);
                        }} className="absolute top-1 left-1 z-10" />
                        {d.verified === false && (
                          <span className="absolute top-1 right-1 z-10 bg-amber-500 text-white text-[9px] font-bold px-1 py-0.5 rounded" title="아직 검증되지 않은 서류">미검증</span>
                        )}
                        {d.mimeType.startsWith('image/') ? (
                          <AuthImage docId={d.id} alt={d.category} className="w-full h-24 object-cover bg-slate-100" />
                        ) : (
                          <div className="w-full h-24 bg-slate-100 flex items-center justify-center text-xs text-slate-500">{d.originalName.split('.').pop()}</div>
                        )}
                        <div className="px-1 py-1 text-[10px] font-medium truncate bg-white">{d.category}</div>
                      </label>
                    );
                  })}
                </div>
              </div>
            )}

            {assignedPersons.filter(a => a.people.length > 0).flatMap(a =>
              a.people.map(person => (
                <div key={a.key + '_' + person.id} className="mb-3">
                  <div className="text-xs font-semibold text-slate-600 mb-1.5 flex items-center gap-1.5">
                    <span className="bg-emerald-100 text-emerald-700 px-1.5 py-0.5 rounded text-[10px]">{a.label}</span>
                    {person.name}
                    <span className="text-slate-400">
                      ({person.documents?.filter(d => personDocIds.has(d.id)).length || 0}/{person.documents?.length || 0})
                    </span>
                  </div>
                  {person.documents && person.documents.length > 0 ? (
                    <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8 gap-2">
                      {person.documents.map(d => {
                        const included = personDocIds.has(d.id);
                        return (
                          <label key={d.id} className={`relative cursor-pointer border-2 rounded-lg overflow-hidden transition ${included ? 'border-emerald-500 shadow' : 'border-slate-200 opacity-60'}`}>
                            <input type="checkbox" checked={included} onChange={() => {
                              const n = new Set(personDocIds);
                              if (n.has(d.id)) n.delete(d.id); else n.add(d.id);
                              setPersonDocIds(n);
                            }} className="absolute top-1 left-1 z-10" />
                            {d.verified === false && (
                              <span className="absolute top-1 right-1 z-10 bg-amber-500 text-white text-[9px] font-bold px-1 py-0.5 rounded" title="아직 검증되지 않은 서류">미검증</span>
                            )}
                            {d.mimeType.startsWith('image/') ? (
                              <AuthImage docId={d.id} alt={d.category} className="w-full h-24 object-cover bg-slate-100" />
                            ) : (
                              <div className="w-full h-24 bg-slate-100 flex items-center justify-center text-xs text-slate-500">{d.originalName.split('.').pop()}</div>
                            )}
                            <div className="px-1 py-1 text-[10px] font-medium truncate bg-white">{d.category}</div>
                          </label>
                        );
                      })}
                    </div>
                  ) : (
                    <div className="text-xs text-slate-400 italic">등록된 서류 없음</div>
                  )}
                </div>
              ))
            )}
          </div>
        );
      })()}

      {/* ═══ 1단계: BP사 / 공급사 선택 ═══ */}
      <div className="card p-4 bg-indigo-50 border-indigo-200 space-y-3">
        <div className="text-sm font-semibold text-indigo-900">
          Step 1 · BP사 / 장비 공급사 선택
          {loadingSupplierData && <span className="ml-2 text-xs text-indigo-600">(공급사 데이터 로드 중...)</span>}
        </div>
        {companyLoadError && (
          <div className="text-xs text-rose-700 bg-rose-50 border border-rose-200 rounded px-2 py-1">
            ! {companyLoadError} — 임시로 mock 데이터를 쓰려면 로그인하거나 offline 모드를 사용하세요.
          </div>
        )}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <div>
            <label className="text-[10px] font-medium text-slate-600 mb-0.5 block">BP사 (이 계획서의 발주처/건설사)</label>
            <select
              value={bpCompanyId}
              onChange={e => setBpCompanyId(e.target.value)}
              className="w-full border border-slate-300 rounded-lg px-2.5 py-1.5 text-sm bg-white"
            >
              <option value="">-- BP사 선택 --</option>
              {bpCompanies.map(c => (
                <option key={c.id} value={c.id}>{c.name}{c.businessNumber ? ` · ${c.businessNumber}` : ''}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="text-[10px] font-medium text-slate-600 mb-0.5 block">장비 공급사 (선택 시 그 공급사의 장비/인원이 로드됨)</label>
            <select
              value={supplierCompanyId}
              onChange={e => setSupplierCompanyId(e.target.value)}
              className="w-full border border-slate-300 rounded-lg px-2.5 py-1.5 text-sm bg-white"
            >
              <option value="">-- 공급사 선택 --</option>
              {supplierCompanies.map(c => (
                <option key={c.id} value={c.id}>{c.name}{c.businessNumber ? ` · ${c.businessNumber}` : ''}</option>
              ))}
            </select>
          </div>
        </div>
        {supplierCompanyId && !loadingSupplierData && (
          <div className="text-xs text-indigo-700">
            로드됨: 장비 <b>{equipments.length}</b>대 · 인원 <b>{persons.length}</b>명
            {persons.length > 0 && ` (역할 분포: ${Object.entries(persons.reduce((m, p) => { p.roles.forEach(r => m[r] = (m[r]||0)+1); return m; }, {} as Record<string, number>)).map(([r, n]) => `${r} ${n}`).join(', ')})`}
          </div>
        )}
      </div>

      {/* ═══ Step 2: 장비/인력 배치 ═══ */}
      <div id="quick-pick" className="card p-4 bg-blue-50 border-blue-200 space-y-3">
        <div className="text-sm font-semibold text-blue-900">Step 2 · 현장 인력 배치 <span className="text-xs font-normal text-blue-700 ml-2">(역할당 여러 명 가능)</span></div>

        <div className="flex gap-2 items-end">
          <Field label="장비">
            <select value={equipmentId} onChange={e => setEquipmentId(e.target.value)} className="min-w-[180px]">
              <option value="">-- 선택 --</option>
              {equipments.map(e => <option key={e.id} value={e.id}>{e.vehicleNo}</option>)}
            </select>
          </Field>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-2">
          {REQUIRED_ROLES.map(r => {
            const assignedIds = roleAssign[r.key];
            const assignedPersonsForRole = assignedIds.map(id => persons.find(p => p.id === id)).filter(Boolean) as Person[];
            const candidates = persons.filter(p => p.roles.includes(r.role as any) && !assignedIds.includes(p.id));
            return (
              <div key={r.key} className="border border-blue-200 bg-white rounded-lg p-2">
                <div className="flex items-center justify-between mb-1.5">
                  <div className="text-xs font-semibold text-slate-700">
                    {r.label}{r.required && <span className="text-rose-500 ml-0.5">*</span>}
                    {assignedPersonsForRole.length > 0 && (
                      <span className="ml-1.5 text-[10px] bg-emerald-100 text-emerald-700 px-1.5 py-0.5 rounded">{assignedPersonsForRole.length}명</span>
                    )}
                  </div>
                </div>

                {assignedPersonsForRole.length > 0 && (
                  <div className="flex flex-wrap gap-1 mb-1.5">
                    {assignedPersonsForRole.map(p => (
                      <span key={p.id} className="inline-flex items-center gap-1 bg-emerald-50 text-emerald-800 text-xs px-2 py-0.5 rounded-full border border-emerald-200">
                        {p.name}
                        <button
                          type="button"
                          onClick={() => setRoleAssign(prev => ({ ...prev, [r.key]: prev[r.key].filter(id => id !== p.id) }))}
                          className="ml-0.5 text-emerald-600 hover:text-rose-600 leading-none"
                          title="제거"
                        >✕</button>
                      </span>
                    ))}
                  </div>
                )}

                {candidates.length > 0 ? (
                  <select
                    value=""
                    onChange={e => {
                      const id = e.target.value;
                      if (!id) return;
                      setRoleAssign(prev => ({ ...prev, [r.key]: [...prev[r.key], id] }));
                    }}
                    className="w-full text-xs"
                  >
                    <option value="">+ 추가</option>
                    {candidates.map(p => (
                      <option key={p.id} value={p.id}>{p.name}{p.company ? ` · ${p.company}` : ''}</option>
                    ))}
                  </select>
                ) : (
                  <div className="text-[10px] text-slate-400 italic">
                    {assignedPersonsForRole.length === 0 ? '등록된 인력 없음' : '모두 배정됨'}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* ═══ 본문: 편집기 전폭 (개별 필드 입력은 편집기 안에서 직접 수정) ═══ */}
      <div className="grid grid-cols-1 gap-4">
        {/* 편집기 ─ Step1/2 에서 선택한 데이터로 자동 채움 + 직접 편집 */}
        <div className="space-y-2">
          <div className="flex items-center justify-between flex-wrap gap-2 bg-slate-50 py-2 sticky top-0 z-10 border-b border-slate-200">
            {embeddedEditor ? (
              <>
                <div className="flex items-center gap-2">
                  <h2 className="text-sm font-semibold text-slate-700">📝 Word 편집기</h2>
                  <span className="text-xs text-slate-400 truncate max-w-[180px]">{embeddedEditor.fileName}</span>
                  {editorLoading && <span className="text-xs text-slate-500">로딩...</span>}
                  {formStaleForEditor && !editorLoading && (
                    <button
                      onClick={refreshEmbeddedEditor}
                      disabled={openingEditor}
                      className="px-2 py-0.5 rounded bg-amber-100 text-amber-800 text-xs font-medium hover:bg-amber-200 border border-amber-300"
                      title="양식 변경사항을 편집기에 반영 (현재 편집 중인 내용은 자동저장 후 덮어씀)"
                    >
                      🔄 양식 변경됨 · 반영
                    </button>
                  )}
                </div>
                <div className="flex gap-1.5 items-center">
                  <button onClick={downloadEmbeddedDocx} disabled={openingEditor} className="btn-ghost text-xs">DOCX</button>
                  <button onClick={downloadEmbeddedPdf} disabled={openingEditor} className="btn-primary text-xs">PDF</button>
                  <button onClick={closeEmbeddedEditor} className="px-2.5 py-1 rounded-md bg-slate-600 text-white text-xs hover:bg-slate-700" title="편집기 닫고 빠른 미리보기로 전환">✕ 닫기</button>
                </div>
              </>
            ) : (
              <>
                <div className="flex items-center gap-2">
                  <h2 className="text-sm font-semibold text-slate-700">미리보기</h2>
                  <div className="flex text-xs bg-slate-200 rounded-md overflow-hidden">
                    <button
                      onClick={() => setPreviewTab('body')}
                      className={`px-2.5 py-1 transition ${previewTab === 'body' ? 'bg-blue-600 text-white font-semibold' : 'text-slate-700 hover:bg-slate-300'}`}
                      title="본문 5페이지만 (빠름)"
                    >본문 <span className="text-[10px] opacity-80">빠름</span></button>
                    <button
                      onClick={() => setPreviewTab('full')}
                      className={`px-2.5 py-1 transition ${previewTab === 'full' ? 'bg-blue-600 text-white font-semibold' : 'text-slate-700 hover:bg-slate-300'}`}
                      title="본문 + 첨부 서류 모두 포함"
                    >첨부 포함 <span className="text-[10px] opacity-80">전체</span></button>
                  </div>
                </div>
                <div className="flex gap-1.5 items-center">
                  <label className="flex items-center gap-1 text-xs">
                    <input type="checkbox" checked={autoPreview} onChange={e => setAutoPreview(e.target.checked)} />
                    자동
                  </label>
                  <div className="flex items-center gap-1 text-xs">
                    <button onClick={() => setZoom(z => Math.max(40, z - 10))} className="px-1.5 py-0.5 border border-slate-300 rounded hover:bg-slate-100">−</button>
                    <span className="w-10 text-center">{zoom}%</span>
                    <button onClick={() => setZoom(z => Math.min(200, z + 10))} className="px-1.5 py-0.5 border border-slate-300 rounded hover:bg-slate-100">+</button>
                    <button onClick={() => setZoom(85)} className="ml-1 px-1.5 py-0.5 border border-slate-300 rounded hover:bg-slate-100" title="85%">맞춤</button>
                  </div>
                  <button onClick={() => generate(false, previewTab === 'full')} disabled={generating} className="btn-ghost text-xs">
                    {generating ? '...' : '↻'}
                  </button>
                  <button onClick={() => generate(true, true)} disabled={generating} className="btn-primary text-xs">
                    다운로드
                  </button>
                </div>
              </>
            )}
          </div>
          <div id="preview-scroll" className="card bg-slate-200 overflow-auto" style={{ height: 'calc(100vh - 120px)', maxHeight: 'calc(100vh - 120px)' }}>
            {embeddedEditor ? (
              <div className="w-full h-full bg-white relative">
                {editorError && (
                  <div className="absolute inset-0 flex items-center justify-center flex-col gap-3 p-8 bg-white/95 z-10">
                    <div className="text-rose-600 text-sm font-semibold">{editorError}</div>
                    <button onClick={closeEmbeddedEditor} className="px-3 py-1.5 rounded-md bg-slate-700 text-white text-sm">닫기</button>
                  </div>
                )}
                {editorLoading && !editorError && (
                  <div className="absolute inset-0 flex items-center justify-center text-slate-500 text-sm bg-white/80 z-10">
                    편집기 로딩 중...
                  </div>
                )}
                <EmbeddedEditor
                  configStr={embeddedEditor.configStr}
                  onReady={() => setEditorLoading(false)}
                  onError={(msg) => { setEditorError(msg); setEditorLoading(false); }}
                  onClose={closeEmbeddedEditor}
                />
              </div>
            ) : (
              <div id="preview-outer" className="p-4">
                <div id="preview-inner" style={{ zoom: zoom / 100 }}>
                  {/* 두 개 컨테이너, 비활성 탭은 숨김 */}
                  <div id="preview-container-body" style={{ display: previewTab === 'body' ? 'block' : 'none' }}>
                    <div className="text-center text-slate-400 text-sm py-20 px-4 bg-white rounded">
                      {autoPreview ? '자동 미리보기 대기...' : '"새로고침" 버튼으로 미리보기'}
                    </div>
                  </div>
                  <div id="preview-container-full" style={{ display: previewTab === 'full' ? 'block' : 'none' }}>
                    <div className="text-center text-slate-400 text-sm py-20 px-4 bg-white rounded">
                      첨부 포함 미리보기 준비 중...
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* ═══ 고정 하단 액션 바 ═══ */}
      <div className="sticky bottom-0 -mx-4 px-4 py-3 bg-white border-t border-slate-200 flex gap-2 justify-between items-center shadow-lg">
        <div className="text-xs text-slate-500">
          {overall === 100 ? '완료 · 모든 필수 항목 준비 완료' : `! 필수 누락: ${[
            !siteOk && '현장명',
            !equipOk && '장비',
            ...assignedPersons.filter(r => r.required && r.people.length === 0).map(r => r.label),
          ].filter(Boolean).join(', ')}`}
        </div>
        <div className="flex gap-2">
          <button onClick={() => generate(false)} disabled={generating} className="btn-ghost">미리보기</button>
          <button onClick={() => generate(true)} disabled={generating} className="btn-ghost">DOCX</button>
          <button onClick={downloadPdf} disabled={generating} className="btn-primary">PDF 다운로드</button>
          <button
            onClick={embeddedEditor ? closeEmbeddedEditor : openWordEditor}
            disabled={generating || openingEditor}
            className={`px-3 py-1.5 rounded-md text-white text-sm font-medium disabled:opacity-50 ${embeddedEditor ? 'bg-slate-600 hover:bg-slate-700' : 'bg-violet-600 hover:bg-violet-700'}`}
            title={embeddedEditor ? '편집 종료(자동 저장)' : '양식으로 채워진 작업계획서를 Word로 자유 편집'}
          >
            {openingEditor ? '처리 중...' : (embeddedEditor ? '✕ 편집 종료' : '📝 Word 편집')}
          </button>
          <label className="px-3 py-1.5 rounded-md bg-amber-500 text-white text-sm font-medium hover:bg-amber-600 disabled:opacity-50 cursor-pointer" title="{{차량번호}} 같은 플레이스홀더를 넣어두면 현재 선택한 데이터로 자동 채움">
            📄 템플릿 업로드 + 자동 채움
            <input
              type="file"
              accept=".docx"
              className="hidden"
              onChange={(e) => {
                const f = e.target.files?.[0];
                if (f) openEditorFromUploadedFile(f);
                e.target.value = '';
              }}
              disabled={openingEditor}
            />
          </label>
          <button
            onClick={() => { setMailMsg(''); setMailOpen(true); }}
            disabled={generating}
            className="px-3 py-1.5 rounded-md bg-emerald-600 text-white text-sm font-medium hover:bg-emerald-700 disabled:opacity-50"
          >
            📧 PDF 메일 발송
          </button>
        </div>
      </div>

      {/* 업로드 템플릿 플레이스홀더 채움 다이얼로그 */}
      {tplDialog && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4" onClick={() => !openingEditor && setTplDialog(null)}>
          <div className="bg-white rounded-xl p-6 max-w-2xl w-full max-h-[85vh] overflow-auto space-y-3 shadow-xl" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-lg font-bold">📄 템플릿 플레이스홀더 채우기</h3>
                <div className="text-xs text-slate-500 mt-0.5">
                  업로드 파일: <b>{tplDialog.fileName}</b> · {tplDialog.scanned.placeholders.length}개 플레이스홀더 발견
                </div>
              </div>
              <button onClick={() => setTplDialog(null)} className="text-slate-400 hover:text-slate-600">✕</button>
            </div>
            <div className="text-xs text-slate-600 bg-amber-50 border border-amber-200 rounded p-2">
              👉 현재 선택한 장비·현장·인원 정보로 <b>자동 채워진 값</b>은 파란색, 수동 입력 필요한 것은 흰색입니다. 비워두면 빈 문자열로 치환됩니다.
            </div>
            <details className="text-xs border border-slate-200 rounded">
              <summary className="cursor-pointer px-3 py-2 bg-slate-50 hover:bg-slate-100 font-medium">
                💡 사용 가능한 표준 플레이스홀더 전체 목록 보기
              </summary>
              <div className="p-3 space-y-2 max-h-64 overflow-auto">
                {PLACEHOLDER_CATALOG.map(sec => (
                  <div key={sec.section}>
                    <div className="font-semibold text-slate-700 mb-1">{sec.section}</div>
                    <div className="grid grid-cols-2 gap-1 text-[11px]">
                      {sec.items.map(it => (
                        <div key={it.key} className="flex gap-1">
                          <code className="bg-slate-100 px-1 rounded text-slate-700">{`{{${it.key}}}`}</code>
                          {it.desc && <span className="text-slate-400 truncate">{it.desc}</span>}
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
                <div className="pt-2 border-t text-[11px] text-slate-500">
                  💬 역할 프리픽스 조합: <code className="bg-slate-100 px-1 rounded">{`{{조종원_이름}}`}</code> <code className="bg-slate-100 px-1 rounded">{`{{유도원_전원}}`}</code> <code className="bg-slate-100 px-1 rounded">{`{{작업지휘자_1}}`}</code>
                </div>
              </div>
            </details>
            <div className="space-y-2">
              {tplDialog.scanned.placeholders.map((p) => {
                const isAuto = !!tplDialog.values[p] && tplDialog.values[p].length > 0;
                return (
                  <div key={p} className="grid grid-cols-[170px_1fr] gap-2 items-center">
                    <div className="text-sm font-mono text-slate-700">{`{{${p}}}`}</div>
                    <input
                      value={tplDialog.values[p] || ''}
                      onChange={(e) => setTplDialog(d => d && ({ ...d, values: { ...d.values, [p]: e.target.value } }))}
                      placeholder="(비움)"
                      className={`px-2 py-1.5 text-sm border rounded-md ${isAuto ? 'bg-sky-50 border-sky-300' : 'border-slate-300'}`}
                    />
                  </div>
                );
              })}
            </div>
            <div className="flex justify-end gap-2 pt-2 sticky bottom-0 bg-white">
              <button onClick={() => setTplDialog(null)} disabled={openingEditor} className="btn-ghost">취소</button>
              <button onClick={confirmTemplateFill} disabled={openingEditor} className="px-4 py-2 rounded-md bg-violet-600 text-white text-sm font-medium hover:bg-violet-700 disabled:opacity-50">
                {openingEditor ? '열고 있음...' : '채우고 Word 편집 열기'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 이메일 발송 다이얼로그 */}
      {mailOpen && (
        <div
          className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
          onClick={() => !mailSending && setMailOpen(false)}
        >
          <div
            className="bg-white rounded-xl p-6 max-w-lg w-full space-y-3 shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold">작업계획서 PDF 이메일 발송</h3>
              <button
                onClick={() => !mailSending && setMailOpen(false)}
                className="text-slate-400 hover:text-slate-600"
                disabled={mailSending}
              >✕</button>
            </div>
            <div className="text-xs text-slate-500">
              현재 작성된 작업계획서가 PDF로 변환되어 첨부파일로 발송됩니다.
            </div>
            <div>
              <label className="text-xs font-medium text-slate-600 block mb-1">
                답장 받을 이메일 <span className="text-slate-400 font-normal">(선택, 수신자가 회신할 주소)</span>
              </label>
              <input
                type="email"
                value={mailForm.from}
                onChange={(e) => setMailForm(f => ({ ...f, from: e.target.value }))}
                placeholder="예: your@company.com (선택)"
                className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
                disabled={mailSending}
              />
            </div>
            <div>
              <label className="text-xs font-medium text-slate-600 block mb-1">받는 사람 <span className="text-rose-500">*</span> (여러 명은 쉼표로)</label>
              <input
                type="text"
                value={mailForm.to}
                onChange={(e) => setMailForm(f => ({ ...f, to: e.target.value }))}
                placeholder="예: manager@site.com, safety@site.com"
                className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
                disabled={mailSending}
              />
            </div>
            <div>
              <label className="text-xs font-medium text-slate-600 block mb-1">제목 (비워두면 자동)</label>
              <input
                type="text"
                value={mailForm.subject}
                onChange={(e) => setMailForm(f => ({ ...f, subject: e.target.value }))}
                placeholder="[SKEP] 작업계획서"
                className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
                disabled={mailSending}
              />
            </div>
            <div>
              <label className="text-xs font-medium text-slate-600 block mb-1">내용</label>
              <textarea
                value={mailForm.body}
                onChange={(e) => setMailForm(f => ({ ...f, body: e.target.value }))}
                placeholder="본문에 함께 보낼 메시지를 작성하세요."
                rows={5}
                className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
                disabled={mailSending}
              />
            </div>
            {mailMsg && (
              <div className={`text-sm px-3 py-2 rounded ${mailMsg.startsWith('✓') ? 'bg-emerald-50 text-emerald-700' : 'bg-rose-50 text-rose-700'}`}>
                {mailMsg}
              </div>
            )}
            <div className="flex justify-end gap-2 pt-2">
              <button
                onClick={() => setMailOpen(false)}
                disabled={mailSending}
                className="btn-ghost"
              >취소</button>
              <button
                onClick={sendMail}
                disabled={mailSending || !mailForm.to.trim()}
                className="px-4 py-2 rounded-md bg-emerald-600 text-white text-sm font-medium hover:bg-emerald-700 disabled:opacity-50"
              >
                {mailSending ? '발송 중... (PDF 변환 ~10초)' : '발송'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── 체크리스트 아이템 ─────────────────────────────────
function ChecklistItem({ done, required, label, onClick }: { done: boolean; required?: boolean; label: string; onClick?: () => void }) {
  const color = done ? 'border-emerald-300 bg-emerald-50 text-emerald-800' :
    required ? 'border-rose-300 bg-rose-50 text-rose-800' : 'border-slate-200 bg-slate-50 text-slate-500';
  return (
    <button onClick={onClick} className={`border rounded-lg px-2 py-1.5 flex items-center gap-1.5 text-left hover:shadow transition ${color}`}>
      <span>{done ? '✓' : required ? '!' : '○'}</span>
      <span className="truncate">{label}</span>
    </button>
  );
}

// ─── 섹션 카드 ─────────────────────────────────────────
function SectionCard({ section, values, onChange, onAiRewrite, open, onToggle, filter, persons }: {
  section: TemplateSection; values: any; onChange: any; onAiRewrite: any; open: boolean; onToggle: () => void; filter?: string; persons?: Person[];
}) {
  const q = (filter || '').trim().toLowerCase();
  const fields = q
    ? section.fields.filter(f => f.label.toLowerCase().includes(q) || f.key.toLowerCase().includes(q))
    : section.fields;
  const titleMatch = q && section.title.toLowerCase().includes(q);
  const highlight = (text: string) => {
    if (!q) return text;
    const i = text.toLowerCase().indexOf(q);
    if (i < 0) return text;
    return <>{text.slice(0, i)}<mark className="bg-yellow-200 rounded px-0.5">{text.slice(i, i + q.length)}</mark>{text.slice(i + q.length)}</>;
  };
  return (
    <section className="card">
      <button onClick={onToggle} className="w-full px-3 py-2 flex items-center justify-between hover:bg-slate-50 text-left text-sm">
        <span>
          <span className="text-xs font-mono text-slate-400 mr-1.5">{section.page.toUpperCase()}</span>
          <span className="font-semibold text-slate-800">{titleMatch ? highlight(section.title) : section.title}</span>
          {section.aiRewritable && <span className="badge bg-purple-100 text-purple-700 ml-1.5 text-[10px]">AI</span>}
          {q && <span className="text-[10px] text-slate-400 ml-1.5">({fields.length}/{section.fields.length})</span>}
        </span>
        <span className="text-slate-400">{open ? '▾' : '▸'}</span>
      </button>
      {open && fields.length > 0 && section.id === 'p1_signatures' && (
        <div className="px-3 pb-3 border-t border-slate-100 pt-2">
          <SignatureTable values={values} onChange={onChange} persons={persons || []} />
        </div>
      )}
      {open && fields.length > 0 && section.id !== 'p1_signatures' && (
        <div className="px-3 pb-3 grid grid-cols-2 gap-1.5 border-t border-slate-100 pt-2">
          {fields.map((f: TemplateField) => (
            <FieldInput key={f.key} field={f} value={values[f.key]} onChange={onChange} onAiRewrite={onAiRewrite} highlight={highlight} />
          ))}
        </div>
      )}
    </section>
  );
}

// ─── 서명 전용 표 (5행, 인력 드롭다운) ─────────────────────
const SIGNATURE_ROWS = [
  { idx: 0, label: '작성자', defaultPosition: 'Biz.P 현장소장' },
  { idx: 1, label: '담당자', defaultPosition: 'SKEP 관리감독자' },
  { idx: 2, label: '확인자', defaultPosition: 'SKEP HYPER' },
  { idx: 3, label: '검토자', defaultPosition: 'SKEP 안전관리자' },
  { idx: 4, label: '승인자', defaultPosition: 'SKEP 현장총괄' },
];

function SignatureTable({ values, onChange, persons }: { values: any; onChange: any; persons: Person[] }) {
  return (
    <div className="space-y-1.5">
      <div className="grid grid-cols-[60px_1fr_1fr_110px] gap-1.5 text-[10px] font-semibold text-slate-500 px-1">
        <div>구분</div><div>이름 (인력 선택)</div><div>직위</div><div>일자</div>
      </div>
      {SIGNATURE_ROWS.map(r => {
        const nameKey = `sig${r.idx}_name`;
        const posKey = `sig${r.idx}_position`;
        const dateKey = `sig${r.idx}_date`;
        const currentName = values[nameKey] || '';
        const selectedPerson = persons.find(p => p.name === currentName);
        return (
          <div key={r.idx} className="grid grid-cols-[60px_1fr_1fr_110px] gap-1.5 items-center">
            <div className="text-[11px] font-medium text-slate-700 bg-slate-100 px-1.5 py-1.5 rounded text-center">{r.label}</div>
            <div className="relative">
              <select
                value={selectedPerson?.id || '__manual__'}
                onChange={e => {
                  const v = e.target.value;
                  if (v === '__manual__') return; // 수동 입력 유지
                  if (v === '__clear__') { onChange(nameKey, ''); return; }
                  const p = persons.find(x => x.id === v);
                  if (p) onChange(nameKey, p.name);
                }}
                className="w-full border border-slate-300 rounded px-1.5 py-1 text-xs bg-white"
              >
                <option value="__manual__">{currentName || '-- 인력 선택 or 직접입력 --'}</option>
                <option value="__clear__">(지우기)</option>
                {persons.map(p => (
                  <option key={p.id} value={p.id}>{p.name}{p.company ? ` · ${p.company}` : ''}</option>
                ))}
              </select>
              <input
                data-field-key={nameKey}
                type="text"
                value={currentName}
                onChange={e => onChange(nameKey, e.target.value)}
                placeholder="직접 입력"
                className="w-full border border-slate-300 rounded px-1.5 py-1 text-xs mt-0.5"
              />
            </div>
            <input
              data-field-key={posKey}
              type="text"
              value={values[posKey] ?? r.defaultPosition}
              onChange={e => onChange(posKey, e.target.value)}
              className="w-full border border-slate-300 rounded px-1.5 py-1 text-xs"
            />
            <input
              data-field-key={dateKey}
              type="date"
              value={values[dateKey] || ''}
              onChange={e => onChange(dateKey, e.target.value)}
              className="w-full border border-slate-300 rounded px-1.5 py-1 text-xs"
            />
          </div>
        );
      })}
    </div>
  );
}

// ─── 필드 입력 ─────────────────────────────────────────
function FieldInput({ field, value, onChange, onAiRewrite, highlight }: any) {
  const label = highlight ? highlight(field.label) : field.label;
  if (field.type === 'checkbox') {
    return (
      <label className="col-span-1 flex items-center gap-1.5 p-1.5 border border-slate-200 rounded text-xs cursor-pointer hover:bg-slate-50">
        <input data-field-key={field.key} type="checkbox" checked={!!value} onChange={e => onChange(field.key, e.target.checked)} />
        <span className="truncate">{label}</span>
      </label>
    );
  }
  if (field.type === 'textarea') {
    return (
      <div className="col-span-2">
        <div className="flex justify-between items-center mb-0.5">
          <label className="text-[10px] font-medium text-slate-600">{label}</label>
          {field.aiPrompt && (
            <button onClick={() => onAiRewrite(field)} className="text-[10px] text-purple-600 hover:underline">
              AI 재작성
            </button>
          )}
        </div>
        <textarea data-field-key={field.key} rows={2} className="w-full border border-slate-300 rounded px-2 py-1 text-xs" value={value || ''} onChange={e => onChange(field.key, e.target.value)} />
      </div>
    );
  }
  if (field.type === 'date') {
    return (
      <div>
        <label className="text-[10px] font-medium text-slate-600 block">{label}</label>
        <input data-field-key={field.key} type="date" className="w-full border border-slate-300 rounded px-2 py-1 text-xs" value={value || ''} onChange={e => onChange(field.key, e.target.value)} />
      </div>
    );
  }
  return (
    <div>
      <label className="text-[10px] font-medium text-slate-600 block">{label}</label>
      <input data-field-key={field.key} type="text" className="w-full border border-slate-300 rounded px-2 py-1 text-xs" value={value || ''} onChange={e => onChange(field.key, e.target.value)} placeholder={field.placeholder} />
    </div>
  );
}

function Field({ label, children }: { label: string; children: any }) {
  return (
    <div>
      <label className="text-[10px] font-medium text-slate-600 mb-0.5 block">{label}</label>
      {children}
    </div>
  );
}
