#!/usr/bin/env bash
# ============================================================
# NVIDIA Container Toolkit 安裝腳本
# 適用：Ubuntu 22.04 / Debian 12
# 前提：nvidia-smi 已可正常執行（Driver 已裝）
# ============================================================

set -euo pipefail

echo ">>> 確認 NVIDIA Driver"
nvidia-smi || { echo "❌ nvidia-smi 失敗，請先安裝 NVIDIA Driver"; exit 1; }

echo ">>> 加入 NVIDIA Container Toolkit APT repo"
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

echo ">>> 安裝 nvidia-container-toolkit"
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

echo ">>> 設定 Docker runtime"
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

echo ">>> 驗證安裝（跑 nvidia-smi 在容器內）"
docker run --rm --gpus all \
    nvidia/cuda:12.2.0-base-ubuntu22.04 \
    nvidia-smi

echo "✅ NVIDIA Container Toolkit 安裝完成！"
