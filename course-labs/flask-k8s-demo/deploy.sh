#!/usr/bin/env bash
# ============================================================
# 一鍵部署 Flask API 到 Kubernetes
# ============================================================

set -euo pipefail

echo ">>> 套用 ConfigMap"
kubectl apply -f k8s/configmap.yaml

echo ">>> 套用 Deployment（3 replicas）"
kubectl apply -f k8s/deployment.yaml

echo ">>> 套用 Service（NodePort 30500）"
kubectl apply -f k8s/service.yaml

echo ""
echo ">>> 等待 Pods Ready..."
kubectl rollout status deployment/flask-demo --timeout=60s

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
