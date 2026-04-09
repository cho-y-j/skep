# SKEP API 명세서

> 총 125개 엔드포인트 | 기존 104개 + 신규 21개 | 프론트 연동 25개 + 미연동 100개

---

## 범례
- **[기존]** 원래 있던 API
- **[신규]** 이번에 새로 만든 API
- **[프론트 연동]** 프론트에서 실제 호출
- **[프론트 미연동]** 백엔드만 있고 프론트 미연결

---

## 1. AUTH SERVICE

### 인증 (`/api/auth`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 1 | POST | `/api/auth/register` | 회원가입 | [기존] [프론트 연동] |
| 2 | POST | `/api/auth/login` | 로그인 | [기존] [프론트 연동] |
| 3 | POST | `/api/auth/refresh` | 토큰 갱신 | [기존] [프론트 연동] |
| 4 | POST | `/api/auth/logout` | 로그아웃 | [기존] [프론트 연동] |
| 5 | GET | `/api/auth/me` | 내 프로필 | [기존] [프론트 연동] |
| 6 | GET | `/api/auth/users` | 전체 사용자 목록 | [기존] [프론트 연동] |
| 7 | POST | `/api/auth/fingerprint/register` | 지문 등록 | [기존] [프론트 미연동] |
| 8 | GET | `/api/auth/validate?token=` | 토큰 검증 | [기존] [프론트 미연동] |

**로그인 요청:**
```json
POST /api/auth/login
{ "email": "admin@skep.com", "password": "Admin1234@@" }
```
**응답:**
```json
{
  "user_id": "UUID",
  "email": "admin@skep.com",
  "name": "플랫폼 관리자",
  "role": "PLATFORM_ADMIN",
  "access_token": "JWT...",
  "refresh_token": "JWT...",
  "expires_in": 24,
  "token_type": "Bearer"
}
```

### 회사 관리 (`/api/auth/companies`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 9 | GET | `/api/auth/companies` | 전체 회사 목록 | [신규] [프론트 연동] |
| 10 | GET | `/api/auth/companies/{id}` | 회사 단건 조회 | [신규] [프론트 연동] |
| 11 | GET | `/api/auth/companies/type/{type}` | 타입별 조회 (BP_COMPANY, EQUIPMENT_SUPPLIER) | [신규] [프론트 연동] |
| 12 | GET | `/api/auth/companies/active` | 활성 회사만 | [신규] [프론트 연동] |
| 13 | POST | `/api/auth/companies` | 회사 생성 | [신규] [프론트 연동] |
| 14 | PUT | `/api/auth/companies/{id}` | 회사 수정 | [신규] [프론트 미연동] |
| 15 | PUT | `/api/auth/companies/{id}/status` | 상태 변경 (ACTIVE/SUSPENDED) | [신규] [프론트 연동] |
| 16 | DELETE | `/api/auth/companies/{id}` | 회사 삭제 (소프트) | [신규] [프론트 미연동] |

**회사 생성:**
```json
POST /api/auth/companies
{
  "name": "현대건설",
  "businessNumber": "123-45-67890",
  "representative": "홍길동",
  "companyType": "BP_COMPANY",
  "address": "서울시 강남구",
  "email": "info@hyundai.com",
  "phone": "02-1234-5678"
}
```

---

## 2. EQUIPMENT SERVICE

### 장비 (`/api/equipment`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 17 | POST | `/api/equipment` | 장비 등록 | [기존] [프론트 연동] |
| 18 | GET | `/api/equipment` | 장비 목록 (?supplier_id= 필터) | [기존] [프론트 연동] |
| 19 | GET | `/api/equipment/{id}` | 장비 단건 | [기존] [프론트 연동] |
| 20 | PUT | `/api/equipment/{id}` | 장비 수정 | [기존] [프론트 미연동] |
| 21 | POST | `/api/equipment/{id}/nfc` | NFC 태그 등록 | [기존] [프론트 미연동] |
| 22 | GET | `/api/equipment/nfc/{tagId}` | NFC로 장비 조회 | [기존] [프론트 미연동] |
| 23 | GET | `/api/equipment/{id}/status` | 장비 상태 확인 | [기존] [프론트 미연동] |

**장비 등록:**
```json
POST /api/equipment
{
  "supplier_id": "UUID",
  "equipment_type_name": "대형 크레인",
  "vehicle_number": "서울12가3456",
  "model_name": "LIEBHERR LTM 1300",
  "manufacture_year": 2022
}
```

