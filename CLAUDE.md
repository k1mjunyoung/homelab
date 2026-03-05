# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Mac mini 홈서버 운영 스택. 모든 서비스는 Docker Compose 기반이며 `jigu-net` 외부 Docker 네트워크로 연결된다.

## 공통 명령어

```bash
# 외부 네트워크 생성 (최초 1회)
docker network create jigu-net

# 서비스 시작
cd <서비스디렉토리> && docker compose up -d

# 로그 확인
docker logs -f <컨테이너명>

# nginx 설정 검증 및 반영
docker exec nginx nginx -t
docker exec nginx nginx -s reload

# SSL 인증서 발급 (새 서브도메인)
docker exec certbot certbot certonly --webroot \
  -w /var/www/certbot -d <subdomain.jigu.dev> \
  --email your@email.com --agree-tos --non-interactive
```

## 아키텍처

```
인터넷 → Cloudflare (DDNS + Proxy) → gateway/nginx (80/443)
                                           │
                        ┌──────────────────┼──────────────────┐
                        ▼                  ▼                  ▼
               www.jigu.dev          supa.jigu.dev        (추가 서브도메인)
               jigu-core:8080    supabase-kong:8000
```

모든 컨테이너는 `jigu-net` 네트워크에서 컨테이너명으로 서로 참조한다.

## 서비스별 구조

### `gateway/` — 진입점
- **nginx**: 리버스 프록시. 설정 파일: `gateway/nginx/conf.d/default.conf`
- **certbot**: Let's Encrypt SSL 자동 갱신 (12시간 주기)
- **cloudflare-ddns**: 10분마다 공인 IP 확인 후 Cloudflare A 레코드 업데이트
- 설정: `gateway/.env` (CF_ZONE_NAME, CF_API_TOKEN, CF_RECORDS)
- `CF_RECORDS` 형식: `도메인|proxied여부` 쉼표 구분. CNAME 서브도메인은 등록 불필요

### `supabase/` — Supabase 자체 호스팅
- Kong(API GW) → Studio/Auth/REST/Realtime/Storage/Functions
- Kong은 `jigu-net`에 연결되어 nginx에서 직접 프록시
- DB(supabase-db)는 호스트 `0.0.0.0:5433`으로 노출 (SSH 터널 또는 포트포워딩으로 접속)
- 설정: `supabase/.env` (gitignore됨) — `supabase/.env.example` 참고
- 공개 URL: `https://supa.jigu.dev`

### `postgres/` — 공용 PostgreSQL 18
- 앱 서비스용 독립 PostgreSQL (Supabase DB와 별개)
- `jigu-net`을 통해 다른 컨테이너에서 `postgres:5432`로 접근

### `gitea/` — Git 서버
- 호스트 포트 3001(HTTP), 2201(SSH)로 노출
- 현재 nginx 라우팅 없음 (직접 포트 접근)

## 새 서브도메인 추가 절차

1. Cloudflare에 DNS 레코드 등록
2. `gateway/nginx/conf.d/default.conf`에 server 블록 추가 (파일 하단 예시 참고)
3. `docker exec nginx nginx -t` 로 문법 검증
4. SSL 인증서 발급 (위 명령어 참고)
5. `docker exec nginx nginx -s reload`

## gitignore 규칙

- `.env` — 모든 위치의 `.env` 파일 제외
- `gateway/certbot/conf/*` — SSL 인증서 로컬 전용
- `supabase/volumes/db/data/` — PostgreSQL 실제 데이터
- `supabase/volumes/storage/` — 사용자 업로드 파일
