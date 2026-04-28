"""
Flask API + PostgreSQL 版本
搭配 docker-compose.full.yml 使用

測試指令：
  curl http://localhost:5000/
  curl http://localhost:5000/api/items
  curl -X POST http://localhost:5000/api/items \
       -H 'Content-Type: application/json' \
       -d '{"name": "apple"}'
"""

from flask import Flask, jsonify, request
import os
import socket
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)
DATABASE_URL = os.environ.get("DATABASE_URL", "")


def get_db():
    return psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor)


def init_db():
    """啟動時建立 items table（若不存在）"""
    try:
        with get_db() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS items (
                        id   SERIAL PRIMARY KEY,
                        name TEXT NOT NULL,
                        created_at TIMESTAMP DEFAULT NOW()
                    )
                """)
            conn.commit()
        print("DB initialized.")
    except Exception as e:
        print(f"DB init error: {e}")


@app.route("/")
def index():
    return jsonify({
        "message": "Flask + PostgreSQL on Docker Compose",
        "hostname": socket.gethostname(),
        "env": os.environ.get("APP_ENV", "development"),
    })


@app.route("/health")
def health():
    try:
        with get_db() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
        return jsonify({"status": "ok", "db": "connected"}), 200
    except Exception as e:
        return jsonify({"status": "error", "db": str(e)}), 500


@app.route("/api/items", methods=["GET"])
def get_items():
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM items ORDER BY id")
            rows = cur.fetchall()
    return jsonify({"items": [dict(r) for r in rows], "count": len(rows)})


@app.route("/api/items", methods=["POST"])
def add_item():
    data = request.get_json(silent=True)
    if not data or "name" not in data:
        return jsonify({"error": "'name' is required"}), 400
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO items (name) VALUES (%s) RETURNING *",
                (data["name"],)
            )
            item = dict(cur.fetchone())
        conn.commit()
    return jsonify(item), 201


@app.route("/api/items/<int:item_id>", methods=["DELETE"])
def delete_item(item_id):
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM items WHERE id=%s RETURNING id", (item_id,))
            deleted = cur.fetchone()
        conn.commit()
    if not deleted:
        return jsonify({"error": "not found"}), 404
    return jsonify({"deleted": item_id})


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5000, debug=False)