### 인원 (`/api/equipment/persons`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 24 | POST | `/api/equipment/persons` | 인원 등록 (DRIVER/GUIDE) | [기존] [프론트 연동] |
| 25 | GET | `/api/equipment/persons` | 인원 목록 | [기존] [프론트 연동] |
| 26 | GET | `/api/equipment/persons/{id}` | 인원 단건 | [기존] [프론트 연동] |
| 27 | PUT | `/api/equipment/persons/{id}` | 인원 수정 | [기존] [프론트 미연동] |
| 28 | POST | `/api/equipment/persons/{id}/health-check` | 건강검진 기록 | [기존] [프론트 미연동] |
| 29 | POST | `/api/equipment/persons/{id}/safety-training` | 안전교육 기록 | [기존] [프론트 미연동] |

### 장비 배정 (`/api/equipment/{id}/assign`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 30 | POST | `/api/equipment/{id}/assign` | 장비-기사 배정 | [기존] [프론트 미연동] |
| 31 | GET | `/api/equipment/{id}/current-assignment` | 현재 배정 조회 | [기존] [프론트 미연동] |

---

## 3. DOCUMENT SERVICE

### 서류 (`/api/documents`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 32 | POST | `/api/documents/upload` | 서류 업로드 (multipart) | [기존] [프론트 연동] |
| 33 | GET | `/api/documents/types` | 서류 유형 목록 | [기존] [프론트 연동] |
| 34 | GET | `/api/documents/expiring?days=30` | 만료 임박 서류 | [기존] [프론트 연동] |
| 35 | GET | `/api/documents/{ownerId}/{ownerType}` | 소유자별 서류 | [기존] [프론트 연동] |
| 36 | GET | `/api/documents/{id}` | 서류 단건 | [기존] [프론트 연동] |
| 37 | POST | `/api/documents/{id}/verify` | 서류 검증 | [기존] [프론트 미연동] |
| 38 | GET | `/api/documents/{id}/file` | 서류 파일 미리보기/다운로드 | [신규] [프론트 미연동] |
| 39 | DELETE | `/api/documents/{id}` | 서류 삭제 | [기존] [프론트 미연동] |

### 검증 — lifton 연동 (`/api/documents/verify`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 40 | POST | `/api/documents/verify/driver-license` | 운전면허 검증 | [신규] [프론트 미연동] |
| 41 | POST | `/api/documents/verify/business-registration` | 사업자등록 검증 | [신규] [프론트 미연동] |
| 42 | POST | `/api/documents/verify/cargo` | 화물자격 검증 | [신규] [프론트 미연동] |

**면허 검증:**
```json
POST /api/documents/verify/driver-license
{ "licenseNumber": "11-22-333333-44", "name": "홍길동" }
```
**응답 (lifton 경유):**
```json
{
  "success": true,
  "data": { "result": "VALID", "message": "..." }
}
```

---

## 4. DISPATCH SERVICE

### 현장 (`/api/dispatch/sites`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 43 | GET | `/api/dispatch/sites` | 현장 목록 | [신규] [프론트 연동] |
| 44 | GET | `/api/dispatch/sites/{id}` | 현장 단건 | [신규] [프론트 연동] |
| 45 | GET | `/api/dispatch/sites/bp/{bpCompanyId}` | BP사별 현장 | [신규] [프론트 연동] |
| 46 | POST | `/api/dispatch/sites` | 현장 생성 (폴리곤/원형) | [신규] [프론트 연동] |
| 47 | PUT | `/api/dispatch/sites/{id}` | 현장 수정 | [신규] [프론트 미연동] |

**현장 생성 (원형):**
```json
POST /api/dispatch/sites
{
  "name": "강남역 현장",
  "address": "서울시 강남구",
  "bpCompanyId": "UUID",
  "boundaryType": "CIRCLE",
  "centerLat": 37.4979,
  "centerLng": 127.0276,
  "radiusMeters": 300
}
```
**현장 생성 (폴리곤):**
```json
{
  "name": "판교 현장",
  "bpCompanyId": "UUID",
  "boundaryType": "POLYGON",
  "boundaryCoordinates": "[[37.39,127.10],[37.39,127.12],[37.40,127.12],[37.40,127.10]]"
}
```

### 견적 요청 (`/api/dispatch/quotations/requests`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 48 | POST | `/api/dispatch/quotations/requests` | 견적 요청 생성 (BP→어드민+공급사) | [신규] [프론트 연동] |
| 49 | GET | `/api/dispatch/quotations/requests` | 견적 요청 목록 | [신규] [프론트 연동] |
| 50 | GET | `/api/dispatch/quotations/requests/{id}` | 견적 요청 단건 | [신규] [프론트 연동] |
| 51 | GET | `/api/dispatch/quotations/requests/bp/{bpCompanyId}` | BP사별 요청 | [신규] [프론트 미연동] |

