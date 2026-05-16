#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

COMPOSE_FILE="docker-compose.yml"
SWIFT_IMAGE="swift:6.1"
BUILD_PATH=".build-linux"
NETWORK_NAME="s3client_test_network"

cleanup() {
    echo "==> Stopping MinIO..."
    docker compose -f "$COMPOSE_FILE" down -v
}

trap cleanup EXIT

echo "==> Starting MinIO..."
docker compose -f "$COMPOSE_FILE" up -d --wait minio

echo "==> Running Swift tests on Linux container..."
docker run --rm \
    --network "$NETWORK_NAME" \
    -v "$PWD":/pkg \
    -w /pkg \
    -e S3_ENDPOINT=http://minio:9000 \
    "$SWIFT_IMAGE" \
    swift test --build-path "$BUILD_PATH" "$@"
