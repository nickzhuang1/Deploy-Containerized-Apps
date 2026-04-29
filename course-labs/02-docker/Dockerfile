# ============================================================
# 課程範例 Dockerfile — Flask API
# 用法：
#   docker build -t myapp:v1 .
#   docker run -p 5000:5000 myapp:v1
# ============================================================

FROM python:3.10-slim

# 設定工作目錄
WORKDIR /app

# 安裝系統工具（slim image 預設不含 ps / curl 等）
RUN apt-get update && apt-get install -y --no-install-recommends \
        procps \
    && rm -rf /var/lib/apt/lists/*

# 先複製 requirements 並安裝（利用 Docker layer cache）
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 只複製應用程式原始碼（不含 compose / shell 等檔案）
COPY app.py .

# 宣告容器監聽的 Port
EXPOSE 5000

# 使用非 root 使用者（安全最佳實踐）
RUN useradd -m appuser
USER appuser

# 用 gunicorn 啟動（requirements.txt 已包含）
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