**견적 요청:**
```json
POST /api/dispatch/quotations/requests
{
  "siteId": "UUID",
  "bpCompanyId": "UUID",
  "title": "크레인 2대 요청",
  "description": "5월 한 달간",
  "desiredStartDate": "2026-05-01",
  "desiredEndDate": "2026-05-31"
}
```

### 견적서 (`/api/dispatch/quotations`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 52 | POST | `/api/dispatch/quotations` | 견적서 작성 (장비공급사/어드민) | [신규] [프론트 연동] |
| 53 | GET | `/api/dispatch/quotations/request/{requestId}` | 요청별 견적서 목록 | [신규] [프론트 연동] |
| 54 | PUT | `/api/dispatch/quotations/{id}/submit` | 견적서 제출 (DRAFT→SUBMITTED) | [신규] [프론트 연동] |
| 55 | PUT | `/api/dispatch/quotations/{id}/accept` | 견적서 승인 (→ACCEPTED) | [신규] [프론트 연동] |
| 56 | PUT | `/api/dispatch/quotations/{id}/reject` | 견적서 거절 (→REJECTED) | [신규] [프론트 연동] |

**견적서 작성:**
```json
POST /api/dispatch/quotations
{
  "requestId": "UUID",
  "supplierId": "UUID",
  "totalAmount": 30000000,
  "notes": "크레인 2대 월 임대",
  "items": [
    {
      "equipmentTypeName": "대형 크레인",
      "quantity": 2,
      "rateDaily": 1500000,
      "rateOvertime": 200000,
      "rateNight": 250000,
      "laborIncluded": true
    },
    {
      "equipmentTypeName": "굴삭기",
      "quantity": 1,
      "rateDaily": 800000,
      "laborIncluded": false,
      "laborCostDaily": 300000,
      "guideCostDaily": 200000
    }
  ]
}
```

### 배차 계획 (`/api/dispatch/plans`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 57 | POST | `/api/dispatch/plans` | 배차 계획 생성 | [기존] [프론트 연동] |
| 58 | GET | `/api/dispatch/plans` | 배차 목록 | [기존] [프론트 연동] |
| 59 | GET | `/api/dispatch/plans/{id}` | 배차 단건 | [기존] [프론트 연동] |
| 60 | PUT | `/api/dispatch/plans/{id}` | 배차 수정 | [기존] [프론트 미연동] |
| 61 | GET | `/api/dispatch/plans/supplier/{supplierId}` | 공급사별 배차 | [기존] [프론트 미연동] |

### 투입 체크리스트 (`/api/dispatch/checklists`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 62 | GET | `/api/dispatch/checklists/plan/{planId}` | 체크리스트 조회 | [신규] [프론트 미연동] |
| 63 | PUT | `/api/dispatch/checklists/{id}/update` | 체크 항목 업데이트 | [신규] [프론트 미연동] |
| 64 | PUT | `/api/dispatch/checklists/{id}/override` | 강제 통과 (어드민/BP) | [신규] [프론트 미연동] |

**체크리스트 항목:**
```json
{
  "quotationConfirmed": true,
  "documentsVerified": true,
  "licenseVerified": true,
  "safetyInspectionPassed": true,
  "healthCheckCompleted": true,
  "personnelAssigned": true,
  "equipmentAssigned": true,
  "overallStatus": "PASSED"
}
```

### 일일 명부 (`/api/dispatch/rosters`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 65 | POST | `/api/dispatch/rosters` | 명부 생성 | [기존] [프론트 연동] |
| 66 | GET | `/api/dispatch/rosters` | 명부 목록 (?date=&planId=) | [기존] [프론트 연동] |
| 67 | GET | `/api/dispatch/rosters/{id}` | 명부 단건 | [기존] [프론트 연동] |
| 68 | PUT | `/api/dispatch/rosters/{id}/approve` | 명부 승인 | [기존] [프론트 연동] |
| 69 | PUT | `/api/dispatch/rosters/{id}/reject` | 명부 반려 | [기존] [프론트 미연동] |

