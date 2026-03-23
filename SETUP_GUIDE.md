# SKEP 프로젝트 기본 구조 설정 가이드

## 📦 생성된 파일 목록 및 설명

### 1. 환경 설정 파일

#### `.env.example`
- 모든 서비스의 환경 변수 템플릿
- 데이터베이스, Redis, JWT, AWS, FCM, 로깅 등 설정
- **사용**: `cp .env.example .env` 후 실제 값으로 수정

#### `.env` (생성 필요)
- 실제 환경 변수 파일
- `.gitignore`에 포함되어 있어 Git에 커밋되지 않음

### 2. Docker Compose 파일

#### `docker-compose.yml` (개발 환경)
**포함 서비스:**
- PostgreSQL 16 (포트 5432)
- Redis 7 (포트 6379)
- OCR Service Mock (포트 8089)
- Government API Service Mock (포트 8090)
- 9개 Spring Boot 마이크로서비스 (포트 8080-8088)
- Flutter Frontend (포트 3000)

**특징:**
- 자동 헬스 체크
- 의존성 관리 (depends_on)
- 네트워크 격리 (skep-network)
- 데이터 볼륨 지속성

**사용:**
```bash
docker-compose up -d
```

#### `docker-compose.prod.yml` (프로덕션 환경)
- AWS RDS (외부 PostgreSQL)
- AWS ElastiCache (외부 Redis)
- 환경 변수 오버라이드
- 높은 가용성 설정

**사용:**
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### 3. 빌드 및 배포 스크립트

#### `scripts/build-all.sh`
- 모든 마이크로서비스의 Docker 이미지 빌드
- 선택적 Docker 레지스트리 지정
- 이미지 태깅 지원

**사용:**
```bash
./scripts/build-all.sh
./scripts/build-all.sh --tag v1.0.0
./scripts/build-all.sh --registry 123456789.dkr.ecr.ap-northeast-2.amazonaws.com/
```

#### `scripts/deploy-dev.sh`
- ECR에 이미지 푸시
- ECS Task Definition 생성
- ECS 서비스 업데이트
- 배포 완료 대기

**사용:**
```bash
./scripts/deploy-dev.sh --account-id 123456789 --tag v1.0.0
```

#### `scripts/deploy-prod.sh`
- 프로덕션 배포 (승인 필수)
- ECR 저장소 자동 생성
- 배포 레코드 생성
- 상세한 로깅

**사용:**
```bash
./scripts/deploy-prod.sh --account-id 123456789 --tag stable
```

#### `scripts/init-db.sql`
- PostgreSQL 초기 스키마 생성
- 8개 스키마 정의 (auth, equipment, document, dispatch 등)
- 인덱스 및 트리거 설정
- 샘플 데이터 (역할, 권한)

### 4. 서비스별 Dockerfiles

#### Spring Boot 서비스 (9개)
```
services/
├── api-gateway/Dockerfile
├── auth-service/Dockerfile
├── document-service/Dockerfile
├── equipment-service/Dockerfile
├── dispatch-service/Dockerfile
├── inspection-service/Dockerfile
├── settlement-service/Dockerfile
├── notification-service/Dockerfile
└── location-service/Dockerfile
```

**특징:**
- Multi-stage build (Maven으로 컴파일, Alpine Linux로 실행)
- JVM 최적화 (-Xmx512m, G1GC)
- 헬스 체크 엔드포인트
- 각 서비스별 포트 (8080-8088)

#### Mock 서비스 (2개)

**OCR Service** (`services/ocr-service/`)
- Node.js 18 기반
- 문서 유형별 OCR 결과 시뮬레이션
- 엔드포인트:
  - `POST /api/ocr/extract` - 문서 텍스트 추출
  - `POST /api/ocr/validate` - 이미지 품질 검증
  - `GET /api/ocr/status` - 서비스 상태

