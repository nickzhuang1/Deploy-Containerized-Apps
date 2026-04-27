#!/usr/bin/env bash
# ============================================================
# kube-prometheus-stack 安裝（Prometheus + Grafana + AlertManager）
# ============================================================

set -euo pipefail

echo ">>> 加入 prometheus-community Helm repo"
helm repo add prometheus-community \
    https://prometheus-community.github.io/helm-charts
helm repo update

echo ">>> 安裝 kube-prometheus-stack"
helm install kube-prom-stack \
    prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --set grafana.adminPassword=admin123

echo ">>> 等待啟動"
kubectl wait --for=condition=available deploy/kube-prom-stack-grafana \
    -n monitoring --timeout=180s

echo ""
echo "✅ 安裝完成！"
echo ""
echo "=== Grafana ==="
echo "   kubectl port-forward svc/kube-prom-stack-grafana 3000:80 -n monitoring"
echo "   瀏覽器開啟 http://localhost:3000"
echo "   帳號: admin  密碼: admin123"
echo ""
echo "=== Prometheus ==="
echo "   kubectl port-forward svc/kube-prom-stack-kube-prome-prometheus 9090:9090 -n monitoring"
echo "   瀏覽器開啟 http://localhost:9090"
echo ""
echo "=== 查看所有元件 ==="
echo "   kubectl get pods -n monitoring"
