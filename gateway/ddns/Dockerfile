FROM alpine:latest

RUN apk add --no-cache bash curl jq tzdata

COPY update.sh /update.sh
RUN chmod +x /update.sh

CMD ["bash", "-c", "while true; do /update.sh; sleep 600; done"]