**Government API Service** (`services/govapi-service/`)
- Node.js 18 기반
- 정부 공공 API 검증 시뮬레이션
- 엔드포인트:
  - `POST /api/verify/vehicle` - 차량 정보 검증
  - `POST /api/verify/license` - 운전면허 검증
  - `POST /api/verify/business` - 사업자등록증 검증
  - `POST /api/verify/insurance` - 보험 검증
  - `POST /api/verify/id-card` - 신분증 검증

#### Frontend
```
frontend/Dockerfile
```
- Flutter Web 빌드
- Node.js serve로 배포
- 포트 3000

### 5. 문서 파일

#### `README.md`
프로젝트 전체 가이드:
- 프로젝트 개요 및 아키텍처
- 빠른 시작 가이드
- 환경 설정
- 빌드 및 배포
- 데이터베이스 스키마
- 보안 설정
- 모니터링
- 문제 해결
- API 문서 링크

#### `CONTRIBUTING.md`
기여 가이드:
- Fork & Pull Request 프로세스
- 커밋 메시지 규칙 (Conventional Commits)
- 코드 스타일 가이드
- 테스트 작성
- 코드 리뷰 프로세스
- 릴리스 절차

#### `SETUP_GUIDE.md` (이 파일)
프로젝트 구조 및 설정 가이드

### 6. 설정 도구

#### `Makefile`
자주 사용되는 명령어 단축:
```bash
make help           # 명령어 목록
make up             # 서비스 시작
make down           # 서비스 중지
make logs           # 로그 조회
make health         # 헬스 체크
make build          # 이미지 빌드
make deploy-dev     # Dev 배포
make deploy-prod    # Prod 배포
make db-shell       # PostgreSQL 셸
make redis-shell    # Redis 셸
make clean          # 전체 정리
```

#### `.gitignore`
Git에서 제외할 파일:
- 환경 변수 파일 (.env)
- IDE 파일 (.idea, .vscode)
- 빌드 산출물 (target/, build/)
- 의존성 (node_modules, .mvn)
- OS 파일 (.DS_Store)

#### `.dockerignore`
Docker 빌드에서 제외:
- Git 파일
- IDE 파일
- 문서
- 로그
- 의존성

## 🚀 빠른 시작

### 1단계: 환경 설정
```bash
cp .env.example .env
# .env 파일 편집하여 실제 값 설정
```

### 2단계: 서비스 시작
```bash
docker-compose up -d
```

### 3단계: 상태 확인
```bash
# Makefile 사용
make health

# 또는 curl
curl http://localhost:8080/health
curl http://localhost:8089/health
curl http://localhost:8090/health
```

### 4단계: 데이터베이스 확인
```bash
make db-shell
# PostgreSQL 프롬프트에서
SELECT * FROM auth.users;
```

## 📂 디렉토리 구조

```
skep/
├── .env.example                 # 환경 변수 템플릿
├── .gitignore                   # Git 제외 파일
├── .dockerignore                # Docker 제외 파일
├── README.md                    # 프로젝트 설명
├── CONTRIBUTING.md              # 기여 가이드
├── SETUP_GUIDE.md              # 이 파일
├── Makefile                     # 명령어 단축
├── docker-compose.yml           # Dev 환경
├── docker-compose.prod.yml      # Prod 환경
│
├── scripts/                     # 배포 및 빌드 스크립트
│   ├── build-all.sh            # 모든 이미지 빌드
│   ├── deploy-dev.sh           # Dev 환경 배포
│   ├── deploy-prod.sh          # Prod 환경 배포
│   └── init-db.sql             # 데이터베이스 초기화
│
├── services/                    # 마이크로서비스
│   ├── api-gateway/            # API Gateway (8080)
│   ├── auth-service/           # 인증 서비스 (8081)
│   ├── document-service/       # 문서 서비스 (8082)
│   ├── equipment-service/      # 장비 서비스 (8083)
│   ├── dispatch-service/       # 투입 관리 (8084)
│   ├── inspection-service/     # 검사 관리 (8085)
│   ├── settlement-service/     # 정산 관리 (8086)
│   ├── notification-service/   # 알림 서비스 (8087)
│   ├── location-service/       # 위치 서비스 (8088)
│   ├── ocr-service/            # OCR 서비스 Mock (8089)
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── server.js
│   ├── govapi-service/         # 정부 API Mock (8090)
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── server.js
│   └── frontend/               # Flutter Web (3000)
│       └── Dockerfile
└── .env                        # 실제 환경 변수 (생성 후)
```

