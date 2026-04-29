# Docker 容器化實作 — Demo 操作手冊

環境：任一安裝有 Docker 的 Linux 主機（需 Docker Engine + docker compose v2）

> ⚠️ 必須使用 `docker compose`（空格，v2 plugin），**不是** `docker-compose`（連字號，v1）。

---

## 檔案結構

```
02-docker/
│
│  ── 簡單版（Flask only）──────────────────────────
├── app.py                  # Flask API（hostname / health）
├── Dockerfile              # 基本 Dockerfile
├── requirements.txt        # flask + gunicorn
├── docker-compose.yml      # 單服務，馬上能跑
│
│  ── 完整版（Flask + PostgreSQL）──────────────────
├── app-with-db.py          # Flask CRUD API，實際連線 DB
├── Dockerfile.full         # 含 psycopg2 的 Dockerfile
├── requirements.full.txt   # flask + gunicorn + psycopg2
├── docker-compose.full.yml # Flask + PostgreSQL（含 healthcheck）
│
└── docker-commands.sh      # 常用指令速查（對應投影片）
```

---

## Demo A：簡單版（Flask only）

適合說明「Dockerfile 如何撰寫」和「容器的無狀態特性」。

### Step 1：Build Image

```bash
cd course-labs/02-docker
docker build -t myapp:v1 .
```

### Step 2：Run 容器

```bash
docker run -d -p 5000:5000 --name myapp myapp:v1
```

### Step 3：測試 API

```bash
curl http://localhost:5000/
curl http://localhost:5000/health
```

預期輸出：
```json
{"env": "development", "hostname": "a3f9d2c1e4b7", "message": "Hello from Container!"}
```

> **展示重點**：`hostname` 是容器 ID。重建容器後 hostname 會變，說明容器的**無狀態**特性。

### Step 4：展示 Log / 進入容器

```bash
# 查看 log
docker logs myapp
docker logs -f myapp            # 即時追蹤

# 進入容器
docker exec -it myapp bash
whoami                          # 應顯示 appuser（非 root）
ps aux                          # 看到 gunicorn worker
exit
```

### Step 5：展示 docker compose（單服務）

```bash
# 先清掉剛才的容器
docker stop myapp && docker rm myapp

# 用 compose 啟動
docker compose up -d
docker compose ps
curl http://localhost:5000/

# 停止
docker compose down
```

---

## Demo B：完整版（Flask + PostgreSQL）

適合說明「多容器協作」、`depends_on` healthcheck、以及 **Volume 資料持久化**。

### Step 1：Build 完整版 Image

```bash
docker build -f Dockerfile.full -t myapp-full:v1 .
```

### Step 2：啟動 Flask + PostgreSQL

```bash
docker compose -f docker-compose.full.yml up -d
```

觀察啟動順序（DB healthcheck 通過後，web 才啟動）：
```bash
docker compose -f docker-compose.full.yml ps
docker compose -f docker-compose.full.yml logs -f
```

預期狀態（約 15 秒後）：
```
NAME        STATUS
02-docker-db-1    running (healthy)
02-docker-web-1   running
```

### Step 3：測試 CRUD API

```bash
# 健康檢查（含 DB 連線確認）
curl http://localhost:5000/health
# → {"db": "connected", "status": "ok"}

# 新增 items
curl -X POST http://localhost:5000/api/items \
     -H 'Content-Type: application/json' \
     -d '{"name": "apple"}'

curl -X POST http://localhost:5000/api/items \
     -H 'Content-Type: application/json' \
     -d '{"name": "banana"}'

# 列出 items
curl http://localhost:5000/api/items

# 刪除 item（替換 {id} 為實際 id）
curl -X DELETE http://localhost:5000/api/items/1

# 確認刪除
curl http://localhost:5000/api/items
```

### Step 4：展示 Volume 資料持久化

重啟服務後，資料仍然存在（因為 DB 資料放在 named volume `pgdata`）：

```bash
# 重啟服務（不刪 Volume）
docker compose -f docker-compose.full.yml restart

# 確認資料還在
curl http://localhost:5000/api/items
```

> **展示重點**：對比 flask-k8s-demo 的 `/api/items`（存在記憶體，重啟就消失），說明 Volume 如何解決資料持久化問題。

### Step 5：清理

```bash
# down 但保留 Volume（資料留著）
docker compose -f docker-compose.full.yml down

# down 並刪除 Volume（完全清除）
docker compose -f docker-compose.full.yml down -v
```

---

## Part 3：常用指令 Demo（docker-commands.sh）

依序貼入終端機執行，對應投影片說明：

```bash
# inspect：查容器 IP
docker run -d --name test-nginx nginx
docker inspect -f '{{.NetworkSettings.IPAddress}}' test-nginx
docker inspect -f '{{json .Config.Env}}' test-nginx | python3 -m json.tool

# logs：即時追蹤
docker logs -f test-nginx

# stats：資源使用（一次性輸出）
docker stats --no-stream

# 設定資源限制
docker run -d --memory='256m' --cpus='0.5' --name limited nginx
docker stats --no-stream limited

# volume：資料持久化
docker volume create mydata
docker volume inspect mydata

# 清理
docker stop test-nginx limited && docker rm test-nginx limited
docker volume rm mydata
```

---

## 注意事項

- `docker-compose.full.yml` 用 `depends_on: condition: service_healthy`，Web 容器會等 PostgreSQL healthcheck 通過才啟動，避免連線失敗。
- `app-with-db.py` 啟動時會自動 `CREATE TABLE IF NOT EXISTS items`，不需要手動建 schema。
- `Dockerfile` 使用 `USER appuser`（非 root），是容器安全的最佳實踐，上課時可特別說明。
- 如果 `docker compose up` 後 web 一直 restart，用 `docker compose logs web` 查原因（通常是 DB 還沒 ready）。
