# Inspection Service

안전점검, 운전원 정비점검, GPS 위치 검증을 담당하는 마이크로서비스입니다.

## 기술 스택

- **Java**: 21 (Eclipse Temurin)
- **Spring Boot**: 3.2.3
- **Build**: Gradle
- **Database**: PostgreSQL 16
- **Migration**: Flyway
- **ORM**: Spring Data JPA
- **API**: Spring Web MVC
- **GIS**: JTS (Java Topology Suite)

## 주요 기능

### 안전점검 (Safety Inspections)
- 장비별 실시간 안전점검 (11개 항목 강제)
- GPS 위치 검증 (50m 이내만 가능)
- 항목 순서 강제 (타임스탬프 기반)
- 사진 첨부 지원
- 점검 상태 관리 (IN_PROGRESS, COMPLETED, FAILED)

### 운전원 정비점검표 (Maintenance Inspections)
- 일일 정비점검 기록
- 엔진오일, 유압유, 냉각수 상태 관리
- 연비, 연료량 기록

### 점검 항목 마스터 (Inspection Item Masters)
- 장비 유형별 점검 항목 관리
- 항목별 검사 방법 정의
- 사진 필수 여부 설정

## 프로젝트 구조

```
inspection-service/
├── build.gradle
├── settings.gradle
├── gradle.properties
├── Dockerfile
├── README.md
├── src/main/
│   ├── java/com/skep/inspection/
│   │   ├── InspectionServiceApplication.java
│   │   ├── controller/
│   │   │   ├── SafetyInspectionController.java
│   │   │   ├── MaintenanceInspectionController.java
│   │   │   └── InspectionItemController.java
│   │   ├── domain/
│   │   │   ├── SafetyInspection.java
│   │   │   ├── InspectionItemMaster.java
│   │   │   ├── InspectionItemResult.java
│   │   │   └── MaintenanceInspection.java
│   │   ├── repository/
│   │   │   ├── SafetyInspectionRepository.java
│   │   │   ├── InspectionItemMasterRepository.java
│   │   │   ├── InspectionItemResultRepository.java
│   │   │   └── MaintenanceInspectionRepository.java
│   │   ├── service/
│   │   │   ├── SafetyInspectionService.java
│   │   │   ├── MaintenanceInspectionService.java
│   │   │   └── InspectionItemMasterService.java
│   │   ├── util/
│   │   │   └── GpsUtil.java
│   │   └── dto/
│   │       ├── StartSafetyInspectionRequest.java
│   │       ├── RecordItemRequest.java
│   │       └── ...
│   └── resources/
│       ├── application.yml
│       └── db/migration/
│           └── V1__create_inspection_tables.sql
```

## 빌드 및 실행

### 로컬 개발 환경

```bash
# 저장소 클론
cd inspection-service

# Gradle 빌드
./gradlew clean build

# Spring Boot 실행
./gradlew bootRun
```

### Docker 빌드

```bash
# 이미지 빌드
docker build -t skep/inspection-service:1.0.0 .

# 컨테이너 실행
docker run -d \
  --name inspection-service \
  -p 8085:8085 \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/inspection_db \
  -e SPRING_DATASOURCE_USERNAME=postgres \
  -e SPRING_DATASOURCE_PASSWORD=postgres \
  skep/inspection-service:1.0.0
```

### Docker Compose로 전체 스택 실행

```bash
cd /sessions/charming-sharp-hawking/mnt/skep/services
docker-compose up -d
```

## 데이터베이스 마이그레이션

Flyway를 사용하여 자동으로 마이그레이션됩니다:
- `V1__create_inspection_tables.sql`: 초기 테이블 생성

## GPS 검증

### Haversine Formula
- 지구 반경: 6,371 km
- 허용 범위: 50 미터 이내
- 실시간 거리 계산으로 부정행위 방지

### 사용 예시
```java
GpsUtil.isWithinInspectionRange(
    inspectorLat, inspectorLng,
    equipmentLat, equipmentLng
);
```

## API 엔드포인트

### 안전점검
- `POST /api/inspection/safety/start` - 점검 시작 (GPS 검증)
- `POST /api/inspection/safety/{id}/record-item` - 항목 기록 (순서 검증)
- `POST /api/inspection/safety/{id}/complete` - 점검 완료
- `POST /api/inspection/safety/{id}/fail` - 점검 실패
- `GET /api/inspection/safety/{id}` - 상세 조회
- `GET /api/inspection/safety/{id}/items` - 점검 항목 조회
- `GET /api/inspection/safety/equipment/{equipmentId}` - 장비별 이력

### 운전원 정비점검
- `POST /api/inspection/maintenance` - 기록 생성
- `GET /api/inspection/maintenance/{id}` - 상세 조회
- `GET /api/inspection/maintenance/equipment/{equipmentId}` - 장비별 이력
- `GET /api/inspection/maintenance/driver/{driverId}` - 운전원별 이력
- `PUT /api/inspection/maintenance/{id}` - 수정

### 점검 항목 관리
- `GET /api/inspection/items/equipment-type/{equipmentTypeId}` - 활성 항목 조회
- `POST /api/inspection/items/equipment-type/{equipmentTypeId}` - 항목 추가 (관리자)
- `PUT /api/inspection/items/{id}` - 항목 수정
- `DELETE /api/inspection/items/{id}` - 항목 비활성화
- `POST /api/inspection/items/{id}/activate` - 항목 활성화

## 설정

### application.yml
- `spring.datasource.url`: PostgreSQL 연결 URL
- `spring.datasource.username`: DB 사용자명
- `spring.datasource.password`: DB 패스워드
- `server.port`: 서비스 포트 (기본값: 8085)

## 포트

- **Service Port**: 8085
- **Database Port**: 5432 (PostgreSQL)

## 헬스 체크

```bash
curl http://localhost:8085/api/inspection/items
```

## 개발 가이드

### 안전점검 플로우
1. `POST /api/inspection/safety/start` - 점검 세션 시작
2. `POST /api/inspection/safety/{id}/record-item` - 각 항목 기록 (1~11번 순서)
3. `POST /api/inspection/safety/{id}/complete` - 모든 항목 완료 후 종료

### 순서 검증
- 각 항목은 `sequence_number`로 순서 강제
- 이전 항목이 완료되지 않으면 다음 항목 기록 불가

### GPS 검증
- 점검 시작 시 GPS 좌표 검증
- 50m 이상 떨어져 있으면 점검 시작 불가

## 라이선스

SKEP Platform
