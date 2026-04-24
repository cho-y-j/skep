// WorkPlanCreate 내부에 임베드되는 OnlyOffice 편집기 (새 탭 이동 없이 미리보기 자리에서 편집).
// WHY memo: OnlyOffice는 DIV에 DOM을 직접 주입하므로, 부모 리렌더가 일어나면 React 재조정과 충돌해
// insertBefore failed 에러 발생. memo(() => true) 로 리렌더를 완전히 차단한다.
import { memo, useEffect, useRef } from 'react';

declare global {
  interface Window { DocsAPI?: any; docEditorEmbedded?: any; }
}

const ONLYOFFICE_API_SCRIPT = '/onlyoffice/web-apps/apps/api/documents/api.js';

export interface EmbeddedEditorProps {
  configStr: string;
  onReady?: () => void;
  onError?: (msg: string) => void;
  onClose?: () => void;
}

export const EmbeddedEditor = memo(function EmbeddedEditor({
  configStr, onReady, onError, onClose,
}: EmbeddedEditorProps) {
  const hostRef = useRef<HTMLDivElement>(null);
  const cbRef = useRef({ onReady, onError, onClose });
  cbRef.current = { onReady, onError, onClose };

  useEffect(() => {
    const host = hostRef.current;
    if (!host) return;

    // 내부 컨테이너를 마운트 (OnlyOffice가 여기에 DOM 주입)
    const inner = document.createElement('div');
    inner.id = 'onlyoffice-embedded-container';
    inner.style.width = '100%';
    inner.style.height = '100%';
    host.appendChild(inner);

    const init = () => {
      try {
        const config = JSON.parse(configStr);
        config.width = '100%';
        config.height = '100%';
        config.events = {
          onDocumentReady: () => cbRef.current.onReady?.(),
          onError: (e: any) => cbRef.current.onError?.('편집기 오류: ' + (e?.data || e?.error || 'unknown')),
          onRequestClose: () => cbRef.current.onClose?.(),
        };
        window.docEditorEmbedded = new window.DocsAPI!.DocEditor('onlyoffice-embedded-container', config);
      } catch (e: any) {
        cbRef.current.onError?.('초기화 실패: ' + (e?.message || e));
      }
    };

    if (window.DocsAPI) {
      init();
    } else {
      const existing = document.querySelector(`script[src="${ONLYOFFICE_API_SCRIPT}"]`) as HTMLScriptElement | null;
      if (existing) {
        existing.addEventListener('load', init);
      } else {
        const script = document.createElement('script');
        script.src = ONLYOFFICE_API_SCRIPT;
        script.onload = init;
        script.onerror = () => cbRef.current.onError?.('OnlyOffice 스크립트 로드 실패');
        document.head.appendChild(script);
      }
    }

    return () => {
      try { window.docEditorEmbedded?.destroyEditor?.(); window.docEditorEmbedded = undefined; } catch { /* noop */ }
      try { if (inner.parentNode === host) host.removeChild(inner); } catch { /* noop */ }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return <div ref={hostRef} className="w-full h-full" />;
}, () => true);
