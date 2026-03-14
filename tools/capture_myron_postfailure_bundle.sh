#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
PREFIX="${2:-postfailure}"
OUT_DIR="${TOP_DIR}/_checkpoints/${PREFIX}_$(date +%Y%m%d_%H%M%S)"
MARKER_FILE="${MARKER_FILE:-}"
PRODUCT_MARKER_PATH="${PRODUCT_MARKER_PATH:-/product/etc/myron_partition_provenance_marker.txt}"
SYSTEM_EXT_MARKER_PATH="${SYSTEM_EXT_MARKER_PATH:-/system_ext/etc/myron_partition_provenance_marker.txt}"
PROVENANCE_PATHS=(
  "/product/app/MIUICloudServiceGlobal"
  "/product/app/MIUIMiCloudSync"
  "/product/priv-app/MIUISecurityCenterGlobal"
  "/product/app/MIUISecurityAdd"
  "/product/app/MIUIFileExplorerGlobal"
  "/system_ext/priv-app/FindDevice"
  "${PRODUCT_MARKER_PATH}"
  "${SYSTEM_EXT_MARKER_PATH}"
  "/system/framework/framework.jar"
  "/system/framework/services.jar"
)

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing host tool: $1" >&2
    exit 2
  }
}

need_cmd adb
mkdir -p "${OUT_DIR}"

capture_shell() {
  local out="$1"
  shift
  adb shell "$@" > "${out}" 2>&1 || true
}

capture_root_or_shell() {
  local out="$1"
  local cmd="$2"
  adb shell su -c "${cmd}" > "${out}" 2>&1 || adb shell "${cmd}" > "${out}" 2>&1 || true
}

adb wait-for-device
adb shell getprop > "${OUT_DIR}/getprop.txt"
adb shell logcat -d > "${OUT_DIR}/logcat_all.txt"
adb shell su -c dmesg > "${OUT_DIR}/dmesg.txt" 2>/dev/null || adb shell dmesg > "${OUT_DIR}/dmesg.txt" 2>/dev/null || true
adb shell cat /sys/fs/pstore/console-ramoops > "${OUT_DIR}/pstore_dump.txt" 2>/dev/null || true
adb shell cat /proc/last_kmsg > "${OUT_DIR}/last_kmsg.txt" 2>/dev/null || true
capture_shell "${OUT_DIR}/proc_mounts.txt" cat /proc/mounts
capture_shell "${OUT_DIR}/proc_self_mountinfo.txt" cat /proc/self/mountinfo
capture_shell "${OUT_DIR}/proc_1_mountinfo.txt" cat /proc/1/mountinfo
capture_root_or_shell "${OUT_DIR}/dmsetup_ls_tree.txt" "dmsetup ls --tree"
capture_root_or_shell "${OUT_DIR}/dmsetup_table.txt" "dmsetup table"
capture_shell "${OUT_DIR}/block_by_name.txt" ls -l /dev/block/by-name
capture_shell "${OUT_DIR}/proc_cmdline.txt" cat /proc/cmdline
{
  adb shell getprop ro.boot.slot_suffix || true
  adb shell getprop ro.boot.dynamic_partitions || true
  adb shell getprop ro.virtual_ab.enabled || true
  adb shell getprop ro.boot.vbmeta.device_state || true
} > "${OUT_DIR}/slot_facts.txt" 2>&1

{
  printf 'product_marker=%s\n' "${PRODUCT_MARKER_PATH}"
  printf 'system_ext_marker=%s\n' "${SYSTEM_EXT_MARKER_PATH}"
  for path in "${PROVENANCE_PATHS[@]}"; do
    printf '%s\n' "${path}"
  done
} > "${OUT_DIR}/provenance_targets.txt"

{
  printf 'for path'
  for path in "${PROVENANCE_PATHS[@]}"; do
    printf " '%s'" "${path}"
  done
  cat <<'EOF'
; do
  echo "== PATH:${path}"
  if [ -e "${path}" ]; then
    echo "exists=yes"
    ls -ldZ "${path}" 2>&1 || true
    stat "${path}" 2>&1 || true
    readlink -f "${path}" 2>&1 || true
    if [ -f "${path}" ]; then
      sha256sum "${path}" 2>&1 || true
    else
      find "${path}" -maxdepth 2 -type f \( -name '*.apk' -o -name '*.jar' -o -name '*.txt' \) -print 2>&1 | sort | while read -r file; do
        [ -n "${file}" ] || continue
        echo "-- file:${file}"
        ls -lZ "${file}" 2>&1 || true
        sha256sum "${file}" 2>&1 || true
      done
    fi
  else
    echo "exists=no"
  fi
done
EOF
} | adb shell > "${OUT_DIR}/path_provenance.txt" 2>&1 || true

python3 - "${OUT_DIR}/logcat_all.txt" "${OUT_DIR}/logcat_failed_boot_segment.txt" "${MARKER_FILE:-}" <<'PY'
import re
import sys
from pathlib import Path

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
marker_file = Path(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[3] else None
lines = src.read_text(errors="ignore").splitlines()

timestamp_re = re.compile(r"^(\d{2}-\d{2}) ")

def first_segment_after(start_index: int) -> list[str]:
    segment = []
    boot_prefix = None
    started = False
    for line in lines[start_index:]:
        if line.startswith("--------- beginning of "):
            started = True
            segment.append(line)
            continue
        if not started:
            continue
        m = timestamp_re.match(line)
        if m:
            if boot_prefix is None:
                boot_prefix = m.group(1)
            elif m.group(1) != boot_prefix:
                break
        segment.append(line)
    return segment

segment = []
if marker_file and marker_file.is_file():
    marker = marker_file.read_text(errors="ignore").strip()
    if marker:
        marker_index = None
        for idx, line in enumerate(lines):
            if marker in line:
                marker_index = idx
        if marker_index is not None:
            segment = first_segment_after(marker_index + 1)

if not segment:
    segment = first_segment_after(0)

dst.write_text("\n".join(segment) + ("\n" if segment else ""))
PY

if [[ -n "${FASTBOOT_VARS_FILE:-}" && -f "${FASTBOOT_VARS_FILE}" ]]; then
  cp "${FASTBOOT_VARS_FILE}" "${OUT_DIR}/fastboot_vars.txt"
fi

for runtime_path in /system/framework/framework.jar /system/framework/services.jar; do
  basename="$(basename "${runtime_path}")"
  adb shell "sha256sum ${runtime_path}" > "${OUT_DIR}/${basename}.runtime.sha256.txt" 2>&1 || true
done

if [[ -n "${MARKER_FILE}" && -f "${MARKER_FILE}" ]]; then
  cp "${MARKER_FILE}" "${OUT_DIR}/preflash_marker.txt"
  marker="$(cat "${MARKER_FILE}")"
  rg -n "${marker}" "${OUT_DIR}/logcat_all.txt" > "${OUT_DIR}/marker_hits.txt" || true
fi

echo "${OUT_DIR}"
