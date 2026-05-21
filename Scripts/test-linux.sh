#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

COMPOSE_FILE="docker-compose.yml"
BUILD_PATH=".build-linux"
NETWORK_NAME="s3client_test_network"

cleanup() {
    echo "==> Stopping MinIO..."
    docker compose -f "$COMPOSE_FILE" down -v
    rm -rf "$BUILD_PATH"
}

trap cleanup EXIT

rm -rf "$BUILD_PATH"

echo "==> Starting MinIO..."
docker compose -f "$COMPOSE_FILE" up -d --wait minio

echo "==> Running Swift tests on Linux Swift 6.0 container..."
docker run --rm \
    --network "$NETWORK_NAME" \
    -v "$PWD":/pkg \
    -w /pkg \
    -e S3_ENDPOINT=http://minio:9000 \
    "swift:6.0" \
    swift test --build-path "$BUILD_PATH" "$@"

rm -rf "$BUILD_PATH"

echo "==> Running Swift tests on Linux Swift 6.3 container..."
docker run --rm \
    --network "$NETWORK_NAME" \
    -v "$PWD":/pkg \
    -w /pkg \
    -e S3_ENDPOINT=http://minio:9000 \
    "swift:6.3" \
    swift test --build-path "$BUILD_PATH" "$@"