### 작업 기록 (`/api/dispatch/work-records`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 70 | POST | `/api/dispatch/work-records/clock-in` | 출근 (GPS+지문) | [기존] [프론트 연동] |
| 71 | POST | `/api/dispatch/work-records/{id}/start` | 작업 시작 | [기존] [프론트 연동] |
| 72 | POST | `/api/dispatch/work-records/{id}/end` | 작업 종료 | [기존] [프론트 연동] |
| 73 | GET | `/api/dispatch/work-records/{id}` | 작업 기록 단건 | [기존] [프론트 미연동] |
| 74 | GET | `/api/dispatch/work-records/worker/{workerId}/today` | 오늘 작업 | [기존] [프론트 미연동] |
| 75 | GET | `/api/dispatch/work-records/roster/{rosterId}` | 명부별 작업 | [기존] [프론트 미연동] |

### 작업확인서 — 일일 (`/api/dispatch/confirmations/daily`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 76 | POST | `/api/dispatch/confirmations/daily/generate/{workRecordId}` | 일일 확인서 생성 | [기존] [프론트 연동] |
| 77 | POST | `/api/dispatch/confirmations/daily/{id}/sign` | 서명 (BP/어드민) | [기존] [프론트 연동] |
| 78 | GET | `/api/dispatch/confirmations/daily` | 확인서 목록 (?status=) | [기존] [프론트 연동] |
| 79 | GET | `/api/dispatch/confirmations/daily/{id}` | 확인서 단건 | [기존] [프론트 미연동] |

### 작업확인서 — 월간 (`/api/dispatch/confirmations/monthly`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 80 | POST | `/api/dispatch/confirmations/monthly/{planId}/{yearMonth}/generate` | 월간 확인서 생성 | [기존] [프론트 미연동] |
| 81 | GET | `/api/dispatch/confirmations/monthly/{planId}/{yearMonth}` | 월간 확인서 조회 | [기존] [프론트 미연동] |
| 82 | POST | `/api/dispatch/confirmations/monthly/{id}/sign` | 서명 | [기존] [프론트 미연동] |
| 83 | POST | `/api/dispatch/confirmations/monthly/{id}/send` | 발송 | [기존] [프론트 미연동] |
| 84 | GET | `/api/dispatch/confirmations/monthly/plan/{planId}` | 계획별 목록 | [기존] [프론트 미연동] |

---

## 5. INSPECTION SERVICE

### 점검 항목 (`/api/inspection/items`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 85 | GET | `/api/inspection/items/equipment-type/{typeId}` | 장비타입별 점검항목 | [기존] [프론트 미연동] |
| 86 | GET | `/api/inspection/items/{id}` | 점검항목 단건 | [기존] [프론트 미연동] |
| 87 | POST | `/api/inspection/items/equipment-type/{typeId}` | 점검항목 생성 | [기존] [프론트 미연동] |
| 88 | PUT | `/api/inspection/items/{id}` | 점검항목 수정 | [기존] [프론트 미연동] |
| 89 | DELETE | `/api/inspection/items/{id}` | 점검항목 비활성화 | [기존] [프론트 미연동] |
| 90 | POST | `/api/inspection/items/{id}/activate` | 점검항목 활성화 | [기존] [프론트 미연동] |
| 91 | GET | `/api/inspection/items/all/equipment-type/{typeId}` | 전체 (비활성 포함) | [기존] [프론트 미연동] |

### 안전점검 (`/api/inspection/safety`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 92 | POST | `/api/inspection/safety/start` | 안전점검 시작 | [기존] [프론트 미연동] |
| 93 | POST | `/api/inspection/safety/{id}/record-item` | 점검항목 기록 (OK/NG/NA) | [기존] [프론트 미연동] |
| 94 | POST | `/api/inspection/safety/{id}/complete` | 점검 완료 | [기존] [프론트 미연동] |
| 95 | POST | `/api/inspection/safety/{id}/fail` | 점검 실패 | [기존] [프론트 미연동] |
| 96 | GET | `/api/inspection/safety/{id}` | 점검 단건 | [기존] [프론트 미연동] |
| 97 | GET | `/api/inspection/safety/{id}/items` | 점검 결과 목록 | [기존] [프론트 미연동] |
| 98 | GET | `/api/inspection/safety/equipment/{equipmentId}` | 장비별 점검 이력 | [기존] [프론트 미연동] |

### 정비점검 (`/api/inspection/maintenance`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 99 | POST | `/api/inspection/maintenance` | 정비점검 생성 | [기존] [프론트 미연동] |
| 100 | GET | `/api/inspection/maintenance/{id}` | 정비 단건 | [기존] [프론트 미연동] |
| 101 | GET | `/api/inspection/maintenance/equipment/{equipmentId}` | 장비별 정비 이력 | [기존] [프론트 미연동] |
| 102 | GET | `/api/inspection/maintenance/driver/{driverId}` | 기사별 정비 이력 | [기존] [프론트 미연동] |
| 103 | PUT | `/api/inspection/maintenance/{id}` | 정비 수정 | [기존] [프론트 미연동] |

