# Kubernetes 實作 — Demo 操作手冊

環境：1 control plane + 1 worker node，control plane taint 已移除

---

## 檔案結構

```
04-kubernetes/
├── kubectl-commands.sh     # kubectl 常用指令速查
├── nginx-deploy.yaml       # Nginx Deployment + NodePort Service（基本示範）
├── deployment.yaml         # 完整 Deployment 範本（含 Probe、Resource Limit）
├── service.yaml            # ClusterIP + NodePort 範例
├── hpa.yaml                # HorizontalPodAutoscaler（自動擴縮容）
├── gpu-pod.yaml            # GPU Pod（申請 nvidia.com/gpu）
├── metallb-config.yaml     # MetalLB LoadBalancer（進階）
├── ingress.yaml            # Ingress 路由規則（進階）
└── dist-train-job.yaml     # 分散式訓練 Job（進階）
```

---

## 事前準備（上課前做一次）

### 安裝 Metrics Server

`kubectl top` 需要 Metrics Server。kubeadm 環境的 kubelet 使用自簽憑證，需要加 `--kubelet-insecure-tls`：

```bash
# 安裝
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# kubeadm 環境必須加這個 patch，否則 Metrics Server 會一直 CrashLoop
kubectl patch deployment metrics-server -n kube-system \
  --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# 等待就緒（約 30 秒）
kubectl rollout status deployment/metrics-server -n kube-system

# 確認可用
kubectl top nodes
kubectl top pods -A
```

---

## 事前確認

```bash
# 確認節點狀態
kubectl get nodes

# 確認 control plane taint 已移除（Pod 才能排程到 control plane）
kubectl describe node controlplane | grep Taints
# 若有 NoSchedule，執行：
kubectl taint nodes controlplane node-role.kubernetes.io/control-plane:NoSchedule-
```

---

## Part 1：基本 Deployment — Nginx

### 部署

```bash
kubectl apply -f nginx-deploy.yaml
```

### 確認 Pod 狀態

```bash
kubectl get pods -l app=nginx -o wide
kubectl get svc nginx-svc
```

### 存取 Nginx

```bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
curl http://${NODE_IP}:30088
```

### 展示 Rolling Update

```bash
# 更新 Image 版本
kubectl set image deployment/nginx nginx=nginx:1.26

# 監看滾動更新進度
kubectl rollout status deployment/nginx

# 查看版本歷史
kubectl rollout history deployment/nginx

# 回滾上一版
kubectl rollout undo deployment/nginx
```

### 展示 Scale

```bash
kubectl scale deployment/nginx --replicas=5
kubectl get pods -l app=nginx
kubectl scale deployment/nginx --replicas=2
```

### 清除

```bash
kubectl delete -f nginx-deploy.yaml
```

---

## Part 2：完整 Deployment 範本

> 使用 `nginx:1.25` 作為示範 image，不需要自建 image 即可直接跑。

### 套用

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl rollout status deployment/web-app
```

### 確認 Pod 狀態

```bash
kubectl get pods -l app=web -o wide
```

預期三個 Pod 都 Running（readinessProbe 通過後才 READY 1/1）：
```
NAME                       READY   STATUS    NODE
web-app-xxx-aaa            1/1     Running   controlplane
web-app-xxx-bbb            1/1     Running   controlplane
web-app-xxx-ccc            1/1     Running   controlplane
```

### 展示 Probe 設定

```bash
kubectl describe pod -l app=web | grep -A5 "Liveness\|Readiness"
```

> `deployment.yaml` 展示的功能：
> - `rollingUpdate.maxUnavailable: 0`（零停機更新）
> - Readiness / Liveness Probe（探測 `GET /` port 80）
> - Resource requests & limits

### 存取（NodePort 30080）

```bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
curl http://${NODE_IP}:30080
```

---

## Part 3：kubectl 常用指令 Demo

對應 `kubectl-commands.sh`，逐段說明：

```bash
# ── 查詢資源 ──────────────────────────────────
kubectl get all -n default
kubectl get pods -o wide
kubectl top pods                    # 需 Metrics Server