## 🔧 설정 및 커스터마이제이션

### 포트 변경
`docker-compose.yml`에서:
```yaml
services:
  api-gateway:
    ports:
      - "9000:8080"  # 호스트:컨테이너 포트 변경
```

### 데이터베이스 자격증명 변경
`.env`에서:
```bash
DB_USERNAME=new_user
DB_PASSWORD=new_password
```

### Redis 암호 설정
`.env`에서:
```bash
REDIS_PASSWORD=your_secure_redis_password
```

### AWS 설정
`.env`에서:
```bash
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=ap-northeast-2
AWS_S3_BUCKET=your_bucket_name
```

## 🧪 검증

### 모든 서비스 상태 확인
```bash
make ps
```

### 헬스 체크
```bash
make health
```

### 데이터베이스 연결 테스트
```bash
make test-connection
```

### 로그 확인
```bash
make logs
# 또는 특정 서비스
make logs-gateway
make logs-auth
```

## 📊 모니터링

### Prometheus 메트릭
```bash
curl http://localhost:8080/actuator/prometheus
```

### 서비스 통계
```bash
make stats
```

### 실시간 로그
```bash
docker-compose logs -f api-gateway
```

## 🔄 업데이트 및 유지보수

### 코드 업데이트 후
```bash
# 이미지 재빌드
make build

# 서비스 재시작
make restart
```

### 데이터베이스 마이그레이션
```bash
# SQL 파일 실행
make migrate
```

### 캐시 초기화
```bash
make redis-shell
# redis> FLUSHALL
# redis> exit
```

## ⚠️ 주의사항

### 프로덕션 배포
1. `.env` 파일의 민감한 정보 보호
2. JWT_SECRET은 안전한 값으로 변경
3. 데이터베이스 암호는 강력하게 설정
4. AWS 자격증명 관리
5. 배포 승인 프로세스 준수

### 데이터 보호
```bash
# 중요한 데이터 백업
docker-compose exec postgres pg_dump -U skep_user -d skep_db > backup.sql
```

### 보안 검사
- API 키 노출 확인
- 환경 변수 파일 커밋 금지
- 민감한 로그 기록 확인

## 🆘 문제 해결

### 포트 충돌
```bash
# 사용 중인 포트 확인
lsof -i :8080

# 또는 다른 포트로 변경
docker-compose.yml 수정 후 재시작
```

### 메모리 부족
```bash
# 컨테이너 메모리 제한 증가
docker-compose.yml에서 services.XXX.mem_limit 조정
```

### 디스크 공간 부족
```bash
# 오래된 이미지 제거
docker image prune

# 사용하지 않는 볼륨 제거
docker volume prune
```

### 데이터베이스 연결 오류
```bash
# PostgreSQL 재시작
docker-compose restart postgres

# 데이터 볼륨 초기화 (데이터 손실!)
docker-compose down -v
```

## 📚 추가 리소스

- [Docker 공식 문서](https://docs.docker.com/)
- [Spring Boot 문서](https://spring.io/projects/spring-boot)
- [PostgreSQL 문서](https://www.postgresql.org/docs/)
- [Redis 문서](https://redis.io/documentation)
- [Flutter 문서](https://flutter.dev/docs)

## 📞 지원

문제 발생 시:
1. README.md의 문제 해결 섹션 확인
2. GitHub Issues에 문제 보고
3. 팀 Slack #development 채널 문의

---

**최종 업데이트**: 2026-03-19
**프로젝트 버전**: v1.0.0
