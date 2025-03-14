#!/bin/bash

# 명령어 실패 시 스크립트 종료
set -euo pipefail

# 로그 출력 함수
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# 에러 발생 시 로그와 함께 종료하는 함수
error() {
  log "Error on line $1"
  exit 1
}

trap 'error $LINENO' ERR

log "스크립트 실행 시작."

# docker network 생성
if docker network ls --format '{{.Name}}' | grep -q '^nansan-network$'; then
  log "Docker network named 'nansan-network' is already existed."
else
  log "Docker network named 'nansan-network' is creating..."
  docker network create --driver bridge nansan-network
fi

# 기존 minio 이미지를 삭제하고 새로 빌드
log "minio image remove and build."
docker rmi minio:latest || true
docker build -t minio:latest .

# Docker로 minio 서비스 실행
log "Execute minio..."
docker run -dt \
  --name minio \
  --restart unless-stopped \
  -e MINIO_ROOT_USER=${MINIO_ROOT_USER} \
  -e MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD} \
  -e MINIO_VOLUMES=/mnt/data \
  -e MINIO_OPTS="--console-address :9001" \
  -p 9000:9000 \
  -p 9001:9001 \
  -v /var/minio:/mnt/data \
  --network nansan-network \
  minio:latest server --console-address ":9001"

echo "작업이 완료되었습니다."
