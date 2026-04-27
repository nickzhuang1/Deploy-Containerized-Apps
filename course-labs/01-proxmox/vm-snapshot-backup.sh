#!/usr/bin/env bash
# ============================================================
# Proxmox VM 快照與備份指令速查
# 在 Proxmox 節點以 root 身份執行
# ============================================================

VMID=101   # ← 改成你的 VM ID

# ════════════════════════════════════════
# 快照（Snapshot）
# ════════════════════════════════════════

# 建立快照（VM 需使用 qcow2/raw 磁碟，非 lvm-thin）
qm snapshot ${VMID} snap-before-update --vmstate 1
# --vmstate 1 = 同時保存記憶體狀態（VM 不需停機）

# 列出快照
qm listsnapshot ${VMID}

# 還原快照
qm rollback ${VMID} snap-before-update

# 刪除快照
qm delsnapshot ${VMID} snap-before-update

# ════════════════════════════════════════
# 備份（Backup）- vzdump
# ════════════════════════════════════════

# 備份到 local storage（/var/lib/vz/dump/）
vzdump ${VMID} \
    --storage local \
    --mode snapshot \
    --compress zstd \
    --notes "手動備份 $(date +%Y-%m-%d)"

# 備份多台 VM（逗號分隔）
# vzdump 101,102,103 --storage local --mode snapshot --compress zstd

# 備份所有 VM
# vzdump --all --storage local --mode snapshot --compress zstd

# 查看備份清單
ls -lh /var/lib/vz/dump/*.vma.zst 2>/dev/null || \
ls -lh /var/lib/vz/dump/*.vma.gz  2>/dev/null

# 還原備份（注意：會建立新的 VMID）
BACKUP_FILE=$(ls /var/lib/vz/dump/vzdump-qemu-${VMID}-*.vma.zst | tail -1)
qmrestore "${BACKUP_FILE}" 102   # 還原成 VMID 102

# ════════════════════════════════════════
# 排程備份（crontab 或 Proxmox UI 設定）
# ════════════════════════════════════════
# 建議在 Web UI > Datacenter > Backup 設定，
# 可設定排程、保留數量、儲存目標等。
#
# CLI 範例：每天凌晨 2:00 備份 VMID 101，保留 7 份
# 在 /etc/cron.d/pve-backup 新增：
# 0 2 * * * root vzdump 101 --storage local --mode snapshot \
#   --compress zstd --maxfiles 7 --quiet 1
