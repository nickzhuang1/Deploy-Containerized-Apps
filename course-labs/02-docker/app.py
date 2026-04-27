"""
課程範例 Flask API
測試：curl http://localhost:5000/
"""
from flask import Flask, jsonify
import os
import socket

app = Flask(__name__)

@app.route("/")
def index():
    return jsonify({
        "message": "Hello from Container!",
        "hostname": socket.gethostname(),
        "env": os.environ.get("APP_ENV", "development"),
    })

@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
