# SKEP Platform - 빠른 시작 가이드

## 전제 조건

- Docker Desktop 4.x 이상 (실행 중)
- Java 21 (로컬 Gradle 빌드 시 필요)
- Git

## 1. 환경 설정

```bash
cd /Users/jojo/pro/skep

# 환경 변수 파일 생성
cp .env.example .env

# 필수 값 수정 (최소 설정)
vi .env
```

`.env` 최소 필수 설정:
```env
DB_PASSWORD=skep_secure_pass_2024
REDIS_PASSWORD=
JWT_SECRET=skep-super-secret-jwt-key-256bit-minimum-32chars-long-here
AWS_S3_BUCKET=skep-documents-dev
AWS_REGION=ap-northeast-2
```

## 2. 로컬 전체 시작 (자동)

```bash
chmod +x scripts/*.sh
./scripts/start-local.sh all
```

또는 단계별 시작:

```bash
# 1단계: DB + Redis만
./scripts/start-local.sh infra

# 2단계: Mock 서비스 (OCR, GovAPI)
./scripts/start-local.sh mocks

# 3단계: 백엔드 서비스
./scripts/start-local.sh services

# 4단계: API Gateway
./scripts/start-local.sh gateway

# 5단계: Frontend
./scripts/start-local.sh frontend
```

## 3. 서비스 URL

| 서비스 | URL |
|--------|-----|
| **Frontend** (Flutter Web) | http://localhost:3000 |
| **API Gateway** | http://localhost:8080 |
| Auth Service | http://localhost:8081 |
| Document Service | http://localhost:8082 |
| Equipment Service | http://localhost:8083 |
| Dispatch Service | http://localhost:8084 |
| Inspection Service | http://localhost:8085 |
| Settlement Service | http://localhost:8086 |
| Notification Service | http://localhost:8087 |
| Location Service | http://localhost:8088 |
| OCR Mock | http://localhost:8089 |
| GovAPI Mock | http://localhost:8090 |

## 4. API 테스트

```bash
# 빠른 API 검증
./scripts/test-api.sh

# 개별 엔드포인트 테스트
# 로그인
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@skep.com","password":"Admin1234!"}'

# Health check
curl http://localhost:8080/actuator/health
```

## 5. 로그 확인

```bash
# 특정 서비스 로그
docker compose logs -f auth-service
docker compose logs -f api-gateway

# 전체 로그
docker compose logs -f

# 에러만
docker compose logs | grep ERROR
```

## 6. 서비스 재빌드

코드 수정 후:
```bash
# 단일 서비스 재빌드
docker compose up -d --build auth-service

# 전체 재빌드
docker compose up -d --build
```

## 7. 종료

```bash
# 서비스만 종료 (데이터 유지)
docker compose down

# 데이터까지 초기화
docker compose down -v
```

## 8. GitHub에 푸시

```bash
git remote set-url origin https://github.com/cho-y-j/skep.git
git add .
git commit -m "feat: initial SKEP platform implementation"
git push -u origin main
```

## 9. AWS 배포 준비

### GitHub Actions 시크릿 설정
GitHub → Settings → Secrets → Actions:

| Secret | 값 |
|--------|----|
| `AWS_ACCOUNT_ID` | AWS 계정 ID (12자리) |
| `AWS_ROLE_TO_ASSUME` | `arn:aws:iam::{ACCOUNT_ID}:role/github-actions-role` |

### Terraform 첫 실행
```bash
# Terraform 상태 저장용 S3 버킷 먼저 생성
aws s3 mb s3://skep-terraform-state-{YOUR_ACCOUNT_ID} --region ap-northeast-2

# Terraform 초기화
cd infrastructure/terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### OIDC IAM Role 설정
```bash
# GitHub OIDC 프로바이더 등록 및 Role 생성
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

## 트러블슈팅

**서비스가 시작 안 될 때:**
```bash
docker compose logs auth-service | tail -50
```

**DB 연결 실패:**
```bash
# postgres 컨테이너 직접 접속
docker compose exec postgres psql -U skep_user -d skep_db
```

**포트 충돌:**
`.env` 파일에서 포트 번호 수정 후 재시작

**Flutter Web 빌드 시간:**
Flutter 빌드는 첫 번째 실행 시 5-10분 소요됩니다.
개발 중에는 Flutter 직접 실행 권장:
```bash
cd frontend/skep_app
flutter pub get
flutter run -d web-server --web-port 3000
```
