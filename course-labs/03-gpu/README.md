# GPU 容器化實作 — Demo 操作手冊

環境：已安裝 NVIDIA Driver 的 Ubuntu 22.04 主機（`nvidia-smi` 可正常執行）

---

## 檔案結構

```
03-gpu/
├── nvidia-toolkit-install.sh   # 安裝 NVIDIA Container Toolkit
└── gpu-run.sh                  # GPU 容器執行範例
```

---

## 事前準備（上課前做一次）

### 確認 Driver 正常

```bash
nvidia-smi
```

預期輸出（顯示 GPU 型號、Driver 版本、顯示卡記憶體）：
```
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 535.xx    Driver Version: 535.xx    CUDA Version: 12.2          |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC|
...
```

---

## Part 1：安裝 NVIDIA Container Toolkit

```bash
cd course-labs/03-gpu
chmod +x nvidia-toolkit-install.sh
./nvidia-toolkit-install.sh
```

腳本流程說明：
1. 確認 `nvidia-smi` 可用
2. 加入 NVIDIA APT repo
3. 安裝 `nvidia-container-toolkit`
4. 設定 Docker runtime（`nvidia-ctk runtime configure`）
5. 重啟 Docker
6. 執行驗證：在容器內跑 `nvidia-smi`

> **展示重點**：安裝後 Docker 多了 `--gpus` flag，容器可以直接使用 GPU。

---

## Part 2：GPU 容器執行 Demo

### 全部 GPU

```bash
docker run --rm --gpus all \
    nvidia/cuda:12.2.0-base-ubuntu22.04 \
    nvidia-smi
```

### 只用 GPU 0

```bash
docker run --rm --gpus device=0 \
    nvidia/cuda:12.2.0-base-ubuntu22.04 \
    nvidia-smi
```

### 查詢 GPU 詳細資訊

```bash
docker run --rm --gpus all \
    nvidia/cuda:12.2.0-base-ubuntu22.04 \
    nvidia-smi --query-gpu=name,driver_version,memory.total,memory.free \
    --format=csv,noheader
```

預期輸出（含可用顯示卡記憶體）：
```
Tesla V100-SXM2-32GB, 535.xx, 32510 MiB, 32000 MiB
```

### 互動式進入 GPU 容器

```bash
docker run -it --rm --gpus all \
    nvidia/cuda:12.2.0-base-ubuntu22.04 \
    bash
# 在容器內
nvidia-smi
python3 -c "import os; print(os.environ.get('NVIDIA_VISIBLE_DEVICES'))"
exit
```

---

## Part 3：進階範例（視時間決定是否示範）

### PyTorch 確認 CUDA 可用

```bash
docker run --rm --gpus all \
    pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime \
    python3 -c "import torch; print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0))"
```

### 多 GPU

```bash
docker run --rm --gpus '"device=0,1"' \
    nvidia/cuda:12.2.0-base-ubuntu22.04 \
    nvidia-smi
```

---

## 常見問題

| 錯誤訊息 | 原因 | 解法 |
|---|---|---|
| `Error response from daemon: could not select device driver ""` | Container Toolkit 未設定 Docker runtime | 執行 `sudo nvidia-ctk runtime configure --runtime=docker && sudo systemctl restart docker` |
| `nvidia-smi: not found`（容器內） | Image 無 NVIDIA 工具 | 改用 `nvidia/cuda:*-base-*` image |
| `Failed to initialize NVML: Driver/library version mismatch` | Host Driver 版本與 CUDA image 不符 | 換 CUDA image tag 對應 Driver 版本 |

---

## 注意事項

- `--gpus all` 是讓容器看見所有 GPU；不加此 flag 則容器完全看不到 GPU（即便 Host 有）。
- GPU 資源**不共享**：同時多個容器搶同一張 GPU 時，顯存是競爭關係，並非自動分配。
- Kubernetes 需額外安裝 `nvidia-device-plugin` DaemonSet 才能在 Pod 中使用 GPU（見 04-kubernetes）。
