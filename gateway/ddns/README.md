# Cloudflare DDNS

Cloudflare API를 사용해 동적 공인 IP를 DNS A 레코드에 자동 반영하는 컨테이너입니다.
10분마다 현재 공인 IP를 확인하고, IP가 변경된 경우에만 레코드를 업데이트합니다.

---

## 사전 준비

### 1. Cloudflare API 토큰 발급

1. [Cloudflare 대시보드](https://dash.cloudflare.com) → 우측 상단 프로필 → **My Profile**
2. **API Tokens** → **Create Token**
3. **Edit zone DNS** 템플릿 선택
4. Zone Resources: `Include` → `Specific zone` → 해당 도메인 선택
5. **Continue to summary** → **Create Token**
6. 생성된 토큰을 안전하게 보관 (다시 확인 불가)

### 2. Cloudflare DNS A 레코드 등록

DDNS 스크립트는 기존에 존재하는 레코드만 업데이트합니다. 레코드가 없으면 업데이트되지 않으므로 먼저 수동 등록이 필요합니다.

1. Cloudflare 대시보드 → 해당 도메인 → **DNS** → **Records**
2. **Add record** 클릭 후 A 레코드 추가:

| Type | Name | Content (임시 IP) | Proxy status |
|------|------|-------------------|--------------|
| A | `@` | `1.2.3.4` | DNS only |
| A | `git` | `1.2.3.4` | Proxied |

> `update.sh`의 `RECORDS` 배열에서 설정한 `proxied` 값과 일치해야 합니다.

**Proxy status 선택 기준:**
- `Proxied (true)` — 실제 서버 IP가 숨겨지고 Cloudflare CDN·DDoS 방어가 적용됩니다. HTTP/HTTPS 서비스에 권장합니다.
- `DNS only (false)` — 실제 IP가 노출됩니다. SSH, 게임 서버 등 비HTTP 서비스나 루트 도메인에 사용합니다.

---

## 설정

### .env 파일 작성

`gateway/.env.example`을 복사해 `gateway/.env`를 만들고 값을 채워주세요.

```bash
cp gateway/.env.example gateway/.env
```

```env
CF_ZONE_NAME=your-domain.com
CF_API_TOKEN=your-api-token

# 쉼표로 구분, 형식: 도메인|proxied여부
CF_RECORDS=your-domain.com|false,git.your-domain.com|true
```

---

## 실행

### docker compose로 실행 (권장)

`gateway/docker-compose.yml`에 이미 포함되어 있습니다.

```bash
# 외부 네트워크가 없다면 먼저 생성
docker network create ger-net

cd gateway
docker compose up -d cloudflare-ddns
```

### 단독 실행

```bash
docker build -t cloudflare-ddns ./ddns
docker run -d \
  --name cloudflare-ddns \
  --restart unless-stopped \
  -e TZ=Asia/Seoul \
  cloudflare-ddns
```

### 로그 확인

```bash
docker logs -f cloudflare-ddns
```

정상 동작 시 아래와 같이 출력됩니다:

```
[2025-01-01 12:00:00] ✅ your-domain.com Current IP: 1.2.3.4
[2025-01-01 12:00:00] ✅ git.your-domain.com Current IP: 1.2.3.4
```

IP가 변경된 경우:

```
[2025-01-01 12:00:00] 🔄 your-domain.com Change IP: 1.2.3.4 → 5.6.7.8
```

---

## Docker 리소스 설정

### Mac Mini M4 (16GB RAM, 256GB SSD) 권장 설정

#### Docker Desktop VM

**Docker Desktop** → Settings → Resources:

| 항목 | 권장값 | 근거 |
|------|--------|------|
| CPU | 4~6코어 | M4 10코어 중 macOS용 여유 확보 |
| Memory | 8GB | 전체 16GB의 절반, 나머지는 macOS용 |
| Swap | 1~2GB | 메모리 부족 시 완충 |
| Virtual disk | 64GB | 홈랩 이미지·볼륨 수에 따라 조정 |

> **OrbStack 추천:** Apple Silicon Mac에서는 Docker Desktop 대신 [OrbStack](https://orbstack.dev)을 사용하면 VM 오버헤드가 적고 성능이 뛰어납니다. 무료 플랜으로 홈랩 운영에 충분합니다.

#### cloudflare-ddns 컨테이너

이 컨테이너는 10분마다 짧은 HTTP 요청만 발생시키므로 리소스 소비가 거의 없습니다.

| 항목 | 실사용량 | 비고 |
|------|----------|------|
| CPU | < 0.01코어 | 대부분 sleep 상태 |
| Memory | ~10MB | |
| Network | < 1KB/10분 | API 호출만 |

별도 제한 없이 운영해도 무방하지만, `docker-compose.yml`에서 명시적으로 제한하려면:

```yaml
services:
  cloudflare-ddns:
    build: ./ddns
    deploy:
      resources:
        limits:
          cpus: '0.10'
          memory: 64M
```

---

## 보안

- `gateway/.env`는 `.gitignore`에 등록되어 있어 git에 커밋되지 않습니다.
- `gateway/.env.example`에는 빈 값만 포함되어 있어 저장소에 안전하게 커밋됩니다.
- API 토큰을 재발급해야 하는 경우 Cloudflare 대시보드 → API Tokens → 해당 토큰 Roll 또는 Delete 후 재생성하세요.

---

## 문제 해결

| 증상 | 원인 | 해결 |
|------|------|------|
| `ZONE_ID` 가 null | 도메인명 오류 또는 API 토큰 권한 부족 | `ZONE_NAME` 및 토큰의 Zone 범위 확인 |
| `RECORD_ID` 가 null | DNS 레코드 미등록 | Cloudflare 대시보드에서 A 레코드 먼저 수동 등록 |
| IP 변경 없이 계속 업데이트 | `icanhazip.com` 응답 이상 | `curl -s https://ipv4.icanhazip.com` 로 직접 확인 |
| 컨테이너가 즉시 종료 | 스크립트 오류 | `docker logs cloudflare-ddns` 로 에러 메시지 확인 |
