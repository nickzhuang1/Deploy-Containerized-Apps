# Flask API on Kubernetes — Demo 操作手冊

環境：1 control plane + 1 worker node，image 在 control plane 本機（containerd）

---

## 檔案結構

```
flask-k8s-demo/
├── app.py                  # Flask API 主程式
├── Dockerfile              # Container image 定義
├── requirements.txt        # Python 套件
├── build-and-push.sh       # Build + 匯入 containerd
├── deploy.sh               # 一鍵部署到 K8s
└── k8s/
    ├── configmap.yaml      # 環境變數設定
    ├── deployment.yaml     # 3 個 replica，含 Probe / Resource Limit
    └── service.yaml        # NodePort 30500
```

---

## 事前準備（上課前做一次）

### 1. 移除 control plane taint

```bash
kubectl taint nodes controlplane node-role.kubernetes.io/control-plane:NoSchedule-

# 確認移除成功（應顯示 Taints: <none>）
kubectl describe node controlplane | grep Taints
```

### 2. Build image 並匯入 containerd

```bash
cd course-labs/flask-k8s-demo
chmod +x build-and-push.sh deploy.sh

./build-and-push.sh
```

> **為什麼要匯入 containerd？**
> K8s 使用 containerd 當 container runtime，跟 Docker 是獨立的 image store。
> `docker build` 的 image 不會自動出現在 containerd，需要手動匯入。

### 3. 部署到 K8s

```bash
./deploy.sh
```

輸出範例：
```
✅ Control plane taint 已移除，可以排程 Pod
>>> 套用 ConfigMap
>>> 套用 Deployment（3 replicas）
>>> 套用 Service（NodePort 30500）
>>> 等待 Pods Ready...
✅ 部署完成！
```

---

## Demo 流程

### Step 1：確認 Pod 都在跑

```bash
kubectl get pods -l app=flask-demo -o wide
```

預期結果（3 個 Pod 全在 controlplane）：
```
NAME                         READY   STATUS    NODE           
flask-demo-xxx-aaa           1/1     Running   controlplane   
flask-demo-xxx-bbb           1/1     Running   controlplane   
flask-demo-xxx-ccc           1/1     Running   controlplane   
```

### Step 2：設定 NODE_IP

```bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo $NODE_IP
```

### Step 3：打 API

```bash
# 首頁
curl http://${NODE_IP}:30500/

# Pod 資訊（展示 Downward API + ConfigMap 注入）
curl http://${NODE_IP}:30500/api/info

# 新增 item
curl -X POST http://${NODE_IP}:30500/api/items \
     -H 'Content-Type: application/json' \
     -d '{"name": "apple"}'

# 列出 items
curl http://${NODE_IP}:30500/api/items
```

### Step 4：展示負載均衡（重點 Demo）

連打 6 次，觀察 `pod_name` 在 3 個 replica 之間切換：

```bash
for i in $(seq 1 6); do
  curl -s http://${NODE_IP}:30500/api/info | python3 -m json.tool | grep pod_name
done
```

預期輸出（每次可能不同）：
```
    "pod_name": "flask-demo-87fd59b5c-aaa",
    "pod_name": "flask-demo-87fd59b5c-bbb",
    "pod_name": "flask-demo-87fd59b5c-ccc",
    "pod_name": "flask-demo-87fd59b5c-aaa",
    ...
```

### Step 5：展示 Liveness / Readiness Probe

```bash
# 直接打 probe endpoint
curl http://${NODE_IP}:30500/health/live
curl http://${NODE_IP}:30500/health/ready

# 查看 K8s 偵測到的 probe 狀態
kubectl describe pod -l app=flask-demo | grep -A5 "Liveness\|Readiness"
```

### Step 6：展示 ConfigMap 熱更新

修改訊息後 rolling restart：

```bash
kubectl edit configmap flask-demo-config
# 把 APP_MESSAGE 改成任意文字，存檔離開

kubectl rollout restart deployment/flask-demo
kubectl rollout status deployment/flask-demo

curl http://${NODE_IP}:30500/api/info | python3 -m json.tool | grep message
```

### Step 7：展示 Scaling

```bash
# 擴展到 5 個 replica
kubectl scale deployment flask-demo --replicas=5
kubectl get pods -l app=flask-demo

# 縮回 3 個
kubectl scale deployment flask-demo --replicas=3
```

---

## 注意事項

- `/api/items` 的資料存在 Pod 記憶體，**不跨 replica 共享**。
  POST 到 Pod A，下一個 GET 打到 Pod B 會看不到剛新增的資料。
  → 這是刻意展示「無狀態服務」的概念，上課時說明清楚即可。

---

## 清理

```bash
# 移除所有 K8s 資源
kubectl delete -f k8s/

# 還原 control plane taint
kubectl taint nodes controlplane node-role.kubernetes.io/control-plane:NoSchedule

# 移除 containerd image（選用）
sudo ctr -n k8s.io images rm docker.io/library/flask-demo:v1
```
