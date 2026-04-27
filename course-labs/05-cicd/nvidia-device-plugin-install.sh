#!/usr/bin/env bash
# ============================================================
# NVIDIA Device Plugin for Kubernetes 安裝
# 前提：每個 GPU 節點已安裝 Driver + NVIDIA Container Toolkit
# ============================================================

set -euo pipefail

echo ">>> 加入 NVIDIA Device Plugin Helm repo"
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update

echo ">>> 安裝 nvidia-device-plugin（DaemonSet）"
helm install nvdp nvdp/nvidia-device-plugin \
    --namespace kube-system \
    --set failOnInitError=false

echo ">>> 確認 DaemonSet 是否在所有 GPU 節點正常運行"
kubectl get pods -n kube-system -l app.kubernetes.io/name=nvidia-device-plugin

echo ""
echo ">>> 確認節點有 GPU 資源（nvidia.com/gpu 欄位）"
kubectl describe nodes | grep -A5 "nvidia.com/gpu"

echo ""
echo ">>> 測試：跑一個 GPU Pod"
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: gpu-test
spec:
  containers:
  - name: cuda
    image: nvidia/cuda:12.2.0-base-ubuntu22.04
    command: ["nvidia-smi"]
    resources:
      limits:
        nvidia.com/gpu: 1
  restartPolicy: Never
EOF

echo ""
echo "   等待 GPU Pod 完成..."
kubectl wait pod/gpu-test --for=condition=Succeeded --timeout=60s
kubectl logs gpu-test
kubectl delete pod gpu-test
