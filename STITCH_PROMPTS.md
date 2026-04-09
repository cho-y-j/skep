# SKEP Stitch 프롬프트 — 로그인 + 관리자 대시보드

---

## 프롬프트 1: 로그인 페이지

Design a modern B2B SaaS login page for "SKEP" — an industrial construction site equipment deployment management platform.

**Page layout:**
- Centered card (max-width 420px) on a light gray (#F8FAFC) background
- Card has white background, rounded corners (12px), subtle shadow

**Card contents (top to bottom):**
- Logo: Blue square icon with "S" letter + "SKEP" text in blue (#2563EB)
- Subtitle: "산업현장 장비 투입 관리 플랫폼" in gray
- Email input field with label "이메일" and placeholder "이메일 주소를 입력하세요"
- Password input field with label "비밀번호", placeholder "비밀번호를 입력하세요", and a visibility toggle icon on the right
- "비밀번호를 잊으셨나요?" link aligned right, blue text
- Full-width blue (#2563EB) button "로그인" with white text, rounded
- Divider with "또는" text centered
- "계정이 없으신가요? 회원가입" text with blue link

**Style:** Clean, minimal, professional. No illustrations. Google Material Design 3 style inputs and buttons. Font: Inter or Pretendard.

---

## 프롬프트 2: 어드민 대시보드 — 레이아웃

Design the main admin dashboard layout for "SKEP" B2B SaaS platform.

**Layout structure:**
- Left sidebar: 240px wide, dark navy background (#1E293B)
- Top bar: white background, 60px height, bottom border (#E2E8F0)
- Main content area: light gray (#F8FAFC) background

**Sidebar contents:**
- Top: Blue square "S" logo + "SKEP" text in white
- Divider line (#334155)
- Menu items with Material icons (20px) + label text (14px). Inactive items: gray (#94A3B8). Active item: white text on blue (#2563EB) highlight background.
- Menu items in order:
  1. dashboard — 대시보드
  2. people — 회원 관리 (expandable with sub-items: 사용자 목록, 회사 목록)
  3. description — 서류 유형 관리
  4. construction — 장비 유형 설정
  5. badge — 인력 유형 설정
  6. apartment — BP사 관리
  7. precision_manufacturing — 장비 현황
  8. rocket_launch — 투입 관리
  9. map — 현장 관리
  10. request_quote — 견적 관리
  11. checklist — 투입 체크리스트
  12. folder_open — 서류 관리
  13. safety_check — 점검 관리
  14. payments — 정산
  15. bar_chart — 통계
  16. notifications — 알림/메시지
  17. location_on — 실시간 위치
  18. preview — 서류 미리보기
  19. verified_user — 검증 관리
- Bottom: Divider, user avatar circle + name "관리자" + logout icon, gray text

**Top bar:**
- Left: Page title "대시보드" bold 18px
- Right: notifications bell icon with red badge "3" + user circle "관" + dropdown arrow

**Style:** Dark sidebar with clean contrast. Material Design 3. Professional B2B SaaS feel. Similar to Linear, Vercel dashboard, or Retool admin panel style.

---

## 프롬프트 3: 어드민 대시보드 — 홈 화면

Design the admin dashboard home page content area for "SKEP" platform.

**Top section — 4 stat cards in a row:**
- Card 1: icon "business" in blue circle, number "12", label "등록 회사"
- Card 2: icon "build" in green circle, number "28", label "등록 장비"
- Card 3: icon "person" in amber circle, number "45", label "등록 인원"
- Card 4: icon "rocket_launch" in purple circle, number "8", label "투입 중"
- Each card: white background, rounded 12px, shadow-sm, icon top-left, large number, small label below

**Middle section — 2 columns:**

Left column — "최근 활동" card:
- Card title "최근 활동" with "more_horiz" icon
- List of 5 activity items, each with:
  - Small colored dot (green/blue/amber)
  - Activity text: "크레인 투입 승인", "판교현장 견적 요청" etc.
  - Timestamp: "2시간 전", "오늘 09:15" etc.
  - Status badge on right

Right column — "만료 임박 서류" card:
- Card title "만료 임박 서류" with warning icon
- List of document items, each with:
  - Document icon
  - Document name + owner: "김기사 운전면허증"
  - D-day badge: red "D-7", amber "D-15", amber "D-22"
  - Expiry date text

**Bottom right corner:** Floating refresh button

**Style:** Dashboard cards with clean spacing (24px gap). Numbers are large (28px bold). Labels are small (13px gray). White cards on gray background. No clutter.

---

## 프롬프트 4: 어드민 — 회사 목록 페이지

Design a company management list page for "SKEP" admin dashboard.

**Header row:**
- Page title "회사 목록" left-aligned
- "회사 추가" blue contained button with "add" icon, right-aligned

**Filter row below header:**
- Search input with "search" icon, placeholder "회사명, 사업자번호 검색"
- Dropdown "유형": 전체 / 공급사 / BP사
- Dropdown "상태": 전체 / 활성 / 정지

**Data table:**
- Columns: 회사명, 사업자번호, 유형, 대표자, 상태, 가입일, 액션
- 유형 column: "BP사" in blue chip, "공급사" in green chip
- 상태 column: "활성" green badge, "정지" red badge
- 액션 column: toggle button or "정지"/"활성화" text button
- Table has alternating row colors (white / #F8FAFC)
- Sample data rows:
  - 현대건설 | 123-45-67890 | BP사 | 홍길동 | 활성 | 2026-03-01
  - 삼성중공업 | 234-56-78901 | 공급사 | 이순신 | 활성 | 2026-03-05
  - GS건설 | 345-67-89012 | BP사 | 김건설 | 정지 | 2026-03-10

**Pagination:** Bottom right, "1 2 3 >" style

**Style:** Clean data table. Subtle borders. Status badges with colored backgrounds. Professional admin panel look.

---

## 프롬프트 5: 어드민 — 장비 현황 페이지

Design an equipment status list page for "SKEP" admin dashboard.

**Header row:**
- Title "장비 현황"
- "장비 추가" blue button with "add" icon

**Filter row:**
- Search: "차량번호, 모델명 검색"
- Dropdown: 상태 (전체/활성/정비중/비활성)

**Data table:**
- Columns: 차량번호, 장비 타입, 모델/제조사, 공급사, 상태, 사전점검
- Sample rows:
  - 서울11가1111 | 대형 크레인 | LIEBHERR LTM 1300 | 삼성중공업 | [활성] green | [통과] green
  - 경기22나2222 | 굴삭기 | CAT 320 | 삼성중공업 | [활성] green | [대기] amber
  - 인천33다3333 | 지게차 | Clark C500 | 삼성중공업 | [정비중] amber | [미실시] gray

**Style:** Same table style as company list. Equipment type shown as subtle chip/tag.

---

## 프롬프트 6: 어드민 — 현장 관리 페이지

Design a construction site management page for "SKEP" admin dashboard.

**Header row:**
- Title "현장 관리"
- "현장 등록" blue button with "add" icon

**Site list — expandable rows:**

Each row shows: 현장명, 주소, BP사, 범위유형(원형/폴리곤), 상태, expand arrow

When expanded, shows a map preview:
- For CIRCLE type: Map with a red marker at center point and a semi-transparent blue circle showing the radius boundary (e.g., 300m)
- For POLYGON type: Map with a semi-transparent blue polygon overlay and small blue dots at each vertex
- Below map: address text, coordinates, radius/area info

**Sample data:**
- 강남역 오피스빌딩 | 서울 강남구 | 현대건설 | 원형 | [활성]
  - Expanded: Map showing Seoul Gangnam area with blue circle overlay
- 판교 아파트단지 | 경기 성남시 | 현대건설 | 폴리곤 | [활성]
  - Expanded: Map showing Pangyo area with blue polygon overlay

**Style:** Map uses OpenStreetMap tiles. Clean expansion animation. Map preview is 200px height with rounded corners.

---

## 프롬프트 7: 어드민 — 견적 관리 페이지

Design a quotation management page with tabs for "SKEP" admin dashboard.

**Two tabs at top:** "견적 요청" | "견적서"

**Tab 1: 견적 요청**
- "견적 요청" blue button top-right
- Table columns: 제목, 현장, BP사, 희망기간, 상태, 요청일
- Status badges: PENDING=amber, QUOTED=blue, ACCEPTED=green, REJECTED=red
- Sample: "크레인 2대 + 굴삭기 1대" | 강남역 | 현대건설 | 05/01~05/31 | [승인] green

**Tab 2: 견적서**
- "견적서 작성" blue button top-right
- Table columns: 견적요청, 공급사, 총액, 상태, 생성일
- Sample: "크레인 2대" | 삼성중공업 | 45,000,000원 | [승인] green

**When clicking a quotation row, show detail panel:**
- Items table: 장비종류, 수량, 일단가, 야간, 인건비포함, 비고
- Footer: 합계 금액
- Action buttons based on status: [제출] for DRAFT, [승인][거절] for SUBMITTED

**Style:** Tab navigation with underline indicator. Currency formatted with commas. Detail panel slides down or opens as a dialog.

---

## 프롬프트 8: 어드민 — 투입 체크리스트 페이지

Design a deployment checklist page for "SKEP" admin dashboard.

**Top:** Dropdown selector "투입 계획 선택" with plan options

**After selecting a plan, show:**

**Status badge:** Large badge showing overall status — "PASSED" green, "PENDING" amber, or "OVERRIDDEN" purple

**Checklist — 7 items with toggle switches:**
1. 견적 확정 — toggle on/off
2. 서류 검증 — toggle on/off
3. 면허 검증 — toggle on/off
4. 안전점검 통과 — toggle on/off
5. 건강검진 완료 — toggle on/off
6. 인력 배정 — toggle on/off
7. 장비 배정 — toggle on/off

Each item: Material icon + label + toggle switch. When all 7 are on, overall status becomes "PASSED" with green background.

**Assignment section below checklist:**
- "배정 관리" section title
- Equipment dropdown: "서울11가1111 - 대형크레인"
- Driver dropdown: "김기사"
- Guide multi-select chips: [최유도] [정안내]
- [배정] blue button
- Current assignment info card: green background, showing assigned equipment + driver + guides

**Bottom buttons:** [저장] primary, [강제 통과] outlined/warning

**Style:** Card-based layout. Toggles use Material switch style. Clean grouping with section dividers.

---

## 프롬프트 9: 어드민 — 검증 관리 페이지

Design a verification management page with tabs for "SKEP" admin dashboard.

**Four tabs:** "운전면허" | "사업자등록" | "화물자격" | "일괄 검증"

**Tabs 1-3: Individual verification**
Each tab has:
- Input fields in a card (specific to each type)
  - Tab 1: 면허번호 + 이름
  - Tab 2: 사업자번호
  - Tab 3: 이름 + 생년월일 + 자격번호
- [검증 실행] blue button
- Result card below:
  - Success: Green border card with check_circle icon, "유효한 면허증입니다" text, detailed JSON result
  - Failure: Red border card with cancel icon, "유효하지 않은 번호입니다" text
  - Unknown: Amber border card with help icon, "확인할 수 없습니다" text

**Tab 4: 일괄 검증**
- [기사 목록 불러오기] outlined button + [전체 검증] blue button
- Linear progress bar: "72% 완료 (18/25)" with blue fill
- Data table: #, 이름, 전화번호, 면허번호, 검증결과, 액션
- Results color-coded: VALID=green badge, INVALID=red badge, UNKNOWN=amber badge, 미검증=gray badge
- 액션 column: [개별 검증] small button per row

**Style:** Tabs with underline. Result cards have left border accent color. Progress bar is prominent. Table is compact.

---

## 프롬프트 10: 어드민 — 정산 페이지

Design a settlement page with tabs for "SKEP" admin dashboard.

**Three tabs:** "목록" | "달력" | "차트"

**Top — 3 stat cards:**
- 총 거래액: 125,000,000원 (blue)
- 지급 완료: 98,000,000원 (green)
- 미지급: 27,000,000원 (red)

**Tab 1: 목록**
- Table: 공급사, BP사, 정산월, 금액, 상태, 액션
- Status: DRAFT=gray, SENT=blue, PAID=green
- 액션: [상세] [발송] [입금확인]

**Tab 2: 달력**
- Month navigation: "< 2026년 5월 >"
- Calendar grid: 7 columns (월~일), 5-6 rows
- Cells with settlement amounts have light blue (#EFF6FF) background
- Amount text in small font inside each cell

**Tab 3: 차트**
- Left: Vertical bar chart — monthly settlement amounts (6 months)
- Right: Donut/pie chart — status breakdown (DRAFT/SENT/PAID percentages)
- Charts use blue/green/gray color scheme

**Style:** Stats cards prominent at top. Calendar is clean with subtle cell borders. Charts use a professional color palette.

---

## 프롬프트 11: 어드민 — 서류 미리보기 페이지

Design a document preview page with split layout for "SKEP" admin dashboard.

**Two-panel layout (40% / 60% split):**

**Left panel — Document list:**
- Top: Owner type dropdown + Owner selector dropdown + [전체] button
- Document list items, each showing:
  - File type icon (image/pdf/document)
  - Document name
  - Status badge (활성/만료임박/만료)
  - Expiry D-day text
- Selected item has blue left border highlight

**Right panel — Preview area:**
- For images: Large preview with zoom controls (InteractiveViewer style, pinch/scroll zoom)
- For PDFs: Embedded PDF viewer (iframe)
- For other files: File icon + "미리보기를 지원하지 않는 파일 형식입니다" message

**Below preview — Metadata panel:**
- Info grid: 파일명, 파일크기, 업로드일, 서류유형, 상태(badge), 만료일, 소유자
- Action buttons: [download] icon button, [open_in_new] icon button

**When no document selected:**
- Center text: "좌측 목록에서 서류를 선택하세요"

**Style:** Split panel with subtle divider. Left panel has hover highlights. Preview area has subtle border. Clean metadata display.
