# SKEP AWS Infrastructure - 완전한 IaC 구현 완료

## 생성된 파일 목록

### Terraform 모듈 (infrastructure/terraform/modules/)

#### 1. VPC 모듈 (vpc/)
- **main.tf**: VPC, 서브넷(Public/Private), IGW, NAT Gateway, Route Tables, Security Groups
  - 4개 Security Groups: ALB, ECS Tasks, RDS, ElastiCache
- **variables.tf**: VPC CIDR, 서브넷 CIDR, AZ 정의
- **outputs.tf**: VPC ID, 서브넷 ID, Security Group ID 출력

#### 2. ECR 모듈 (ecr/)
- **main.tf**: 12개 서비스별 ECR 저장소 + 라이프사이클 정책 + 이미지 스캔
  - 최근 10개 이미지만 유지하는 자동 정책
  - Docker Hub, GHCR pull-through cache rule
  - Enhanced registry scanning configuration
- **outputs.tf**: 저장소 URL, Registry ID 출력

#### 3. RDS 모듈 (rds/)
- **main.tf**: Aurora PostgreSQL 16 클러스터 + 매개변수 그룹 + KMS 암호화
  - Primary 인스턴스 + 읽기 복제본 (prod only)
  - CloudWatch Logs 활성화
  - Parameter Store에 접속 정보 저장 (SecureString)
  - IAM 데이터베이스 인증 활성화
- **variables.tf**: 환경별 인스턴스 클래스 정의
  - dev: db.t3.medium
  - prod: db.r6g.large

#### 4. ElastiCache 모듈 (elasticache/)
- **main.tf**: Redis 7.x 클러스터 + 매개변수 그룹 + CloudWatch Logs
  - 환경별 노드 수: dev=2, prod=3
  - 자동 장애조치 (prod only)
  - Multi-AZ 활성화 (prod only)
  - AUTH 토큰 기반 인증
  - CloudWatch 느린 쿼리 및 엔진 로그
- **variables.tf**: 환경별 노드 타입

#### 5. S3 모듈 (s3/)
- **main.tf**: 2개 버킷 (문서, 자산) + KMS 암호화 + 버저닝 + CORS + 라이프사이클
  - documents 버킷: 버저닝, 30일 오래된 버전 삭제
  - assets 버킷: 불완전 멀티파트 업로드 7일 후 삭제
  - CORS 설정: skep.on1.kr, localhost:3000, localhost:8080 허용
  - 버킷 정책: ECS Task Role만 접근 가능
  - 모든 객체 암호화

