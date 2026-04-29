# Docker 容器化實作 — Demo 操作手冊

環境：任一安裝有 Docker 的 Linux 主機（需 Docker Engine + docker compose v2）

---

## 檔案結構

```
02-docker/
├── app.py                  # 簡單 Flask API（無 DB）
├── Dockerfile              # 基本 Dockerfile
├── requirements.txt        # flask + gunicorn
├── docker-commands.sh      # 常用指令速查
├── docker-compose.yml      # 單服務（Flask only）
│
├── app-with-db.py          # Flask + PostgreSQL 版 API
├── Dockerfile.full         # 完整版 Dockerfile
├── requirements.full.txt   # flask + gunicorn + psycopg2
└── docker-compose.full.yml # Flask + PostgreSQL（進階）
```

---

## Part 1：基本 Build & Run

### 1. Build Image

```bash
cd course-labs/02-docker
docker build -t myapp:v1 .
```

預期輸出：
```
Successfully built xxxxxxxx
Successfully tagged myapp:v1
```

### 2. 確認 Image

```bash
docker images | grep myapp
```

### 3. Run 容器

```bash
docker run -d -p 5000:5000 --name myapp-container myapp:v1
```

### 4. 測試 API

```bash
curl http://localhost:5000/
curl http://localhost:5000/health
```

預期輸出：
```json
{"env": "development", "hostname": "xxxxxxxx", "message": "Hello from Container!"}
```

> **展示重點**：`hostname` 就是容器 ID，重啟後會變—說明容器的「無狀態」特性。

### 5. 查看 Log / Stats

```bash
docker logs myapp-container
docker stats --no-stream
```

### 6. 進入容器

```bash
docker exec -it myapp-container bash
# 在容器內
whoami          # appuser（非 root）
ps aux
exit
```

### 7. 停止並清除

```bash
docker stop myapp-container
docker rm myapp-container
```

---

## Part 2：docker compose（單服務）

# v2 plugin: 用官方腳本安裝最新版

```bash
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
```

```bash
# 啟動
docker compose up -d

# 測試
curl http://localhost:5000/

# 查看 log
docker compose logs -f

# 停止
docker compose down
```

---

## Part 3：docker compose 完整版（Flask + PostgreSQL）

> **注意**：必須使用 `docker compose`（v2），不是 `docker-compose`（v1）

```bash
# 啟動（含 PostgreSQL，healthcheck 通過後才啟動 web）
docker compose -f docker-compose.full.yml up -d

# 查看啟動狀態
docker compose -f docker-compose.full.yml ps

# 等 web 狀態變成 running（約 15 秒）
watch docker compose -f docker-compose.full.yml ps
```

### 測試 API（含 DB）

```bash
# 新增 item
curl -X POST http://localhost:5000/api/items \
     -H 'Content-Type: application/json' \
     -d '{"name": "apple"}'

# 列出 items
curl http://localhost:5000/api/items

# 健康檢查（會 ping DB）
curl http://localhost:5000/health
```

### 清理

```bash
docker compose -f docker-compose.full.yml down -v   # -v 同時刪除 Volume
```

---

## Part 4：常用指令 Demo（docker-commands.sh）

依序貼入終端機執行，對應投影片說明：

```bash
# inspect：查容器 IP
docker run -d --name test-nginx nginx
docker inspect -f '{{.NetworkSettings.IPAddress}}' test-nginx

# logs：即時追蹤
docker logs -f test-nginx

# stats：資源使用
docker stats --no-stream

# volume：資料持久化
docker volume create mydata
docker run -d -v mydata:/usr/share/nginx/html nginx
docker volume inspect mydata

# 清理
docker stop test-nginx && docker rm test-nginx
docker volume rm mydata
```

---

## 注意事項

- 使用 `docker compose`（空格）而非 `docker-compose`（連字號），避免 v1 的已知 bug。
- `Dockerfile` 中使用 `USER appuser`（非 root），上課時說明安全最佳實踐。
- `app-with-db.py` 的資料存在 PostgreSQL，重啟服務後資料保留（示範 Volume 的作用）。
