# Dispatch Service

투입 계획, 일일 작업자 명단, 작업 기록, 작업확인서 관리를 담당하는 마이크로서비스입니다.

## 기술 스택

- **Java**: 21 (Eclipse Temurin)
- **Spring Boot**: 3.2.3
- **Build**: Gradle
- **Database**: PostgreSQL 16
- **Migration**: Flyway
- **ORM**: Spring Data JPA
- **API**: Spring Web MVC

## 주요 기능

### 투입 계획 (Deployment Plans)
- 장기 계약 단위의 투입 계획 생성/조회/수정
- 다양한 요금 체계 지원 (일급, 야간, 야근, 조출 등)
- 상태 관리 (ACTIVE, EXTENDED, REDUCED, COMPLETED)

### 일일 작업자 명단 (Daily Rosters)
- 매일 익일 작업자 명단 제출
- 운전원/보조원 관리
- 승인/반려 프로세스

### 작업 기록 (Work Records)
- GPS 기반 출근 인증
- 작업 시작/종료 기록
- 작업 유형별 기록

### 작업확인서 (Confirmations)
- 일일 확인서 (BP사 수령용)
- 월간 확인서 (공급사 수령용)
- 전자서명 지원

## 프로젝트 구조

```
dispatch-service/
├── build.gradle
├── settings.gradle
├── gradle.properties
├── Dockerfile
├── README.md
├── src/main/
│   ├── java/com/skep/dispatch/
│   │   ├── DispatchServiceApplication.java
│   │   ├── controller/
│   │   │   ├── DispatchController.java
│   │   │   └── ConfirmationController.java
│   │   ├── domain/
│   │   │   ├── DeploymentPlan.java
│   │   │   ├── DailyRoster.java
│   │   │   ├── WorkRecord.java
│   │   │   ├── MonthlyWorkConfirmation.java
│   │   │   └── DailyWorkConfirmation.java
│   │   ├── repository/
│   │   │   ├── DeploymentPlanRepository.java
│   │   │   ├── DailyRosterRepository.java
│   │   │   ├── WorkRecordRepository.java
│   │   │   ├── MonthlyWorkConfirmationRepository.java
│   │   │   └── DailyWorkConfirmationRepository.java
│   │   ├── service/
│   │   │   ├── DeploymentPlanService.java
│   │   │   ├── DailyRosterService.java
│   │   │   ├── WorkRecordService.java
│   │   │   └── ConfirmationService.java
│   │   └── dto/
│   │       ├── CreateDeploymentPlanRequest.java
│   │       ├── CreateDailyRosterRequest.java
│   │       ├── ClockInRequest.java
│   │       └── ...
│   └── resources/
│       ├── application.yml
│       └── db/migration/
│           └── V1__create_dispatch_tables.sql
```

## 빌드 및 실행

### 로컬 개발 환경

```bash
# 저장소 클론
cd dispatch-service

# Gradle 빌드
./gradlew clean build

# Spring Boot 실행
./gradlew bootRun
```

### Docker 빌드

```bash
# 이미지 빌드
docker build -t skep/dispatch-service:1.0.0 .

# 컨테이너 실행
docker run -d \
  --name dispatch-service \
  -p 8084:8084 \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/dispatch_db \
  -e SPRING_DATASOURCE_USERNAME=postgres \
  -e SPRING_DATASOURCE_PASSWORD=postgres \
  skep/dispatch-service:1.0.0
```

### Docker Compose로 전체 스택 실행

```bash
cd /sessions/charming-sharp-hawking/mnt/skep/services
docker-compose up -d
```

## 데이터베이스 마이그레이션

Flyway를 사용하여 자동으로 마이그레이션됩니다:
- `V1__create_dispatch_tables.sql`: 초기 테이블 생성

## API 엔드포인트

### 투입 계획
- `POST /api/dispatch/plans` - 생성
- `GET /api/dispatch/plans` - 목록
- `GET /api/dispatch/plans/{id}` - 상세
- `PUT /api/dispatch/plans/{id}` - 수정

### 일일 명단
- `POST /api/dispatch/rosters` - 제출
- `GET /api/dispatch/rosters` - 조회
- `PUT /api/dispatch/rosters/{id}/approve` - 승인
- `PUT /api/dispatch/rosters/{id}/reject` - 반려

### 작업 기록
- `POST /api/dispatch/work-records/clock-in` - 출근
- `POST /api/dispatch/work-records/{id}/start` - 시작
- `POST /api/dispatch/work-records/{id}/end` - 종료
- `GET /api/dispatch/work-records/{workerId}/today` - 오늘 기록

### 작업확인서
- `POST /api/dispatch/confirmations/daily/generate/{workRecordId}` - 일일 자동 생성
- `POST /api/dispatch/confirmations/daily/{id}/sign` - 전자서명
- `GET /api/dispatch/confirmations/monthly/{planId}/{yearMonth}` - 월간 조회
- `POST /api/dispatch/confirmations/monthly/{planId}/{yearMonth}/generate` - 월간 생성

## 설정

### application.yml
- `spring.datasource.url`: PostgreSQL 연결 URL
- `spring.datasource.username`: DB 사용자명
- `spring.datasource.password`: DB 패스워드
- `server.port`: 서비스 포트 (기본값: 8084)

## 포트

- **Service Port**: 8084
- **Database Port**: 5432 (PostgreSQL)

## 헬스 체크

```bash
curl http://localhost:8084/api/dispatch/plans
```

## 개발 가이드

### 새로운 엔티티 추가
1. `domain/` 패키지에 엔티티 클래스 생성
2. `repository/` 패키지에 Repository 인터페이스 생성
3. `service/` 패키지에 비즈니스 로직 구현
4. `controller/` 패키지에 API 엔드포인트 추가
5. Flyway 마이그레이션 파일 추가

### 마이그레이션 추가
`src/main/resources/db/migration/` 디렉토리에 새로운 SQL 파일 추가:
```
V2__add_column_to_deployment_plans.sql
```

## 라이선스

SKEP Platform
