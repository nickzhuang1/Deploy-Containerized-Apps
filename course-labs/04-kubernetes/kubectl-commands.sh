#!/usr/bin/env bash
# ============================================================
# kubectl 指令速查 — 對應課程投影片 33-36、41、47
# ============================================================

# ════════════════════════════════════════
# 查詢資源
# ════════════════════════════════════════
kubectl get pods                           # 列出 default namespace 的 Pod
kubectl get pods -A                        # 所有 namespace
kubectl get pods -o wide                   # 顯示 Node IP 和所在節點
kubectl get all -n default                 # 所有資源類型
kubectl get nodes                          # 列出所有節點
kubectl get svc                            # Service 列表
kubectl get deploy                         # Deployment 列表
kubectl get pv,pvc                         # PersistentVolume
kubectl top pods                           # Pod CPU/記憶體使用量（需 Metrics Server）
kubectl top nodes                          # 節點資源使用量

# ════════════════════════════════════════
# describe — 除錯必備
# ════════════════════════════════════════
kubectl describe pod <pod-name>            # Pod 完整狀態（含 Events）
kubectl describe node <node-name>          # 節點資訊（含 GPU、分配狀況）
kubectl describe deploy web-app            # Deployment 狀態
kubectl describe svc nginx-svc             # Service 詳細

# 查看 GPU 節點資源
kubectl describe node | grep -A5 "nvidia.com/gpu"

# ════════════════════════════════════════
# logs — 查看容器 log
# ════════════════════════════════════════
kubectl logs <pod-name>                    # Pod log
kubectl logs -f <pod-name>                 # 即時追蹤
kubectl logs --tail=100 <pod-name>         # 最後 100 行
kubectl logs <pod-name> -c <container>     # 多容器 Pod 指定容器
kubectl logs <pod-name> --previous         # 已死亡的前一個容器（CrashLoopBackOff）
kubectl logs -l app=web --all-containers   # Label 匹配的所有 Pod
kubectl logs <pod-name> --since=1h         # 最近 1 小時

# ════════════════════════════════════════
# 操作資源
# ════════════════════════════════════════
kubectl apply -f manifest.yaml             # 套用設定（建立或更新）
kubectl delete -f manifest.yaml            # 刪除設定中的資源
kubectl delete pod <pod-name>              # 刪除 Pod（Deployment 會自動重建）
kubectl exec -it <pod-name> -- bash        # 進入容器（互動式 shell）
kubectl exec -it <pod-name> -- sh          # 若沒有 bash 用 sh
kubectl cp <pod-name>:/path ./local        # 從容器複製檔案
kubectl port-forward svc/web-app 8080:80   # 本機 8080 → Service 80

# ════════════════════════════════════════
# Deployment 操作
# ════════════════════════════════════════
kubectl scale deploy web-app --replicas=5         # 手動擴縮
kubectl set image deploy/web-app web=myapp:v2     # 更新 Image（觸發滾動更新）
kubectl rollout status deploy/web-app             # 監看更新進度
kubectl rollout history deploy/web-app            # 查看版本歷史
kubectl rollout undo deploy/web-app               # 回滾上一版
kubectl rollout undo deploy/web-app --to-revision=2  # 回滾到指定版本
kubectl rollout restart deploy/web-app            # 強制重啟所有 Pod

# ════════════════════════════════════════
# Namespace
# ════════════════════════════════════════
kubectl create namespace staging
kubectl get ns
kubectl get pods -n kube-system
kubectl config set-context --current --namespace=staging   # 切換預設 namespace

# ════════════════════════════════════════
# 常見問題排查
# ════════════════════════════════════════
kubectl get pods -A                                          # 確認所有 Pod 狀態
kubectl get events --sort-by=.lastTimestamp                 # 依時間排序事件
kubectl get events --field-selector reason=Failed           # 只看 Failed 事件
kubectl describe pod <pod-name> | grep -A20 Events          # 看 Pod 錯誤事件
kubectl logs <pod-name> --previous                          # CrashLoop 的 log
kubectl logs -n kube-system <kube-system-pod>               # 系統元件 log
