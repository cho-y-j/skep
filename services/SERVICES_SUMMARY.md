# SKEP Services Architecture Summary

## Generated Services

Two fully functional Spring Boot 3.2 microservices have been created with complete implementations.

## 1. Dispatch Service (Port 8084)

### Location
`/sessions/charming-sharp-hawking/mnt/skep/services/dispatch-service/`

### Core Components

#### Entities (JPA Domain Models)
- `DeploymentPlan` - 투입 계획 (장기 계약 단위)
- `DailyRoster` - 일일 작업자 명단
- `WorkRecord` - 작업 기록 (출근/시작/종료)
- `MonthlyWorkConfirmation` - 월간 작업확인서
- `DailyWorkConfirmation` - 일일 작업확인서

#### Services (Business Logic)
- `DeploymentPlanService` - 투입 계획 관리
- `DailyRosterService` - 일일 명단 제출/승인
- `WorkRecordService` - 작업 기록 (GPS 기반 출근)
- `ConfirmationService` - 작업확인서 생성/서명

#### Controllers (REST API)
- `DispatchController` - 투입, 명단, 작업 기록 엔드포인트
- `ConfirmationController` - 작업확인서 엔드포인트

#### Repositories
- 5개의 JPA Repository (Spring Data)
- 다양한 쿼리 메서드 (@Query)

#### DTOs
- 요청/응답 객체 7개
- Lombok을 이용한 간결한 코드

#### Database
- SQL: `V1__create_dispatch_tables.sql` (Flyway 마이그레이션)
- 5개 테이블 + 인덱스 생성
- PostgreSQL 16 호환

### API Endpoints (총 14개)

| Method | Endpoint | 기능 |
|--------|----------|------|
| POST | /api/dispatch/plans | 투입 계획 생성 |
| GET | /api/dispatch/plans | 투입 계획 목록 |
| GET | /api/dispatch/plans/{id} | 투입 계획 상세 |
| PUT | /api/dispatch/plans/{id} | 투입 계획 수정 |
| POST | /api/dispatch/rosters | 일일 명단 제출 |
| GET | /api/dispatch/rosters | 일일 명단 조회 |
| PUT | /api/dispatch/rosters/{id}/approve | 일일 명단 승인 |
| PUT | /api/dispatch/rosters/{id}/reject | 일일 명단 반려 |
| POST | /api/dispatch/work-records/clock-in | GPS 출근 |
| POST | /api/dispatch/work-records/{id}/start | 작업 시작 |
| POST | /api/dispatch/work-records/{id}/end | 작업 종료 |
| GET | /api/dispatch/work-records/{workerId}/today | 오늘 작업 기록 |
| POST | /api/dispatch/confirmations/daily/generate/{id} | 일일 확인서 생성 |
| POST | /api/dispatch/confirmations/daily/{id}/sign | 확인서 서명 |
| GET | /api/dispatch/confirmations/monthly/{planId}/{yearMonth} | 월간 확인서 조회 |
| POST | /api/dispatch/confirmations/monthly/{planId}/{yearMonth}/generate | 월간 확인서 생성 |

### Key Features
- GPS 기반 출근 인증
- 다양한 요금 체계 (일급, 야간, 야근, 조출, 월급)
- 작업확인서 자동 생성 및 전자서명
- 상태 관리 (ACTIVE, EXTENDED, REDUCED, COMPLETED)
- JSONB 지원 (가이드 리스트)

---

## 2. Inspection Service (Port 8085)

### Location
`/sessions/charming-sharp-hawking/mnt/skep/services/inspection-service/`

### Core Components

#### Entities (JPA Domain Models)
- `SafetyInspection` - 안전점검 세션
- `InspectionItemMaster` - 점검 항목 마스터
- `InspectionItemResult` - 점검 항목 결과
- `MaintenanceInspection` - 운전원 정비점검

#### Services (Business Logic)
- `SafetyInspectionService` - 안전점검 관리 (GPS 검증, 순서 강제)
- `MaintenanceInspectionService` - 정비점검 관리
- `InspectionItemMasterService` - 점검 항목 관리

