# PostgreSQL

PostgreSQL 18 Docker Compose 설정.

## 파일 구조

```
postgres/
├── docker-compose.yml        # 서비스 정의
├── .env.example              # 환경 변수 예시
├── .env                      # 실제 환경 변수 (gitignore)
└── initdb/                   # 초기화 SQL/스크립트 (선택)
```

## 시작하기

```bash
cp .env.example .env
# .env 파일에서 POSTGRES_PASSWORD 수정

docker compose up -d
```

## 환경 변수

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `POSTGRES_PASSWORD` | (필수) | superuser 패스워드 |
| `POSTGRES_USER` | `postgres` | superuser 계정명 |
| `POSTGRES_DB` | `postgres` | 초기 생성 DB 이름 |
| `POSTGRES_PORT` | `5432` | 호스트 포트 |

## PostgreSQL 18 주요 특징

### 비동기 I/O (`io_method`)

PG18부터 기본적으로 AIO가 활성화되어 읽기 성능이 향상됨.

| 옵션 | 설명 |
|------|------|
| `worker` | 백그라운드 프로세스가 I/O 처리. 기본값. 모든 환경 지원 |
| `io_uring` | Linux io_uring 사용. 가장 빠르나 공식 Docker 이미지 미지원 |
| `sync` | 동기 I/O. PG17 이전 방식 |

### UUIDv7

별도 설정 없이 즉시 사용 가능.

```sql
SELECT uuidv7();

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuidv7()
);
```

## 자주 쓰는 명령어

```bash
# 실행
docker compose up -d

# 로그
docker compose logs -f

# psql 접속
docker exec -it postgres psql -U postgres

# 중지
docker compose down

# 중지 + 데이터 삭제
docker compose down -v
```
