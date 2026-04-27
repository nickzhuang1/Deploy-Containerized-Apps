#!/usr/bin/env bash
# ============================================================
# GPU 容器執行範例
# ============================================================

# ── 使用所有 GPU ──────────────────────────────────────────
docker run --rm --gpus all \
    nvidia/cuda:12.2.0-base-ubuntu22.04 \
    nvidia-smi

# ── 只使用 GPU 0 ──────────────────────────────────────────
docker run --rm --gpus device=0 \
    nvidia/cuda:12.2.0-base-ubuntu22.04 \
    nvidia-smi

# ── 使用 GPU 0 和 1 ───────────────────────────────────────
docker run --rm --gpus '"device=0,1"' \
    nvidia/cuda:12.2.0-base-ubuntu22.04 \
    nvidia-smi

# ── PyTorch GPU 訓練 ──────────────────────────────────────
# docker run --rm --gpus all \
#     -v "$(pwd)/data":/data \
#     pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime \
#     python train.py

# ── 互動式進入 TensorFlow 容器 ────────────────────────────
# docker run -it --gpus all --rm \
#     nvcr.io/nvidia/tensorflow:24.01-tf2-py3 \
#     bash

# ── 查看容器內 GPU 資訊 ───────────────────────────────────
echo ""
echo "=== 容器內 nvidia-smi 輸出 ==="
docker run --rm --gpus all \
    nvidia/cuda:12.2.0-base-ubuntu22.04 \
    nvidia-smi --query-gpu=name,driver_version,memory.total,memory.free \
    --format=csv,noheader