# ── describe 除錯 ─────────────────────────────
kubectl describe pod <pod-name>     # 查 Events（最重要）
kubectl describe node               # 查節點資源分配

# ── logs ──────────────────────────────────────
kubectl logs -f <pod-name>
kubectl logs <pod-name> --previous  # CrashLoopBackOff 時查前一次

# ── exec 進入容器 ──────────────────────────────
kubectl exec -it <pod-name> -- bash

# ── port-forward（不用 NodePort 的快速測試）──────
kubectl port-forward svc/web-app-clusterip 8080:80
curl http://localhost:8080/
```

---

## Part 4：HPA 自動擴縮容（進階）

> 前提：需安裝 Metrics Server

```bash
# 安裝 Metrics Server（一次性）
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 套用 HPA
kubectl apply -f hpa.yaml

# 查看 HPA 狀態
kubectl get hpa
kubectl describe hpa web-app-hpa
```

### 壓力測試觀察自動擴容

```bash
# 終端機 A：監看 HPA 副本數變化
kubectl get hpa -w
```

開另一個終端機（終端機 B）產生負載，用 Deployment 並發 10 個 worker 同時打：

```bash
# 啟動 10 個 worker 並發打 ClusterIP
kubectl create deployment load-test \
  --image=busybox \
  --replicas=10 \
  -- /bin/sh -c "while true; do wget -q -O /dev/null http://web-app-clusterip/; done"

# 確認 load-test pod 都在跑
kubectl get pods -l app=load-test
```

約 30–60 秒後（HPA 預設每 15 秒評估一次），終端機 A 應看到 REPLICAS 數字上升：
```
NAME           REFERENCE             TARGETS        MINPODS   MAXPODS   REPLICAS
web-app-hpa    Deployment/web-app    8%/50%         2         10        2
web-app-hpa    Deployment/web-app    63%/50%        2         10        2
web-app-hpa    Deployment/web-app    63%/50%        2         10        4     ← 擴容
web-app-hpa    Deployment/web-app    41%/50%        2         10        4
```

如果 CPU 仍然不夠高，可以再加 replica 數：
```bash
kubectl scale deployment load-test --replicas=20
```

### 結束壓測

```bash
# 刪除 load-test，HPA 會在 5 分鐘冷卻後縮回 minReplicas
kubectl delete deployment load-test

# 監看縮容（需等 5 分鐘，HPA scaleDown 預設 stabilizationWindowSeconds: 300）
kubectl get hpa -w
```

---

## Part 5：GPU Pod（進階，需 GPU 節點）

> 前提：節點已安裝 NVIDIA Driver + Container Toolkit，且 `nvidia-device-plugin` DaemonSet 運行中

```bash
# 確認 GPU 節點資源
kubectl describe node | grep -A5 "nvidia.com/gpu"

# 提交 GPU Pod
kubectl apply -f gpu-pod.yaml

# 查看執行結果（nvidia-smi 輸出）
kubectl logs gpu-job

# 清除
kubectl delete pod gpu-job
```

---

## 常見問題排查

| 現象 | 指令 | 說明 |
|---|---|---|
| Pod 卡在 Pending | `kubectl describe pod <name>` | 看 Events，通常是資源不足或無法排程 |
| Pod CrashLoopBackOff | `kubectl logs <name> --previous` | 看前一次 crash 的 log |
| ErrImageNeverPull | `kubectl describe pod <name>` | imagePullPolicy:Never 但 Image 不在 containerd |
| ErrImagePull | `kubectl describe pod <name>` | 無法從 registry pull，檢查網路 / 認證 |
| Pod 無法被排程到 control plane | `kubectl describe node controlplane` | 確認 taint 是否移除 |

---

## 清理全部資源

```bash
kubectl delete -f .
```
