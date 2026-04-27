#!/usr/bin/env bash
# ============================================================
# Build Docker image 並推到 Registry
# 使用方式：
#   ./build-and-push.sh                      # 用本機 Docker（kind / minikube）
#   REGISTRY=192.168.1.200/myproject ./build-and-push.sh  # 推到 Harbor
# ============================================================

set -euo pipefail

IMAGE_NAME="flask-demo"
TAG="v1"
REGISTRY="${REGISTRY:-}"   # 留空代表只 build 本機用

FULL_IMAGE="${IMAGE_NAME}:${TAG}"
if [ -n "${REGISTRY}" ]; then
    FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"
fi

echo ">>> Building image: ${FULL_IMAGE}"
docker build -t "${FULL_IMAGE}" .

if [ -n "${REGISTRY}" ]; then
    echo ">>> Pushing to registry..."
    docker push "${FULL_IMAGE}"
fi

echo ""
echo "✅ Image ready: ${FULL_IMAGE}"
echo ""
echo ">>> 記得更新 k8s/deployment.yaml 的 image 欄位："
echo "    image: ${FULL_IMAGE}"
