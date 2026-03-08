#!/usr/bin/env bash
set -euo pipefail

TREE_DIR="${1:-$HOME/android/lineage}"
MIN_FREE_GB="${MIN_FREE_GB:-120}"
MIN_CCACHE_GB="${MIN_CCACHE_GB:-20}"
MIN_ULIMIT_N="${MIN_ULIMIT_N:-1024}"

critical_cmds=(git repo python3 java javac adb fastboot)
recommended_cmds=(rg ccache)
missing_critical=0

echo "[env] tree=${TREE_DIR}"

for c in "${critical_cmds[@]}"; do
  if ! command -v "$c" >/dev/null 2>&1; then
    echo "MISSING_CRITICAL_CMD $c"
    missing_critical=1
  fi
done

for c in "${recommended_cmds[@]}"; do
  if ! command -v "$c" >/dev/null 2>&1; then
    echo "MISSING_RECOMMENDED_CMD $c"
  fi
done

if command -v ccache >/dev/null 2>&1; then
  echo "[env] ccache present"
  ccache -s | sed -n '1,8p' || true
  ccache_limit_gb="$(ccache -s 2>/dev/null | awk '/Cache size \\(GB\\):/{print $6}' | tr -d '()' || true)"
  if [[ -n "${ccache_limit_gb}" ]]; then
    awk -v cur="${ccache_limit_gb}" -v min="${MIN_CCACHE_GB}" 'BEGIN{exit !(cur+0 < min+0)}' \
      && echo "LOW_CCACHE_LIMIT current=${ccache_limit_gb}GB recommended=${MIN_CCACHE_GB}GB" \
      || true
  fi
else
  echo "[env] ccache absent (recommended for faster iteration)"
fi

if [[ -d "$TREE_DIR" ]]; then
  avail_kb=$(df -Pk "$TREE_DIR" | awk 'NR==2{print $4}')
  avail_gb=$((avail_kb / 1024 / 1024))
  echo "[env] free_space_gb=${avail_gb}"
  if (( avail_gb < MIN_FREE_GB )); then
    echo "LOW_DISK_SPACE threshold=${MIN_FREE_GB}GB current=${avail_gb}GB"
    missing_critical=1
  fi
fi

ulimit_n="$(ulimit -n || true)"
echo "[env] ulimit_n=${ulimit_n}"
if [[ "${ulimit_n}" =~ ^[0-9]+$ ]] && (( ulimit_n < MIN_ULIMIT_N )); then
  echo "LOW_ULIMIT_N current=${ulimit_n} recommended>=${MIN_ULIMIT_N}"
fi

if (( missing_critical != 0 )); then
  echo "[env] FAIL"
  exit 1
fi

echo "[env] PASS"
