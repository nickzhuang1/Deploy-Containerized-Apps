#!/usr/bin/env python3
"""
Flask API Demo — K8s 實戰範例
展示：Pod 資訊、ConfigMap 注入、負載均衡、Liveness/Readiness Probe
"""

from flask import Flask, jsonify, request
import os
import socket
import datetime

app = Flask(__name__)

# ── 從 ConfigMap / env var 注入 ────────────────────────────────────────────
APP_MESSAGE = os.environ.get("APP_MESSAGE", "Hello from Flask on Kubernetes!")
APP_VERSION = os.environ.get("APP_VERSION", "v1")

# ── 從 Downward API 注入 Pod 資訊 ──────────────────────────────────────────
POD_NAME      = os.environ.get("POD_NAME",      socket.gethostname())
POD_NAMESPACE = os.environ.get("POD_NAMESPACE", "default")
NODE_NAME     = os.environ.get("NODE_NAME",     "unknown")

# ── 簡單的 in-memory store（示範無狀態 API）───────────────────────────────
items: list[dict] = []


# ── Health endpoints（給 Liveness / Readiness Probe 用）────────────────────
@app.route("/health/live")
def liveness():
    """Liveness Probe：只要 process 活著就回 200"""
    return jsonify({"status": "alive"}), 200


@app.route("/health/ready")
def readiness():
    """Readiness Probe：可以加業務邏輯（例如 DB 連線檢查）"""
    return jsonify({"status": "ready"}), 200


# ── API endpoints ───────────────────────────────────────────────────────────
@app.route("/")
def index():
    return jsonify({
        "message": APP_MESSAGE,
        "version": APP_VERSION,
        "pod":     POD_NAME,
        "hint":    "Try GET /api/info or GET /api/items",
    })


@app.route("/api/info")
def info():
    """
    回傳 Pod 本身的資訊。
    多次呼叫時可以看到 pod_name 在不同 replica 之間切換 → 展示 K8s 負載均衡。
    """
    return jsonify({
        "pod_name":      POD_NAME,
        "namespace":     POD_NAMESPACE,
        "node":          NODE_NAME,
        "version":       APP_VERSION,
        "message":       APP_MESSAGE,
        "timestamp":     datetime.datetime.utcnow().isoformat() + "Z",
    })


@app.route("/api/items", methods=["GET"])
def get_items():
    """列出所有 items，served_by 欄位可以看到哪個 Pod 處理了請求"""
    return jsonify({
        "items":      items,
        "count":      len(items),
        "served_by":  POD_NAME,
    })


@app.route("/api/items", methods=["POST"])
def add_item():
    """新增 item。Body: {"name": "xxx"}"""
    data = request.get_json(silent=True)
    if not data or "name" not in data:
        return jsonify({"error": "JSON body with 'name' field is required"}), 400
    item = {
        "id":         len(items) + 1,
        "name":       data["name"],
        "created_by": POD_NAME,
    }
    items.append(item)
    return jsonify(item), 201


@app.route("/api/items/<int:item_id>", methods=["DELETE"])
def delete_item(item_id):
    global items
    before = len(items)
    items = [i for i in items if i["id"] != item_id]
    if len(items) == before:
        return jsonify({"error": "not found"}), 404
    return jsonify({"deleted": item_id}), 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    print(f"Starting Flask API v{APP_VERSION} on port {port}")
    app.run(host="0.0.0.0", port=port, debug=False)
