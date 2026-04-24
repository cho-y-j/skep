// OnlyOffice Document Server iframe 편집 페이지
// 흐름: sessionStorage에 editorConfig 저장해두고 이 페이지에서 꺼내 init.
// WHY memo: OnlyOffice가 DIV에 DOM을 직접 주입하기 때문에, 부모가 리렌더될 때 React가
//           해당 DIV children을 재조정하려다 "insertBefore failed" 에러를 낸다.
//           EditorMount를 memo로 격리해 부모 state(loading/err/mail 등) 변화에 리렌더 안 되게 함.
import { memo, useEffect, useRef, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import client from '@/api/client';

declare global {
  interface Window { DocsAPI?: any; docEditor?: any; }
}

const ONLYOFFICE_API_SCRIPT = '/onlyoffice/web-apps/apps/api/documents/api.js';

interface MountProps {
  configStr: string;
  onReady: () => void;
  onError: (msg: string) => void;
  onClose: () => void;
}

// OnlyOffice container를 React 트리 바깥(document.body 직접 append)에 렌더.
// WHY: OnlyOffice + DevTools/확장이 주입하는 DOM을 React가 reconciliation 대상으로 삼으면
//       insertBefore failed 에러가 난다. 트리 밖이면 React 관여 없음.
const EditorMount = memo(function EditorMount({ configStr, onReady, onError, onClose, anchorRect }: MountProps & { anchorRect: { top: number; left: number; width: number; height: number } }) {
  useEffect(() => {
    const host = document.createElement('div');
    host.id = 'onlyoffice-host';
    Object.assign(host.style, {
      position: 'fixed',
      top: anchorRect.top + 'px',
      left: anchorRect.left + 'px',
      width: anchorRect.width + 'px',
      height: anchorRect.height + 'px',
      zIndex: '40',
    });
    const inner = document.createElement('div');
    inner.id = 'onlyoffice-container';
    inner.style.width = '100%';
    inner.style.height = '100%';
    host.appendChild(inner);
    document.body.appendChild(host);

    const init = () => {
      try {
        const config = JSON.parse(configStr);
        config.width = '100%';
        config.height = '100%';
        config.events = {
          onDocumentReady: onReady,
          onError: (e: any) => onError('편집기 오류: ' + (e?.data || e?.error || 'unknown')),
          onRequestClose: onClose,
        };
        window.docEditor = new window.DocsAPI!.DocEditor('onlyoffice-container', config);
      } catch (e: any) {
        onError('초기화 실패: ' + (e?.message || e));
      }
    };

    if (window.DocsAPI) {
      init();
    } else {
      const script = document.createElement('script');
      script.src = ONLYOFFICE_API_SCRIPT;
      script.onload = init;
      script.onerror = () => onError('OnlyOffice 스크립트 로드 실패');
      document.head.appendChild(script);
    }

    // 창 크기 변경 시 host 크기 갱신
    const onResize = () => {
      host.style.top = '56px';
      host.style.left = '0px';
      host.style.width = window.innerWidth + 'px';
      host.style.height = (window.innerHeight - 56) + 'px';
    };
    window.addEventListener('resize', onResize);

    return () => {
      window.removeEventListener('resize', onResize);
      try { window.docEditor?.destroyEditor?.(); window.docEditor = undefined; } catch { /* noop */ }
      try { host.remove(); } catch { /* noop */ }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return null;
}, () => true);

export default function WorkPlanEditor() {
  const { sessionId = '' } = useParams();
  const nav = useNavigate();
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState('');
  const [sending, setSending] = useState(false);
  const [mailOpen, setMailOpen] = useState(false);
  const [mail, setMail] = useState({ from: '', to: '', subject: '', body: '' });
  const [mailMsg, setMailMsg] = useState('');

  const fileName = sessionStorage.getItem(`worksheet-editor-${sessionId}-fileName`) || 'worksheet.docx';
  const configStr = sessionStorage.getItem(`worksheet-editor-${sessionId}-config`);

  // 안정 콜백 참조
  const cbRef = useRef({
    ready: () => setLoading(false),
    err: (msg: string) => { setErr(msg); setLoading(false); },
    close: () => nav(-1),
  });

  useEffect(() => {
    if (!configStr) {
      setErr('편집 세션을 찾을 수 없습니다. 작업계획서 생성 화면으로 돌아가 다시 시도해주세요.');
      setLoading(false);
    }
  }, [configStr]);

  // OnlyOffice는 "저장 완료" 이벤트를 직접 쏘지 않아 callback 처리(다운로드→파일 덮어쓰기)의
  // 종료를 동기적으로 알 방법이 없다. 서버 측 반영까지 여유 1.2초 대기.
  const forceSave = async (): Promise<void> => {
    try { window.docEditor?.serviceCommand?.('forcesave'); } catch { /* noop */ }
    await new Promise(r => setTimeout(r, 1200));
  };

  const downloadDocx = async () => {
    await forceSave();
    const base = fileName.replace(/\.docx$/i, '');
    window.open(`/api/worksheet/editor-session/${sessionId}/download?name=${encodeURIComponent(base)}`, '_blank');
  };

  const downloadPdf = async () => {
    setSending(true);
    try {
      await forceSave();
      const base = fileName.replace(/\.docx$/i, '');
      const res = await client.get(`/api/worksheet/editor-session/${sessionId}/pdf?name=${encodeURIComponent(base)}`, {
        responseType: 'blob',
      });
      const blob = res.data instanceof Blob ? res.data : new Blob([res.data], { type: 'application/pdf' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url; a.download = `${base}.pdf`; a.click();
      URL.revokeObjectURL(url);
    } catch (e: any) {
      alert('PDF 실패: ' + (e?.message || e));
    } finally { setSending(false); }
  };

  const sendMail = async () => {
    if (!mail.to.trim()) { setMailMsg('받는 사람 입력'); return; }
    setSending(true);
    setMailMsg('');
    try {
      await forceSave();
      // 편집본 DOCX 내려받아 send-pdf 재사용
      const docxRes = await client.get(`/api/worksheet/editor-session/${sessionId}/download?name=raw`, { responseType: 'blob' });
      const docxBlob = docxRes.data instanceof Blob ? docxRes.data : new Blob([docxRes.data]);
      const fd = new FormData();
      fd.append('file', docxBlob, fileName);
      fd.append('name', fileName.replace(/\.docx$/i, ''));
      if (mail.from.trim()) fd.append('from', mail.from.trim());
      fd.append('to', mail.to.trim());
      if (mail.subject.trim()) fd.append('subject', mail.subject.trim());
      if (mail.body.trim()) fd.append('body', mail.body);
      const res: any = await client.post('/api/worksheet/send-pdf', fd, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      const payload = res?.data ?? res;
      if (payload?.ok === false) setMailMsg(payload.message || '발송 실패');
      else {
        setMailMsg(`✓ ${payload?.to} 로 발송 완료`);
        setTimeout(() => { setMailOpen(false); setMailMsg(''); }, 1500);
      }
    } catch (e: any) {
      setMailMsg('발송 실패: ' + (e?.response?.data?.message || e?.message || e));
    } finally { setSending(false); }
  };

  return (
    <div className="fixed inset-0 flex flex-col bg-slate-100 z-40">
      <div className="flex items-center justify-between px-4 py-2 bg-white border-b border-slate-200 shadow-sm">
        <div className="flex items-center gap-3">
          <button onClick={() => nav(-1)} className="text-sm text-slate-600 hover:text-slate-900">← 돌아가기</button>
          <div className="text-sm font-semibold text-slate-800 truncate max-w-md">📝 {fileName}</div>
          <span className="text-xs text-slate-400">(자동 저장 · Word처럼 자유 편집)</span>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={downloadDocx} disabled={sending} className="px-3 py-1.5 rounded-md border border-slate-300 text-sm hover:bg-slate-50 disabled:opacity-50">DOCX 다운로드</button>
          <button onClick={downloadPdf} disabled={sending} className="px-3 py-1.5 rounded-md bg-indigo-600 text-white text-sm hover:bg-indigo-700 disabled:opacity-50">PDF 다운로드</button>
          <button onClick={() => { setMailMsg(''); setMailOpen(true); }} disabled={sending} className="px-3 py-1.5 rounded-md bg-emerald-600 text-white text-sm hover:bg-emerald-700 disabled:opacity-50">📧 PDF 메일 발송</button>
        </div>
      </div>

      <div className="flex-1 relative">
        {loading && !err && (
          <div className="absolute inset-0 flex items-center justify-center text-slate-500 text-sm bg-white/80">
            편집기 로딩 중...
          </div>
        )}
        {err && (
          <div className="absolute inset-0 flex items-center justify-center flex-col gap-3 p-8">
            <div className="text-rose-600 font-semibold">{err}</div>
            <button onClick={() => nav(-1)} className="px-4 py-2 rounded-md bg-slate-700 text-white text-sm">돌아가기</button>
          </div>
        )}
        {configStr && (
          <EditorMount
            configStr={configStr}
            onReady={cbRef.current.ready}
            onError={cbRef.current.err}
            onClose={cbRef.current.close}
            anchorRect={{ top: 56, left: 0, width: window.innerWidth, height: window.innerHeight - 56 }}
          />
        )}
      </div>

      {mailOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4" onClick={() => !sending && setMailOpen(false)}>
          <div className="bg-white rounded-xl p-6 max-w-lg w-full space-y-3 shadow-xl" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold">편집본 PDF 이메일 발송</h3>
              <button onClick={() => !sending && setMailOpen(false)} className="text-slate-400 hover:text-slate-600">✕</button>
            </div>
            <div>
              <label className="text-xs font-medium text-slate-600 block mb-1">답장 받을 이메일 <span className="text-slate-400 font-normal">(선택)</span></label>
              <input type="email" value={mail.from} onChange={e => setMail(m => ({ ...m, from: e.target.value }))} placeholder="your@company.com" className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm" disabled={sending} />
            </div>
            <div>
              <label className="text-xs font-medium text-slate-600 block mb-1">받는 사람 <span className="text-rose-500">*</span></label>
              <input type="text" value={mail.to} onChange={e => setMail(m => ({ ...m, to: e.target.value }))} placeholder="manager@site.com" className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm" disabled={sending} />
            </div>
            <div>
              <label className="text-xs font-medium text-slate-600 block mb-1">제목</label>
              <input type="text" value={mail.subject} onChange={e => setMail(m => ({ ...m, subject: e.target.value }))} placeholder="[SKEP] 작업계획서" className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm" disabled={sending} />
            </div>
            <div>
              <label className="text-xs font-medium text-slate-600 block mb-1">내용</label>
              <textarea value={mail.body} onChange={e => setMail(m => ({ ...m, body: e.target.value }))} rows={4} className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm" disabled={sending} />
            </div>
            {mailMsg && <div className={`text-sm px-3 py-2 rounded ${mailMsg.startsWith('✓') ? 'bg-emerald-50 text-emerald-700' : 'bg-rose-50 text-rose-700'}`}>{mailMsg}</div>}
            <div className="flex justify-end gap-2 pt-2">
              <button onClick={() => setMailOpen(false)} disabled={sending} className="btn-ghost">취소</button>
              <button onClick={sendMail} disabled={sending || !mail.to.trim()} className="px-4 py-2 rounded-md bg-emerald-600 text-white text-sm disabled:opacity-50">
                {sending ? '발송 중...' : '발송'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
