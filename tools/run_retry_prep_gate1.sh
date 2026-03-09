#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
PRODUCT="${2:-myron}"
APPLY_PROACTIVE_PRUNE="${APPLY_PROACTIVE_PRUNE:-1}"
JOBS="${JOBS:-10}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

step() {
  printf '\n==> %s\n' "$1"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing host tool: $1" >&2
    exit 2
  }
}

need_cmd bash
need_cmd python3

if [[ "${APPLY_PROACTIVE_PRUNE}" == "1" ]]; then
  step "apply proactive retry-prep prune"
  python3 "${SCRIPT_DIR}/prune_generated_vendor_modules.py" \
    "${TOP_DIR}/vendor/xiaomi/myron/Android.bp" \
    --file "${SCRIPT_DIR}/retry_prep_drop_modules.txt" \
    --keep-file "${SCRIPT_DIR}/retry_prep_keep_modules.txt"

  prefix_args=()
  while IFS= read -r prefix; do
    [[ -n "${prefix}" ]] || continue
    [[ "${prefix}" =~ ^# ]] && continue
    prefix_args+=(--prefix "${prefix}")
  done < "${SCRIPT_DIR}/retry_prep_drop_prefixes.txt"

  if [[ ${#prefix_args[@]} -ne 0 ]]; then
    python3 "${SCRIPT_DIR}/prune_generated_vendor_modules.py" \
      "${TOP_DIR}/vendor/xiaomi/myron/Android.bp" \
      "${prefix_args[@]}" \
      --keep-file "${SCRIPT_DIR}/retry_prep_keep_modules.txt"
  fi
fi

step "gate 1"
set +u
source "${TOP_DIR}/build/envsetup.sh" >/dev/null
lunch "lineage_${PRODUCT}-trunk_staging-userdebug" >/dev/null
set -u
m nothing -j"${JOBS}"
