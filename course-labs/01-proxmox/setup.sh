#!/usr/bin/env bash
# ============================================================
# Proxmox VE 安裝後初始設定
# 在 Proxmox 節點以 root 身份執行
# ============================================================

set -euo pipefail

# ── 1. 修正 /etc/hosts（避免 hostname 無法解析導致服務報錯）──────────────
PVE_IP="192.168.1.100"   # ← 改成你的實際 IP
PVE_HOSTNAME="pve"

echo ">>> 設定 /etc/hosts"
cat >> /etc/hosts <<EOF
${PVE_IP}  pve.local  ${PVE_HOSTNAME}
EOF

# ── 2. 關閉 Enterprise repo，改用免費 no-subscription repo ────────────────
echo ">>> 切換到 no-subscription repo"
sed -i 's|enterprise|no-subscription|g' \
    /etc/apt/sources.list.d/pve-enterprise.list 2>/dev/null || true

# 加入 no-subscription source（Proxmox 8.x）
cat > /etc/apt/sources.list.d/pve-no-subscription.list <<EOF
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF

# ── 3. 更新系統 ───────────────────────────────────────────────────────────
echo ">>> 更新套件"
apt update && apt dist-upgrade -y

# ── 4. 關閉 nag（訂閱提示視窗）──────────────────────────────────────────
echo ">>> 關閉訂閱提示"
sed -i.bak "s/data.status !== 'Active'/false/g" \
    /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js 2>/dev/null || true
systemctl restart pveproxy

# ── 5. 確認服務狀態 ──────────────────────────────────────────────────────
echo ">>> 服務狀態"
systemctl status pve-cluster --no-pager -l | head -10
systemctl status pveproxy   --no-pager -l | head -5

echo ""
echo "✅ 完成！請用瀏覽器開啟：https://${PVE_IP}:8006"
echo "   帳號: root  密碼: 安裝時設定的密碼"
