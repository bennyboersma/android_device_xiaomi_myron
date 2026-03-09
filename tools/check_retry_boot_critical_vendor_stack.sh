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

need_cmd awk

[[ -f "${REQUIREMENTS_FILE}" ]] || {
  echo "Missing requirements file: ${REQUIREMENTS_FILE}" >&2
  exit 2
}

echo "[boot-critical] out_dir=${OUT_DIR}"

missing=0
while read -r kind relpath; do
  [[ -n "${kind}" ]] || continue
  [[ "${kind}" =~ ^# ]] && continue
  path="${OUT_DIR}/${relpath}"
  if [[ -e "${path}" ]]; then
    printf '[ok:%s] %s\n' "${kind}" "${path}"
  else
    printf '[missing:%s] %s\n' "${kind}" "${path}" >&2
    missing=$((missing + 1))
  fi
done < "${REQUIREMENTS_FILE}"

if [[ ${missing} -ne 0 ]]; then
  echo "[result] FAIL missing_boot_critical_vendor_outputs=${missing}" >&2
  exit 1
fi

echo "[result] PASS"
