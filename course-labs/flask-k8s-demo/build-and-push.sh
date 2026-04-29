#!/usr/bin/env bash
# ============================================================
# Build Docker image 並匯入 containerd（方案 A：control plane 本機跑）
#
# 使用方式：
#   ./build-and-push.sh                               # build + 匯入 containerd
#   REGISTRY=192.168.1.200/myproject ./build-and-push.sh  # build + 推到 Harbor
#
# 前提：已移除 control plane taint
#   kubectl taint nodes <node> node-role.kubernetes.io/control-plane:NoSchedule-
# ============================================================

set -euo pipefail

IMAGE_NAME="flask-demo"
TAG="v1"
REGISTRY="${REGISTRY:-}"

FULL_IMAGE="${IMAGE_NAME}:${TAG}"
if [ -n "${REGISTRY}" ]; then
    FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"
fi

echo ">>> Building image: ${FULL_IMAGE}"
docker build -t "${FULL_IMAGE}" .

if [ -n "${REGISTRY}" ]; then
    # ── 有 Registry：push 上去，K8s 從 registry pull ──────────────────────
    echo ">>> Pushing to registry..."
    docker push "${FULL_IMAGE}"
    echo ""
    echo "✅ Image pushed: ${FULL_IMAGE}"
    echo "   deployment.yaml 的 imagePullPolicy 請改為 IfNotPresent"
else
    # ── 無 Registry（方案 A）：匯入 containerd，imagePullPolicy: Never ────
    echo ""
    echo ">>> 匯入 containerd image store（K8s 使用 containerd，非 Docker）"
    docker save "${FULL_IMAGE}" | sudo ctr -n k8s.io images import -
    echo ""
    echo ">>> 確認 containerd 已有此 image："
    sudo ctr -n k8s.io images ls | grep "${IMAGE_NAME}" || true
    echo ""
    echo "✅ Image ready in containerd: ${FULL_IMAGE}"
    echo "   deployment.yaml 的 imagePullPolicy 應為 Never（已設定）"
fi
