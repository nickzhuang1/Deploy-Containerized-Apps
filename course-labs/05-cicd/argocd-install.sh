#!/usr/bin/env bash
# ============================================================
# ArgoCD 安裝與初始設定
# ============================================================

set -euo pipefail

echo ">>> 建立 argocd namespace 並安裝"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f \
    https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo ">>> 等待 ArgoCD 啟動"
kubectl wait --for=condition=available deploy/argocd-server \
    -n argocd --timeout=120s

echo ">>> 取得初始 admin 密碼"
kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath='{.data.password}' | base64 -d
echo ""

echo ">>> Port-forward（瀏覽器開啟 https://localhost:8080）"
echo "    kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "    帳號: admin"
echo "    密碼: 上面輸出的字串"