#### Controllers (REST API)
- `SafetyInspectionController` - 안전점검 엔드포인트
- `MaintenanceInspectionController` - 정비점검 엔드포인트
- `InspectionItemController` - 점검 항목 관리 엔드포인트

#### Repositories
- 4개의 JPA Repository (Spring Data)
- 복잡한 쿼리 지원 (@Query)

#### DTOs
- 요청/응답 객체 4개

#### Utilities
- `GpsUtil` - Haversine 공식 (GPS 거리 계산)
  - 50m 이내만 점검 가능
  - 실시간 거리 검증

#### Database
- SQL: `V1__create_inspection_tables.sql` (Flyway 마이그레이션)
- 4개 테이블 + 인덱스 생성
- PostgreSQL 16 호환

### API Endpoints (총 13개)

| Method | Endpoint | 기능 |
|--------|----------|------|
| POST | /api/inspection/safety/start | 안전점검 시작 (GPS 검증) |
| POST | /api/inspection/safety/{id}/record-item | 항목 기록 (순서 검증) |
| POST | /api/inspection/safety/{id}/complete | 점검 완료 |
| POST | /api/inspection/safety/{id}/fail | 점검 실패 |
| GET | /api/inspection/safety/{id} | 상세 조회 |
| GET | /api/inspection/safety/{id}/items | 점검 항목 조회 |
| GET | /api/inspection/safety/equipment/{equipmentId} | 장비별 이력 |
| POST | /api/inspection/maintenance | 정비점검 기록 |
| GET | /api/inspection/maintenance/{id} | 정비점검 상세 |
| GET | /api/inspection/maintenance/equipment/{equipmentId} | 장비별 이력 |
| GET | /api/inspection/maintenance/driver/{driverId} | 운전원별 이력 |
| POST | /api/inspection/items/equipment-type/{equipmentTypeId} | 항목 추가 |
| GET | /api/inspection/items/equipment-type/{equipmentTypeId} | 항목 조회 |

### Key Features
- GPS 거리 검증 (50m 이내)
- 항목 순서 강제화 (sequence_number)
- 타임스탬프 기반 실시간 기록
- 장비 유형별 점검 항목 관리
- 활성/비활성 항목 관리
- Haversine 공식을 이용한 정확한 거리 계산

---

## 공통 기술 스택

```
Language:          Java 21 (LTS)
Framework:         Spring Boot 3.2.3
Build Tool:        Gradle 8.x
Database:          PostgreSQL 16
Migration:         Flyway 9.22.3
ORM:              Spring Data JPA + Hibernate
Web:              Spring Web MVC
JSON:             Jackson (with Java Time support)
Utility:          Lombok 1.18.30
GIS (Inspection): JTS (Java Topology Suite) 1.19.0
Container:        Docker + Docker Compose
Java Source:      UTF-8, Java 21 syntax
```

---

## 파일 구조

```
dispatch-service/
├── build.gradle                    # Gradle 빌드 설정
├── settings.gradle                 # 프로젝트 설정
├── gradle.properties               # Gradle 프로퍼티
├── Dockerfile                      # Docker 이미지
├── README.md                       # 서비스 문서
└── src/main/
    ├── java/com/skep/dispatch/
    │   ├── DispatchServiceApplication.java
    │   ├── controller/             # 2개 컨트롤러
    │   ├── domain/                 # 5개 엔티티
    │   ├── service/                # 4개 서비스
    │   ├── repository/             # 5개 레포지토리
    │   └── dto/                    # 7개 DTO
    └── resources/
        ├── application.yml         # 설정 파일
        └── db/migration/
            └── V1__create_dispatch_tables.sql

inspection-service/
├── build.gradle                    # Gradle 빌드 설정
├── settings.gradle                 # 프로젝트 설정
├── gradle.properties               # Gradle 프로퍼티
├── Dockerfile                      # Docker 이미지
├── README.md                       # 서비스 문서
└── src/main/
    ├── java/com/skep/inspection/
    │   ├── InspectionServiceApplication.java
    │   ├── controller/             # 3개 컨트롤러
    │   ├── domain/                 # 4개 엔티티
    │   ├── service/                # 3개 서비스
    │   ├── repository/             # 4개 레포지토리
    │   ├── util/                   # GPS 유틸리티
    │   └── dto/                    # 4개 DTO
    └── resources/
        ├── application.yml         # 설정 파일
        └── db/migration/
            └── V1__create_inspection_tables.sql

루트 디렉토리/
├── docker-compose.yml              # 전체 스택 구성
├── init-db.sql                     # DB 초기화 스크립트
├── .env.example                    # 환경 변수 샘플
├── README.md                       # 메인 문서
├── DEPLOYMENT_GUIDE.md             # 배포 가이드
└── SERVICES_SUMMARY.md             # 이 파일
```

