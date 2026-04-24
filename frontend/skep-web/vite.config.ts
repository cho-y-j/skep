import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import path from "path";

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  server: {
    host: true,                 // WSL에서 Windows 브라우저가 접근 가능하도록 모든 인터페이스 바인딩
    port: 5173,
    strictPort: true,
    hmr: false,                  // HMR 완전 비활성화 — 에러 루프 방지 (수동 F5로 갱신)
    watch: {
      // /mnt/c (WSL-Windows 브릿지)에서는 fs.watch가 신뢰성이 낮아 폴링 필요
      usePolling: true,
      interval: 400,
    },
    proxy: {
      "/api": {
        // 54.116.90.179:9080 은 방화벽으로 외부 차단 → HTTPS 도메인 통해 접근
        target: process.env.VITE_API_PROXY || "https://skep.on1.kr",
        changeOrigin: true,
        secure: false,
        // 서버 CORS 허용 목록에 localhost:5173 이 없어서 403 → 서버가 자기 자신을 origin으로 인식하도록 재작성
        configure: (proxy) => {
          proxy.on("proxyReq", (proxyReq) => {
            proxyReq.setHeader("origin", "https://skep.on1.kr");
            proxyReq.setHeader("referer", "https://skep.on1.kr/");
          });
        },
      },
      "/onlyoffice": {
        target: process.env.VITE_ONLYOFFICE_PROXY || "https://skep.on1.kr",
        changeOrigin: true,
        secure: false,
        ws: true,
        // 서버는 X-Frame-Options:sameorigin 을 붙여서 localhost 에서 iframe 로드를 막는다.
        // 로컬 dev 한정으로 해당 헤더 제거해 iframe embedding 허용.
        configure: (proxy) => {
          proxy.on("proxyRes", (proxyRes) => {
            delete proxyRes.headers["x-frame-options"];
            delete proxyRes.headers["content-security-policy"];
          });
        },
      },
    },
  },
});
