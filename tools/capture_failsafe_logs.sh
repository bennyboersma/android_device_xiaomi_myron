#!/usr/bin/env bash
# tools/capture_failsafe_logs.sh
set -euo pipefail

OUT_DIR="${1:-_checkpoints/failsafe_logs_$(date +%Y%m%d_%H%M%S)}"
mkdir -p "${OUT_DIR}"

echo "[failsafe] capturing logs to ${OUT_DIR}"

# Try adb first (even if unstable)
if timeout 5 adb wait-for-device >/dev/null 2>&1; then
    echo "[failsafe] adb online, pulling standard logs"
    adb shell dmesg > "${OUT_DIR}/dmesg.txt" || true
    adb shell logcat -b all -d > "${OUT_DIR}/logcat.txt" || true
    adb shell "cat /proc/last_kmsg" > "${OUT_DIR}/last_kmsg.txt" || true
    adb shell "ls -l /sys/fs/pstore" > "${OUT_DIR}/pstore_list.txt" || true
    adb shell "cat /sys/fs/pstore/*" > "${OUT_DIR}/pstore_combined.txt" || true
fi

# Try recovery mode (usually has pstore access if supported)
echo "[failsafe] checking for recovery/fastbootd pstore"
if adb get-state 2>/dev/null | grep -q 'recovery'; then
    echo "[failsafe] recovery detected, pulling ramoops"
    adb shell "mount -t pstore pstore /sys/fs/pstore" || true
    mkdir -p "${OUT_DIR}/pstore"
    adb pull /sys/fs/pstore/ "${OUT_DIR}/pstore/" || true
fi

echo "[failsafe] done. artifacts in ${OUT_DIR}"