---

## 6. SETTLEMENT SERVICE

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 104 | POST | `/api/settlement/generate` | 정산 생성 | [기존] [프론트 미연동] |
| 105 | GET | `/api/settlement` | 정산 목록 (paginated, ?supplierId=&bpCompanyId=&yearMonth=) | [기존] [프론트 연동] |
| 106 | GET | `/api/settlement/{id}` | 정산 단건 | [기존] [프론트 연동] |
| 107 | POST | `/api/settlement/{id}/send?bpEmailAddress=` | 정산 발송 | [기존] [프론트 미연동] |
| 108 | PUT | `/api/settlement/{id}/mark-paid` | 입금 확인 | [기존] [프론트 미연동] |
| 109 | GET | `/api/settlement/statistics/supplier/{supplierId}` | 공급사 통계 | [기존] [프론트 미연동] |
| 110 | GET | `/api/settlement/statistics/bp/{bpId}` | BP사 통계 | [기존] [프론트 미연동] |

---

## 7. NOTIFICATION SERVICE

### 알림 (`/api/notifications`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 111 | POST | `/api/notifications/send` | 알림 발송 | [기존] [프론트 미연동] |
| 112 | GET | `/api/notifications/my?userId=` | 내 알림 목록 | [기존] [프론트 미연동] |
| 113 | PUT | `/api/notifications/{id}/read` | 읽음 처리 | [기존] [프론트 미연동] |
| 114 | GET | `/api/notifications/unread-count?userId=` | 안 읽은 수 | [기존] [프론트 미연동] |

### 메시지 (`/api/notifications/messages`)

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 115 | POST | `/api/notifications/messages` | 메시지 발송 | [기존] [프론트 미연동] |
| 116 | GET | `/api/notifications/messages/my?userId=` | 내 메시지 | [기존] [프론트 미연동] |
| 117 | PUT | `/api/notifications/messages/{id}/read?userId=` | 읽음 | [기존] [프론트 미연동] |
| 118 | PUT | `/api/notifications/messages/{id}/confirm?userId=` | 확인 | [기존] [프론트 미연동] |
| 119 | GET | `/api/notifications/messages/{id}/read-status` | 읽음 현황 | [기존] [프론트 미연동] |
| 120 | POST | `/api/notifications/messages/{id}/resend-unread` | 미읽은 사람 재발송 | [기존] [프론트 미연동] |

### FCM

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 121 | POST | `/api/notifications/fcm/register` | FCM 토큰 등록 | [기존] [프론트 미연동] |

---

## 8. LOCATION SERVICE

| # | Method | Endpoint | 설명 | 상태 |
|---|--------|----------|------|------|
| 122 | POST | `/api/location/update` | 위치 업데이트 | [기존] [프론트 미연동] |
| 123 | GET | `/api/location/current/{siteId}` | 현장별 현재 위치 | [기존] [프론트 미연동] |
| 124 | GET | `/api/location/worker/{workerId}` | 기사 위치 이력 | [기존] [프론트 미연동] |
| 125 | GET | `/api/location/worker/{workerId}/current` | 기사 현재 위치 | [기존] [프론트 미연동] |

---

## 통계 요약

| 구분 | 개수 |
|------|------|
| **전체 엔드포인트** | 125개 |
| 기존 API | 104개 |
| 신규 API (이번에 생성) | 21개 |
| **프론트 연동 완료** | **25개** |
| **프론트 미연동** | **100개** |

### 서비스별

| 서비스 | 엔드포인트 | 프론트 연동 |
|--------|-----------|-----------|
| Auth | 16개 | 11개 |
| Equipment | 15개 | 6개 |
| Document | 11개 | 5개 |
| Dispatch | 42개 | 18개 |
| Inspection | 19개 | 0개 |
| Settlement | 7개 | 2개 |
| Notification | 11개 | 0개 |
| Location | 4개 | 0개 |

### 프론트 연동 우선순위 (남은 100개 중)

**1순위 — 핵심 흐름:**
- 점검 서비스 전체 (19개) — 안전점검/정비 UI
- 체크리스트 (3개) — 투입 전 확인
- 월간 확인서 (5개) — 작업확인서 월간

**2순위 — 관리 기능:**
- 알림 (11개)
- 위치 (4개)
- 정산 통계 (5개)

**3순위 — 부가 기능:**
- NFC (2개)
- 지문 (1개)
- FCM (1개)
