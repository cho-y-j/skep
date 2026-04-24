// 인증 필요 이미지 로더
// /api/documents/{id}/file (JWT 필요) 이미지를 fetch → blob URL → img src
import { useEffect, useState } from "react";

const blobCache = new Map<string, string>();

interface AuthImageProps extends React.ImgHTMLAttributes<HTMLImageElement> {
  docId: string;
}

export function AuthImage({ docId, alt = "", ...rest }: AuthImageProps) {
  const [src, setSrc] = useState<string | null>(() => blobCache.get(docId) || null);

  useEffect(() => {
    if (blobCache.has(docId)) {
      setSrc(blobCache.get(docId)!);
      return;
    }
    let cancelled = false;
    (async () => {
      try {
        const token = localStorage.getItem("skep_token") || "";
        const res = await fetch(`/api/documents/${docId}/file`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (!res.ok) throw new Error(`${res.status}`);
        const blob = await res.blob();
        const url = URL.createObjectURL(blob);
        blobCache.set(docId, url);
        if (!cancelled) setSrc(url);
      } catch {
        if (!cancelled) setSrc(null);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [docId]);

  if (!src) {
    return (
      <div
        className={rest.className}
        style={{ background: "#e2e8f0", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 10, color: "#94a3b8" }}
      >
        로딩...
      </div>
    );
  }
  return <img src={src} alt={alt} {...rest} />;
}