---

## 빌드 커맨드

### Docker Compose (권장)

```bash
cd /sessions/charming-sharp-hawking/mnt/skep/services

# 빌드 및 실행
docker-compose up -d

# 로그 확인
docker-compose logs -f

# 종료
docker-compose down
```

### 로컬 개발

```bash
# Dispatch Service
cd dispatch-service
./gradlew clean build
./gradlew bootRun

# Inspection Service (다른 터미널)
cd inspection-service
./gradlew clean build
./gradlew bootRun
```

---

## 포트 정보

| 서비스 | 포트 | URL |
|--------|------|-----|
| Dispatch Service | 8084 | http://localhost:8084 |
| Inspection Service | 8085 | http://localhost:8085 |
| PostgreSQL | 5432 | localhost:5432 |

---

## 데이터베이스

### 자동 마이그레이션
- Flyway가 서비스 시작 시 자동으로 마이그레이션 실행
- `V1__create_dispatch_tables.sql` - Dispatch DB
- `V1__create_inspection_tables.sql` - Inspection DB

### 테이블 통계

| 서비스 | 테이블 수 | 인덱스 | 특이사항 |
|--------|---------|--------|---------|
| Dispatch | 5개 | 12개 | JSONB, POINT 지원 |
| Inspection | 4개 | 9개 | UUID PK, 복합 인덱스 |

---

## 구현 완료 항목

### Dispatch Service
- [x] 모든 엔티티 (5개)
- [x] 모든 서비스 (4개)
- [x] 모든 리포지토리 (5개)
- [x] 모든 컨트롤러 (2개)
- [x] 모든 DTO (7개)
- [x] Flyway 마이그레이션
- [x] application.yml 설정
- [x] Dockerfile
- [x] build.gradle
- [x] README.md

### Inspection Service
- [x] 모든 엔티티 (4개)
- [x] 모든 서비스 (3개)
- [x] 모든 리포지토리 (4개)
- [x] 모든 컨트롤러 (3개)
- [x] 모든 DTO (4개)
- [x] GPS 유틸리티 (Haversine)
- [x] Flyway 마이그레이션
- [x] application.yml 설정
- [x] Dockerfile
- [x] build.gradle
- [x] README.md

### Infrastructure
- [x] docker-compose.yml
- [x] init-db.sql
- [x] .env.example
- [x] 메인 README.md
- [x] DEPLOYMENT_GUIDE.md
- [x] SERVICES_SUMMARY.md (이 파일)

---

## 다음 단계

1. **개발 시작**
   ```bash
   docker-compose up -d
   ```

2. **API 테스트**
   - Postman, curl, 또는 IDE의 HTTP 클라이언트 사용
   - 각 서비스의 README.md에서 샘플 요청 참고

3. **기능 확장**
   - 새로운 엔티티 추가
   - 비즈니스 로직 구현
   - 마이그레이션 파일 추가

4. **배포**
   - DEPLOYMENT_GUIDE.md 참고
   - Docker 이미지 빌드
   - Kubernetes 또는 다른 오케스트레이션 플랫폼으로 배포

---

## 문서 위치

| 문서 | 위치 |
|------|------|
| 메인 README | `/services/README.md` |
| Dispatch 문서 | `/dispatch-service/README.md` |
| Inspection 문서 | `/inspection-service/README.md` |
| 배포 가이드 | `/services/DEPLOYMENT_GUIDE.md` |
| 서비스 요약 | `/services/SERVICES_SUMMARY.md` (이 파일) |

---

**작성일:** 2026-03-19
**상태:** 완성
**버전:** 1.0.0
