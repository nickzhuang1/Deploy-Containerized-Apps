#!/usr/bin/env bash
# ============================================================
# Docker 指令速查 — 課程對應投影片 16-19、26
# 直接貼到終端機逐行執行
# ============================================================

# ════════════════════════════════════════
# 基本執行
# ════════════════════════════════════════
docker run nginx                         # 前台執行 nginx
docker run -d -p 8080:80 nginx           # 背景執行，本機 8080 → 容器 80
docker run -it ubuntu bash               # 互動式進入 Ubuntu

docker ps                                # 看執行中的容器
docker ps -a                             # 看所有容器（含已停止）
docker stop <container_id>               # 停止容器
docker rm <container_id>                 # 刪除容器

docker images                            # 列出本機 Image
docker pull python:3.10                  # 拉取 Image
docker rmi <image>                       # 刪除 Image

# ════════════════════════════════════════
# docker inspect
# ════════════════════════════════════════
docker inspect <container_id>                                 # 完整 JSON
docker inspect -f '{{.NetworkSettings.IPAddress}}' nginx      # 取 IP
docker inspect -f '{{json .Mounts}}' nginx | jq .             # 取 Volume
docker inspect -f '{{json .Config.Env}}' nginx | jq .         # 取環境變數
docker image inspect --format='{{json .RootFS.Layers}}' nginx # Image Layer
docker inspect -f '{{.State.Pid}}' nginx                      # 取 PID

# ════════════════════════════════════════
# docker logs
# ════════════════════════════════════════
docker logs <container_id>                         # 所有 log
docker logs -f nginx                               # 即時追蹤（tail -f）
docker logs --tail 50 nginx                        # 最後 50 行
docker logs -t nginx                               # 加時間戳
docker logs --since 1h nginx                       # 最近 1 小時
docker logs --since 2024-01-01T00:00:00 nginx      # 指定時間後
docker logs nginx 2>&1 | grep ERROR                # 過濾 ERROR

# ════════════════════════════════════════
# docker stats
# ════════════════════════════════════════
docker stats                                                     # 即時所有容器
docker stats nginx                                               # 只看 nginx
docker stats --no-stream                                         # 輸出一次後結束
docker stats --format '{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}'   # 自訂格式

# 設定資源限制
docker run -d --memory='512m' --cpus='1.5' myapp:v1
docker update --memory='512m' --cpus='1.5' nginx

# ════════════════════════════════════════
# Docker Volume
# ════════════════════════════════════════
docker volume create mydata
docker volume ls
docker volume inspect mydata
docker volume prune                                              # 刪除未使用的

# Named Volume 掛載
docker run -v mydata:/app/data nginx

# Bind Mount（開發用）
docker run -v "$(pwd)":/app nginx

# 備份 Volume
docker run --rm \
    -v mydata:/data \
    -v "$(pwd)":/backup \
    busybox \
    tar cvf /backup/backup.tar /data

# ════════════════════════════════════════
# Build & Push
# ════════════════════════════════════════
docker build -t myapp:v1 .
docker run -p 5000:5000 myapp:v1

# Push to Docker Hub（先 docker login）
docker tag myapp:v1 <dockerhub-user>/myapp:v1
docker push <dockerhub-user>/myapp:v1

# Push to Harbor（私有）
docker tag myapp:v1 192.168.1.200/myproject/myapp:v1
docker push 192.168.1.200/myproject/myapp:v1
