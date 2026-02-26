#!/bin/bash

# 설정 (환경변수로 주입)
ZONE_NAME="${CF_ZONE_NAME}"
API_TOKEN="${CF_API_TOKEN}"

# 필수 환경변수 검증
if [[ -z "$ZONE_NAME" || -z "$API_TOKEN" || -z "$CF_RECORDS" ]]; then
  echo "[ERROR] CF_ZONE_NAME, CF_API_TOKEN, CF_RECORDS 환경변수가 필요합니다."
  exit 1
fi

# CF_RECORDS: 쉼표로 구분된 "도메인|proxied" 형식
# 예) CF_RECORDS=example.com|false,git.example.com|true
IFS=',' read -ra RECORDS <<< "${CF_RECORDS}"

# 현재 시간 구하기
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

# 외부 IP 가져오기
IP=$(curl -s https://ipv4.icanhazip.com)

# Zone ID 가져오기
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$ZONE_NAME" \
  -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
  | jq -r '.result[0].id')

# 레코드 업데이트 함수
update_record() {
  local RECORD_NAME=$1
  local PROXIED=$2

  RECORD_INFO=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$RECORD_NAME" \
    -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json")

  RECORD_ID=$(echo "$RECORD_INFO" | jq -r '.result[0].id')
  OLD_IP=$(echo "$RECORD_INFO" | jq -r '.result[0].content')

  if [[ "$IP" != "$OLD_IP" ]]; then
    echo "[$CURRENT_TIME]  🔄 $RECORD_NAME Change IP: $OLD_IP → $IP"
    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
      -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"$RECORD_NAME\",\"content\":\"$IP\",\"ttl\":120,\"proxied\":$PROXIED}"
  else
    echo "[$CURRENT_TIME] ✅ $RECORD_NAME Current IP: $IP"
  fi
}

# 모든 레코드에 대해 업데이트 수행
for ENTRY in "${RECORDS[@]}"; do
  IFS='|' read -r RECORD_NAME PROXIED <<< "$ENTRY"
  update_record "$RECORD_NAME" "$PROXIED"
done
