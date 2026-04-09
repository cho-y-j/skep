# SKEP 마이크로서비스 빠른 시작 가이드

## 1. 최소 요구사항

- Java 21 JDK
- Docker & Docker Compose (권장)
- PostgreSQL 16 (또는 Docker)
- Git

## 2. 로컬 개발 환경 (Docker Compose 권장)

### 단계 1: 데이터베이스 및 서비스 시작

```bash
cd /sessions/charming-sharp-hawking/mnt/skep/services

# PostgreSQL 시작
docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgres:16

# 데이터베이스 생성
docker exec -it postgres psql -U postgres -c "CREATE DATABASE skep_document;"
docker exec -it postgres psql -U postgres -c "CREATE DATABASE skep_equipment;"

# MinIO (S3 호환) 시작 (선택사항)
docker run -d \
  --name minio \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  -p 9000:9000 \
  minio/minio server /data
```

### 단계 2: Document Service 빌드 및 실행

```bash
cd document-service

# 빌드
./gradlew clean build -x test

# 실행
./gradlew bootRun

# 또는 직접 JAR 실행
java -jar build/libs/document-service.jar
```

**접근 가능한 주소:** http://localhost:8082

### 단계 3: Equipment Service 빌드 및 실행 (새로운 터미널)

```bash
cd equipment-service

# 빌드
./gradlew clean build -x test

# 실행
./gradlew bootRun

# 또는 직접 JAR 실행
java -jar build/libs/equipment-service.jar
```

**접근 가능한 주소:** http://localhost:8083

---

## 3. API 테스트 예제

### Document Service

#### 서류 타입 조회
```bash
curl http://localhost:8082/api/documents/types | jq
```

#### 서류 업로드
```bash
# 먼저 document_type_id를 위의 조회로 얻은 후 사용

curl -X POST \
  -F "file=@your_file.pdf" \
  -F "owner_id=550e8400-e29b-41d4-a716-446655440000" \
  -F "owner_type=EQUIPMENT" \
  -F "document_type_id=<document-type-id>" \
  -F "uploaded_by=550e8400-e29b-41d4-a716-446655440001" \
  http://localhost:8082/api/documents/upload
```

#### 서류 조회
```bash
curl http://localhost:8082/api/documents/550e8400-e29b-41d4-a716-446655440000/EQUIPMENT | jq
```

#### 만료 임박 서류 조회 (30일)
```bash
curl http://localhost:8082/api/documents/expiring?days=30 | jq
```

---

### Equipment Service

#### 장비 타입 확인 (초기 설정된 데이터 조회)
```bash
curl http://localhost:8083/api/equipment | jq
```

#### 장비 등록
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "supplier_id": "550e8400-e29b-41d4-a716-446655440000",
    "equipment_type_id": "<equipment-type-id-from-initial-data>",
    "vehicle_number": "서울12가1234",
    "model_name": "크레인 모델 X",
    "manufacture_year": 2023
  }' \
  http://localhost:8083/api/equipment | jq
```

#### 장비 조회
```bash
curl http://localhost:8083/api/equipment | jq
```

#### 인력 등록 (운전원)
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "supplier_id": "550e8400-e29b-41d4-a716-446655440000",
    "person_type": "DRIVER",
    "user_id": "550e8400-e29b-41d4-a716-446655440002",
    "name": "김운전",
    "phone": "010-1234-5678",
    "birth_date": "1990-01-15"
  }' \
  http://localhost:8083/api/equipment/persons | jq
```

#### 건강검진 기록
```bash
curl -X POST \
  http://localhost:8083/api/equipment/persons/<person-id>/health-check | jq
```

#### 안전교육 기록
```bash
curl -X POST \
  http://localhost:8083/api/equipment/persons/<person-id>/safety-training | jq
```

#### 장비-운전원 배정
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "driver_id": "<person-id>",
    "guide_ids": [],
    "assigned_from": "2026-03-19",
    "assigned_until": "2026-12-31"
  }' \
  http://localhost:8083/api/equipment/<equipment-id>/assign | jq
