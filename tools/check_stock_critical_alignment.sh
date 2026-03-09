#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
PRODUCT="${2:-myron}"
OUT_DIR="${TOP_DIR}/out/target/product/${PRODUCT}"
REQUIREMENTS_FILE="${REQUIREMENTS_FILE:-${TOP_DIR}/tools/boot_critical_vendor_outputs.txt}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing host tool: $1" >&2
    exit 2
  }
}

need_cmd adb
need_cmd awk

[[ -f "${REQUIREMENTS_FILE}" ]] || {
  echo "Missing requirements file: ${REQUIREMENTS_FILE}" >&2
  exit 2
}

adb get-state >/dev/null 2>&1 || {
  echo "adb device required for stock-vs-built alignment check" >&2
  exit 2
}

echo "[alignment] product=${PRODUCT}"
echo "[alignment] out_dir=${OUT_DIR}"

mismatch=0
while read -r kind relpath; do
  [[ -n "${kind}" ]] || continue
  [[ "${kind}" =~ ^# ]] && continue

  stock_path="/${relpath}"
  built_path="${OUT_DIR}/${relpath}"

  if adb shell "if [ -e ${stock_path} ]; then echo present; else echo missing; fi" </dev/null 2>/dev/null \
      | tr -d '\r' | grep -qx 'present'; then
    stock_state="present"
  else
    stock_state="missing"
  fi

  if compgen -G "${built_path}" >/dev/null; then
    built_state="present"
  else
    built_state="missing"
  fi

  if [[ "${stock_state}" == "${built_state}" ]]; then
    printf '[ok:%s] %s stock=%s built=%s\n' "${kind}" "${relpath}" "${stock_state}" "${built_state}"
  else
    printf '[mismatch:%s] %s stock=%s built=%s\n' "${kind}" "${relpath}" "${stock_state}" "${built_state}" >&2
    mismatch=$((mismatch + 1))
  fi
done < "${REQUIREMENTS_FILE}"

if [[ ${mismatch} -ne 0 ]]; then
  echo "[result] FAIL stock_built_mismatch_count=${mismatch}" >&2
  exit 1
fi

echo "[result] PASS"
