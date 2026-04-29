#!/usr/bin/env bash
# ============================================================
# 一鍵部署 Flask API 到 Kubernetes（方案 A：control plane 本機）
#
# 部署前請確認：
#   1. 已移除 control plane taint：
#      kubectl taint nodes <node> node-role.kubernetes.io/control-plane:NoSchedule-
#   2. 已執行 build-and-push.sh（image 已匯入 containerd）
# ============================================================

set -euo pipefail

# ── 確認 control plane taint 已移除 ────────────────────────────────────────
CP_NODE=$(kubectl get nodes --selector='node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}')
TAINT=$(kubectl get node "${CP_NODE}" -o jsonpath='{.spec.taints[?(@.key=="node-role.kubernetes.io/control-plane")].effect}')
if [ -n "${TAINT}" ]; then
    echo "❌ Control plane 還有 NoSchedule taint，Pod 無法排程！"
    echo "   請先執行："
    echo "   kubectl taint nodes ${CP_NODE} node-role.kubernetes.io/control-plane:NoSchedule-"
    exit 1
fi
echo "✅ Control plane taint 已移除，可以排程 Pod"
echo ""

echo ">>> 套用 ConfigMap"
kubectl apply -f k8s/configmap.yaml

echo ">>> 套用 Deployment（3 replicas）"
kubectl apply -f k8s/deployment.yaml

echo ">>> 套用 Service（NodePort 30500）"
kubectl apply -f k8s/service.yaml

echo ""
echo ">>> 等待 Pods Ready..."
kubectl rollout status deployment/flask-demo --timeout=120s

echo ""
echo "✅ 部署完成！"
echo ""
echo "=== Pod 狀態 ==="
kubectl get pods -l app=flask-demo -o wide

echo ""
echo "=== Service ==="
kubectl get svc flask-demo-svc

echo ""
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "=== 測試指令 ==="
echo "  curl http://${NODE_IP}:30500/"
echo "  curl http://${NODE_IP}:30500/api/info"
echo "  curl http://${NODE_IP}:30500/api/items"
echo "  curl -X POST http://${NODE_IP}:30500/api/items -H 'Content-Type: application/json' -d '{\"name\":\"apple\"}'"
echo ""
echo "  # 多跑幾次，觀察 pod_name 在不同 replica 之間切換："
echo "  for i in \$(seq 1 6); do curl -s http://${NODE_IP}:30500/api/info | python3 -m json.tool | grep pod_name; done"
