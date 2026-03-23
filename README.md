# SKEP - 산업현장 장비 투입 관리 플랫폼

> 산업현장에 장비와 인력을 공급하는 장비공급사, 장비를 발주·관리하는 BP사, 현장 안전을 점검하는 안전점검원, 실제 작업을 수행하는 운전원/유도원, 그리고 최종 시행사 간의 서류 흐름과 투입 프로세스를 디지털로 통합 관리하는 시스템

## 프로젝트 현황

| 항목 | 수치 |
|------|------|
| 프론트엔드 (Flutter Web) | 76개 파일, 25,472줄 |
| 백엔드 (Spring Boot) | 164개 파일, 8,971줄 |
| 전체 구현 페이지 | 33개 (Placeholder 0개) |
| 백엔드 마이크로서비스 | 11개 |
| 검증 API | 4종 (국세청/경찰청/교통안전공단/안전보건공단) |
| E2E 테스트 | 21/21 PASS |

## 기술 스택

- **프론트엔드**: Flutter Web (Dart) + BLoC + GoRouter
- **백엔드**: Java Spring Boot 3.2 x 8 마이크로서비스
- **API Gateway**: Spring Cloud Gateway
- **인증**: JWT (Access + Refresh Token)
- **DB**: PostgreSQL 16 + Redis 7
- **검증서버**: verify-server (Java) - OCR/진위확인
- **인프라**: Docker Compose + Nginx + Let's Encrypt SSL
- **서버**: AWS EC2 (skep.on1.kr)

## 프로젝트 구조

```
skep/
├── frontend/skep_app/lib/         # Flutter 앱 (76개 파일)
│   ├── core/                      # 공통 (네트워크/스토리지/위젯)
│   ├── features/auth/             # 인증 (로그인/회원가입)
│   ├── features/dashboard/view/   # 대시보드 페이지 33개
│   ├── features/dispatch/         # 투입 관리 BLoC
│   ├── features/inspection/       # 안전점검 BLoC
│   ├── features/location/         # 위치 추적 BLoC
│   └── router/                    # GoRouter
├── services/                      # Spring Boot 마이크로서비스 11개
│   ├── api-gateway/               # API Gateway (9080)
│   ├── auth-service/              # 인증/사용자 (9081)
│   ├── document-service/          # 서류 관리 (9082)
│   ├── equipment-service/         # 장비/인력 (9083)
│   ├── dispatch-service/          # 투입/명단 (9084)
│   ├── inspection-service/        # 안전점검 (9085)
│   ├── settlement-service/        # 정산 (9086)
│   ├── notification-service/      # 알림 (9087)
│   ├── location-service/          # 위치 (9088)
│   ├── ocr-service/               # OCR (9089)
│   └── govapi-service/            # 정부API (9090)
├── test/                          # 테스트 파일 (사업자/면허증 등)
├── docker-compose.yml             # 로컬 개발
├── docker-compose.server.yml      # 서버 배포
└── .env                           # 환경변수
```

## 역할별 기능 (33개 페이지)

### 관리자 (14개)
대시보드홈, 회원관리(사용자/회사), 서류유형관리, 장비유형설정, 인력유형설정, BP사관리, 장비현황, 투입관리, 서류관리, 안전점검, 정산, 통계, 알림/메시지, 실시간위치

### 공급사 (11개)
대시보드홈, 장비관리, 장비등록, 인력관리, 인력등록, 서류관리, 투입현황, 매칭요청, 출근관리, 정비점검, 정산/거래명세서

### BP사 (8개)
대시보드홈, 투입계획, 장비매칭, 일일명단, 안전점검, 정산, 작업확인서, 실시간위치

## 검증 시스템

| 검증 | API | 외부 연동 |
|------|-----|---------|
| 사업자 진위확인 | POST /api/verify/biz | 국세청 NTS |
| 운전면허 검증 | POST /api/verify/rims/license | 경찰청 RIMS |
| 화물운송 자격 | POST /api/verify/cargo | 한국교통안전공단 |
| 안전교육 확인 | POST /api/verify/kosha | 안전보건공단 QR+OCR |
| OCR | Google Vision API | 사업자/면허/자격증 자동인식 |

## 로컬 실행

```bash
cp .env.example .env
docker compose up -d postgres redis
sleep 15
docker compose up -d auth-service equipment-service document-service dispatch-service inspection-service api-gateway
cd frontend/skep_app && flutter run -d chrome --web-port=8888
```

## E2E 테스트 결과 (21/21 PASS)

회원가입, 로그인, 장비등록(3대), 인력등록(2명), 서류업로드(4건), 투입계획, 명단생성, BP승인, 출근기록, 안전점검, 정비점검

## 테스트 계정

| 역할 | 이메일 | 비밀번호 |
|------|--------|----------|
| 관리자 | test@skep.kr | Test1234! |
| 공급사 | daesung@skep.kr | Test1234! |
| BP사 | hyundai@skep.kr | Test1234! |
| 운전원 | driver.kim@skep.kr | Test1234! |

## URL
- 운영: https://skep.on1.kr
- API: https://skep.on1.kr/api/
- 검증: https://skep.on1.kr/api/verify/
