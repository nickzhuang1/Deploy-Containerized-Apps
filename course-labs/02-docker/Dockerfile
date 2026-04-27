# ============================================================
# 課程範例 Dockerfile — Flask API
# 用法：
#   docker build -t myapp:v1 .
#   docker run -p 5000:5000 myapp:v1
# ============================================================

FROM python:3.10-slim

# 設定工作目錄
WORKDIR /app

# 先複製 requirements 並安裝（利用 Docker layer cache）
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 複製應用程式原始碼
COPY . .

# 宣告容器監聽的 Port
EXPOSE 5000

# 使用非 root 使用者（安全最佳實踐）
RUN useradd -m appuser
USER appuser

# 啟動指令
CMD ["python", "app.py"]
