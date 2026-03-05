# homelab

Mac mini 홈서버 운영 스택. Docker Compose 기반.

## 아키텍처

```
인터넷
  │
  ▼
Cloudflare (DDNS + Proxy)
  │
  ▼
Gateway (Nginx + Certbot)
  │
  ├── www.jigu.dev ──▶ jigu-core:8080
  └── supa.jigu.dev ──▶ Supabase Kong:8000
```

모든 서비스는 `jigu-net` Docker 외부 네트워크로 연결.

## 서비스

| 디렉토리 | 서비스 | 설명 |
|----------|--------|------|
| [`gateway/`](./gateway/) | Nginx · Certbot · DDNS | 리버스 프록시, SSL, Cloudflare DDNS |
| [`supabase/`](./supabase/) | Supabase | 자체 호스팅 Supabase (supa.jigu.dev) |
| [`postgres/`](./postgres/) | PostgreSQL 18 | 공용 데이터베이스 |
| [`gitea/`](./gitea/) | Gitea | 자체 Git 저장소 |

## 시작하기

### 1. 네트워크 생성

```bash
docker network create jigu-net
```

### 2. 각 서비스 실행

```bash
# Gateway (Nginx + Certbot + DDNS)
cd gateway && cp .env.example .env  # .env 편집 후
docker compose up -d

# Supabase
cd supabase && cp .env.example .env  # .env 편집 후
docker compose up -d

# PostgreSQL
cd postgres && cp .env.example .env  # .env 편집 후
docker compose up -d

# Gitea
cd gitea
docker compose up -d
```

각 서비스별 상세 설정은 해당 디렉토리의 README 참고.

## 네트워크

모든 서비스가 `jigu-net` 외부 네트워크를 공유.
컨테이너 이름으로 서로 참조 가능 (`postgres`, `gitea`, `nginx`, `supabase-kong` 등).