```

#### 투입 가능 여부 확인
```bash
curl http://localhost:8083/api/equipment/<equipment-id>/status | jq
```

---

## 4. 초기 데이터 확인

### Document Service - 서류 타입 (자동 생성)

**장비 서류:**
1. 자동차등록원부
2. 자동차등록증
3. 사업자등록증
4. 자동차보험
5. 안전인증서
6. 장비제원표
7. 비파괴검사서

**인력 서류:**
8. 운전면허증
9. 기초안전보건교육이수증
10. 화물운송종사자격증
11. 조종자격수료증
12. 특수형태근로자교육실시확인서
13. 건강검진결과서

### Equipment Service - 장비 타입 (자동 생성)

1. 소형 크레인
2. 대형 크레인
3. 지게차
4. 굴삭기
5. 덤프트럭

---

## 5. 로그 확인

### Document Service 로그
```bash
# 실행 중인 터미널에서 직접 확인 가능
# 또는 로그 파일 (있다면)
tail -f logs/document-service.log
```

### Equipment Service 로그
```bash
# 실행 중인 터미널에서 직접 확인 가능
# 또는 로그 파일 (있다면)
tail -f logs/equipment-service.log
```

---

## 6. 데이터베이스 확인

### PostgreSQL 접속
```bash
docker exec -it postgres psql -U postgres -d skep_document
```

### 테이블 조회
```sql
-- Document Service
\dt
SELECT * FROM document_types;
SELECT * FROM documents;

-- Equipment Service
\dt
SELECT * FROM equipment_types;
SELECT * FROM equipment;
SELECT * FROM persons;
SELECT * FROM equipment_assignments;
```

---

## 7. Docker 빌드 및 실행

### 개별 빌드
```bash
# Document Service
cd document-service
docker build -t skep-document-service:1.0.0 .
docker run -d \
  --name document-service \
  -p 8082:8082 \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/skep_document \
  -e SPRING_DATASOURCE_USERNAME=postgres \
  -e SPRING_DATASOURCE_PASSWORD=postgres \
  skep-document-service:1.0.0

# Equipment Service
cd ../equipment-service
docker build -t skep-equipment-service:1.0.0 .
docker run -d \
  --name equipment-service \
  -p 8083:8083 \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/skep_equipment \
  -e SPRING_DATASOURCE_USERNAME=postgres \
  -e SPRING_DATASOURCE_PASSWORD=postgres \
  -e DOCUMENT_SERVICE_URL=http://document-service:8082/api/documents \
  skep-equipment-service:1.0.0
```

---

## 8. 문제 해결

### 포트 충돌
```bash
# 이미 사용 중인 포트 확인
lsof -i :8082
lsof -i :8083

# 기존 프로세스 종료
kill -9 <PID>
```

### 데이터베이스 연결 실패
```bash
# PostgreSQL 상태 확인
docker ps | grep postgres

# PostgreSQL 재시작
docker restart postgres

# 데이터베이스 재생성
docker exec -it postgres psql -U postgres -c "DROP DATABASE IF EXISTS skep_document;"
docker exec -it postgres psql -U postgres -c "CREATE DATABASE skep_document;"
```

### Gradle 캐시 문제
```bash
# Gradle 캐시 초기화
./gradlew clean --refresh-dependencies
./gradlew build -x test
```

---

## 9. 개발 팁

### IDE 설정 (IntelliJ IDEA)
1. File > Open > 프로젝트 폴더 선택
2. Gradle 자동 임포트 허용
3. Run > Edit Configurations
4. Application 추가
   - Main class: `com.skep.documentservice.DocumentServiceApplication`
   - Working directory: `document-service`

### 핫 리로드 (Hot Reload)
```bash
# pom.xml이나 build.gradle에 devtools 추가
implementation 'org.springframework.boot:spring-boot-devtools'

# 파일 저장 시 자동 재컴파일
```

### API 테스트 도구
- **REST Client**: IntelliJ IDE 내장
- **Postman**: https://www.postman.com/
- **cURL**: 명령줄 도구

---

## 10. 다음 단계

1. **인증 추가**: JWT 또는 OAuth2
2. **API 문서화**: Swagger/SpringFox
3. **캐싱**: Redis 통합
4. **모니터링**: Micrometer + Prometheus
5. **배포**: Kubernetes 또는 클라우드 플랫폼

---

## 지원 및 문서

- 자세한 문서: `README.md`
- 구현 보고서: `IMPLEMENTATION_SUMMARY.md`
- API 명세: 각 서비스의 Controller 클래스

**성공적인 개발을 기원합니다!** 🚀