#### 6. ALB 모듈 (alb/)
- **main.tf**: Application Load Balancer + Target Groups + Listeners + 경로 기반 라우팅
  - HTTP → HTTPS 리다이렉트
  - 2개 Target Groups: API Gateway (8080), Frontend (80)
  - 경로 기반 라우팅: /api/* → api-gateway
  - 스티키 세션 활성화
  - Parameter Store에 ALB DNS 저장

#### 7. ECS 모듈 (ecs/)
- **main.tf**: ECS Cluster + 2개 Task Definitions + 2개 Services + IAM Roles
  - API Gateway Task: Spring Boot 애플리케이션
  - Frontend Task: 웹 애플리케이션
  - 환경변수: DB, Redis, 애플리케이션 설정
  - Secrets: DB/Redis 비밀번호 (Parameter Store에서 로드)
  - CloudWatch 로그 설정
  - ECS Task Role: S3, Parameter Store, SES, KMS 권한
  - Auto Scaling Target (prod only): CPU 70%, 메모리 80% 기준
  - 롤링 배포 설정: 최대 200%, 최소 100%

### 환경별 설정 (infrastructure/terraform/environments/)

#### Dev 환경 (dev/)
- **main.tf**: 모든 모듈 호출 + CloudWatch 알람 (ALB 비정상 타겟)
- **variables.tf**: 기본값 정의
- **terraform.tfvars**: 환경별 설정값

#### Prod 환경 (prod/)
- **main.tf**: 모든 모듈 호출 + 추가 CloudWatch 알람 (RDS/Redis CPU)
- **variables.tf**: 기본값 정의
- **terraform.tfvars**: 환경별 설정값

### GitHub Actions 워크플로우 (.github/workflows/)

#### 1. ci.yml - CI 파이프라인
- **트리거**: develop, main 브랜치로의 push/PR
- **작업**:
  - 11개 Java 마이크로서비스 테스트 및 빌드 (병렬)
  - Flutter 빌드 검증
  - Docker 빌드 검증 (push 없음)
  - Trivy 보안 취약점 스캔
  - 실패 계속 실행 모드

#### 2. deploy-dev.yml - 개발 배포
- **트리거**: develop 브랜치 push
- **작업**:
  - 12개 서비스 Docker 이미지 ECR 푸시 (병렬)
  - OIDC 기반 AWS 인증
  - Layer caching으로 빌드 속도 최적화
  - ECS 서비스 강제 재배포
  - 배포 완료 대기

#### 3. deploy-prod.yml - 운영 배포
- **트리거**: main 브랜치 push (수동 승인 필요)
- **작업**:
  - deploy-dev와 동일하되 prod 환경 대상
  - Slack 알림 (성공/실패)
  - Environment approval 확인

#### 4. terraform-plan.yml - Terraform 계획
- **트리거**: infrastructure/ 변경사항이 있는 PR
- **작업**:
  - dev, prod 환경 계획 (병렬)
  - 포맷, 검증, 계획 수행
  - PR 코멘트에 계획 결과 추가

### 배포 및 설정 스크립트 (scripts/)

#### setup-parameter-store.sh
- AWS Parameter Store에 모든 애플리케이션 설정 등록
- DB 비밀번호, Redis 토큰, JWT 시크릿 등 관리
- 태그를 통한 리소스 분류

### 문서

#### DEPLOYMENT.md (infrastructure/)
- 완전한 배포 가이드 (500+ 줄)
- 전제 조건, 초기 설정, Terraform 상태 관리
- 환경별 배포 단계별 지시사항
- GitHub Actions OIDC 설정
- 모니터링, 문제 해결, 재해 복구

#### README.md
- 프로젝트 개요, 빠른 시작 가이드
- AWS 아키텍처 개요
- 배포 흐름도
- 보안 모범 사례
- 모니터링 및 자동 스케일링

#### .gitignore
- Terraform 상태 파일, 로컬 변수 파일 제외
- IDE, OS, 빌드 디렉토리 제외

## 핵심 기능

### 고가용성 (HA)
- RDS Aurora: Multi-AZ, 자동 장애조치
- Redis: Multi-AZ, 자동 장애조치
- ECS: 다중 AZ에 배포
- ALB: 다중 AZ 트래픽 분산

### 보안
- VPC 격리 (Public/Private 서브넷)
- Security Groups: 최소 권한 설정
- KMS 암호화: RDS, S3, ElastiCache
- IAM Roles: 최소 권한 원칙
- Parameter Store: 민감한 정보 관리
- HTTPS 강제 (ALB)

### 모니터링
- CloudWatch Logs: 모든 ECS 태스크
- CloudWatch Alarms: ALB, RDS, Redis
- Container Insights: ECS 메트릭
- 자동 스케일링: CPU/메모리 기반

### CI/CD
- GitHub Actions: 자동화된 빌드 및 배포
- OIDC: 안전한 AWS 인증
- Docker 이미지 캐싱: 빠른 빌드
- 자동 테스트: 각 PR에 수행
- 모니터링 및 알림

## 배포 준비 체크리스트

### 사전 준비
- [ ] AWS 계정 생성
- [ ] ACM 인증서 발급 (skep.on1.kr)
- [ ] Terraform state 버킷 및 DynamoDB 테이블 생성
- [ ] GitHub 리포지토리 설정
- [ ] OIDC Provider 생성
- [ ] IAM Role 생성 및 정책 추가

### 배포
- [ ] AWS 자격증명 설정
- [ ] Terraform 변수 설정 (db_master_password, redis_auth_token)
- [ ] Dev 환경 배포
- [ ] Parameter Store 설정
- [ ] Prod 환경 배포
- [ ] GitHub Secrets 설정
- [ ] GitHub Actions 테스트

### 검증
- [ ] VPC 및 서브넷 확인
- [ ] ECR 저장소 생성 확인
- [ ] RDS 클러스터 확인
- [ ] Redis 클러스터 확인
- [ ] ECS 서비스 확인
- [ ] ALB 헬스 체크 확인
- [ ] CloudWatch 로그 확인

## 비용 추정 (월간)

### Dev 환경
- RDS: db.t3.medium: ~$150
- Redis: cache.t3.micro: ~$30
- ECS (1 task × 256 CPU, 512 MB): ~$10
- ALB: ~$20
- NAT Gateway: ~$30
- CloudWatch/S3: ~$10
- **총계: ~$250**

### Prod 환경
- RDS: db.r6g.large (2 인스턴스): ~$400
- Redis: cache.r6g.large (3 노드): ~$300
- ECS (2-4 tasks): ~$100
- ALB: ~$20
- NAT Gateway: ~$60
- CloudWatch/S3: ~$20
- **총계: ~$900**

## 다음 단계

1. AWS 환경 준비
2. Terraform 초기 설정 (state 버킷, DynamoDB)
3. Dev 환경 배포
4. CI/CD 파이프라인 테스트
5. Prod 환경 배포
6. 모니터링 및 운영

---

생성 날짜: 2026-03-19
DevOps 인프라 코드: 완전하고 프로덕션 준비 완료
