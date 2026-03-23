# SKEP 프로젝트 기여 가이드

SKEP 프로젝트에 기여해주셔서 감사합니다! 이 문서는 기여 프로세스를 설명합니다.

## 🤝 기여 방법

### 1. Fork & Clone

```bash
# Fork the repository on GitHub

# Clone your fork
git clone https://github.com/your-username/skep.git
cd skep

# Add upstream remote
git remote add upstream https://github.com/cho-y-j/skep.git
```

### 2. 브랜치 생성

```bash
# Update your local repository
git fetch upstream
git checkout -b develop origin/develop

# Create your feature branch
git checkout -b feature/your-feature-name
```

브랜치 네이밍 컨벤션:
- `feature/` - 새로운 기능
- `fix/` - 버그 수정
- `docs/` - 문서 개선
- `refactor/` - 코드 리팩토링
- `test/` - 테스트 추가

### 3. 변경 사항 커밋

```bash
git add .
git commit -m "feat: 기능 설명"
```

커밋 메시지 형식 (Conventional Commits):
```
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

예시:
```
feat(equipment-service): equipment 조회 API 추가

- equipment 목록 조회 엔드포인트 구현
- 페이지네이션 지원
- 검색 필터 기능 추가

Closes #123
```

타입:
- `feat` - 새로운 기능
- `fix` - 버그 수정
- `docs` - 문서 변경
- `style` - 코드 스타일 변경 (포맷, 세미콜론 등)
- `refactor` - 코드 리팩토링
- `perf` - 성능 개선
- `test` - 테스트 추가/수정
- `chore` - 빌드, 의존성 등의 변경

### 4. Push & Pull Request

```bash
# Push your changes
git push origin feature/your-feature-name

# Create Pull Request on GitHub
```

PR 제목:
```
feat(auth-service): JWT 토큰 자동 갱신 기능 추가
```

PR 설명 템플릿:
```markdown
## 설명
이 PR은 [기능/수정]을 구현합니다.

## 변경 사항
- [ ] 기능 A 구현
- [ ] 기능 B 구현
- [ ] 테스트 추가
- [ ] 문서 업데이트

## 테스트 방법
1. 다음 단계를 따라 테스트하세요
2. ...

## 체크리스트
- [ ] 코드 스타일 가이드 준수
- [ ] 모든 테스트 통과
- [ ] 문서 업데이트됨
- [ ] 관련 이슈 링크됨 (Closes #123)
```

## 📋 코드 스타일 가이드

### Java

```java
// 클래스 네이밍: PascalCase
public class UserService {

    // 메서드 네이밍: camelCase
    public User getUserById(Long id) {
        // ...
    }

    // 상수: UPPER_SNAKE_CASE
    private static final int MAX_RETRY_COUNT = 3;
}
```

### 포매팅
- 들여쓰기: 4 spaces
- 한 줄 최대 길이: 100 characters
- import 정렬: 자동 포매팅 도구 사용

### JavaScript/Node.js

```javascript
// 함수명: camelCase
const getUserData = async (userId) => {
  // 상수: UPPER_SNAKE_CASE
  const DEFAULT_TIMEOUT = 5000;

  // 변수: camelCase
  const userData = await fetchUser(userId);

  return userData;
};
```

## ✅ 테스트

### Java 단위 테스트

```bash
mvn test
```

### Node.js 테스트

```bash
npm test
```

### 통합 테스트

```bash
mvn verify
```

테스트 커버리지 최소 70% 이상 유지

## 📚 문서 작성

### Javadoc

```java
/**
 * 사용자를 ID로 조회합니다.
 *
 * @param id 사용자 ID
 * @return 조회된 사용자 정보
 * @throws UserNotFoundException 사용자를 찾을 수 없는 경우
 */
public User getUserById(Long id) {
    // ...
}
```

### JSDoc

```javascript
/**
 * 사용자 정보를 조회합니다.
 *
 * @param {number} userId - 사용자 ID
 * @returns {Promise<User>} 사용자 정보
 * @throws {Error} 사용자를 찾을 수 없는 경우
 */
async function getUserData(userId) {
    // ...
}
```

## 🐛 버그 리포트

### 버그 리포트 작성

```markdown
## 버그 설명
버그의 간단한 설명

## 재현 방법
1. ...
2. ...
3. ...

## 예상 동작
예상되는 결과

## 실제 동작
실제 발생한 결과

## 환경
- OS: Windows/Mac/Linux
- Browser/Runtime: Chrome/Node.js v16
- Service: api-gateway v1.0.0

## 추가 정보
스크린샷, 에러 로그 등
```

## ✨ 기능 요청

### 기능 요청 작성

```markdown
## 기능 설명
구현하고 싶은 기능의 설명

## 사용 사례
왜 이 기능이 필요한지, 어디에 사용되는지

## 예상 동작
기능이 어떻게 동작해야 하는지

## 대안
고려한 다른 방법들
```

## 🔄 리뷰 프로세스

### PR 리뷰 체크리스트

1. **코드 품질**
   - [ ] 코드 스타일 가이드 준수
   - [ ] 중복 코드 없음
   - [ ] 적절한 에러 처리
   - [ ] 보안 이슈 없음

2. **기능성**
   - [ ] 요구사항 충족
   - [ ] 테스트 통과
   - [ ] 엣지 케이스 처리

3. **문서**
   - [ ] 코드 주석 적절함
   - [ ] API 문서 업데이트
   - [ ] README 업데이트 필요시

4. **성능**
   - [ ] 성능 저하 없음
   - [ ] 메모리 누수 없음
   - [ ] 쿼리 최적화됨

### 리뷰 받기

- PR 작성 후 최소 2명의 리뷰 필요
- 모든 comments에 응답
- Suggestion은 수용하거나 이유 설명
- Approved 후에 merge 가능

## 📦 릴리스 프로세스

### 버전 관리 (Semantic Versioning)

- `MAJOR.MINOR.PATCH` (예: 1.2.3)
- `MAJOR`: 호환되지 않는 변경
- `MINOR`: 하위 호환 새 기능
- `PATCH`: 하위 호환 버그 수정

### 릴리스 절차

1. `develop` 브랜치에서 최신 코드 확인
2. 버전 번호 업데이트
3. CHANGELOG.md 작성
4. PR 생성 및 리뷰
5. `main` 브랜치에 merge
6. Git tag 생성 (`v1.2.3`)
7. GitHub Release 생성

## 🆘 도움말

### 질문 있을 때

- GitHub Discussions 이용
- Team Slack #development 채널
- Email: dev-team@skep.on1.kr

### 문제 발생 시

1. 기존 이슈 검색
2. 해당하는 이슈 없으면 새로 생성
3. 상세한 정보 포함
4. 답변 기다리기

## 📝 라이선스

프로젝트에 기여함으로써 MIT License 하의 라이선스를 동의합니다.

## 🎓 추가 리소스

- [Java 코딩 컨벤션](https://www.oracle.com/java/technologies/javase/codeconventions-150003.pdf)
- [Node.js 베스트 프랙티스](https://nodejs.org/en/docs/guides/nodejs-performance-best-practices/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)

---

기여해주셔서 감사합니다! 🙏
