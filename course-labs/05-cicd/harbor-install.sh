#!/usr/bin/env bash
# ============================================================
# Harbor 私有 Registry 安裝（Helm）
# 調整 HARBOR_IP 為你的環境 IP
# ============================================================

set -euo pipefail

HARBOR_IP="192.168.1.200"    # ← 改成你的 Harbor 節點 IP

echo ">>> 加入 Harbor Helm repo"
helm repo add harbor https://helm.goharbor.io
helm repo update

echo ">>> 安裝 Harbor"
helm install harbor harbor/harbor \
    --namespace harbor \
    --create-namespace \
    --set expose.type=nodePort \
    --set expose.tls.enabled=false \
    --set externalURL="http://${HARBOR_IP}" \
    --set harborAdminPassword=Harbor12345

echo ">>> 等待 Harbor 啟動"
kubectl wait --for=condition=available deploy/harbor-core \
    -n harbor --timeout=180s

echo ""
echo "✅ Harbor 安裝完成！"
echo "   Web UI: http://${HARBOR_IP}"
echo "   帳號: admin  密碼: Harbor12345"
echo ""
echo ">>> 設定 Docker 允許 HTTP Registry（insecure）"
echo '    在 /etc/docker/daemon.json 加入：'
echo "    { \"insecure-registries\": [\"${HARBOR_IP}\"] }"
echo "    sudo systemctl restart docker"
echo ""
echo ">>> 登入並推送 Image"
echo "    docker login ${HARBOR_IP} -u admin -p Harbor12345"
echo "    docker tag myapp:v1 ${HARBOR_IP}/myproject/myapp:v1"
echo "    docker push ${HARBOR_IP}/myproject/myapp:v1"
echo ""
echo ">>> 漏洞掃描（需安裝 Trivy）"
echo "    trivy image ${HARBOR_IP}/myproject/myapp:v1"
