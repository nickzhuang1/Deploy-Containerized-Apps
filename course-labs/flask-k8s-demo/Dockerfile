FROM python:3.11-slim

WORKDIR /app

# 先複製 requirements 讓 Docker cache layer 生效
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

# 用 python 直接跑（demo 用途，production 建議換 gunicorn）
CMD ["python", "app.py"]
