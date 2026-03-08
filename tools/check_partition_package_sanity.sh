#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
PRODUCT="${2:-myron}"
OUT_DIR="${TOP_DIR}/out/target/product/${PRODUCT}"
DEVICE_BC="${TOP_DIR}/device/xiaomi/myron/BoardConfig.mk"
COMMON_BC="${TOP_DIR}/device/xiaomi/sm8850-common/BoardConfigCommon.mk"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing host tool: $1" >&2
    exit 2
  }
}

need_cmd awk
need_cmd sed
need_cmd rg

extract_simple_var() {
  local file="$1"
  local key="$2"
  sed -n "s/^${key}[[:space:]]*:=[[:space:]]*//p" "${file}" | head -n 1 | sed 's/[[:space:]]#.*$//'
}

echo "[sanity] product=${PRODUCT}"
echo "[sanity] out_dir=${OUT_DIR}"

device_super_size="$(extract_simple_var "${DEVICE_BC}" "BOARD_SUPER_PARTITION_SIZE")"
device_group_size="$(extract_simple_var "${DEVICE_BC}" "BOARD_XIAOMI_DYNAMIC_PARTITIONS_SIZE")"
device_partition_list="$(extract_simple_var "${DEVICE_BC}" "BOARD_XIAOMI_DYNAMIC_PARTITIONS_PARTITION_LIST")"

echo "[config] device_super_size=${device_super_size}"
echo "[config] device_dynamic_group_size=${device_group_size}"
echo "[config] device_dynamic_partitions=${device_partition_list}"

for pair in \
  "system:BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE:${DEVICE_BC}" \
  "system_ext:BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE:${DEVICE_BC}" \
  "product:BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE:${DEVICE_BC}" \
  "vendor:BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE:${DEVICE_BC}" \
  "odm:BOARD_ODMIMAGE_FILE_SYSTEM_TYPE:${DEVICE_BC}" \
  "vendor_dlkm:BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE:${DEVICE_BC}" \
  "system_dlkm:BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE:${DEVICE_BC}"; do
  part="${pair%%:*}"
  rest="${pair#*:}"
  key="${rest%%:*}"
  file="${rest##*:}"
  fs_type="$(extract_simple_var "${file}" "${key}")"
  echo "[config] ${part}_fs=${fs_type}"
done

required_images=(
  system.img
  system_ext.img
  product.img
  vendor.img
  odm.img
  vendor_dlkm.img
  system_dlkm.img
)

missing=0
present_bytes=0

for image in "${required_images[@]}"; do
  path="${OUT_DIR}/${image}"
  if [[ -f "${path}" ]]; then
    size="$(wc -c < "${path}" | tr -d ' ')"
    echo "[artifact] ${image} size_bytes=${size}"
    present_bytes=$((present_bytes + size))
  else
    echo "[artifact] missing ${image}"
    missing=$((missing + 1))
  fi
done

echo "[artifact] total_present_bytes=${present_bytes}"
if [[ -n "${device_group_size}" ]] && [[ "${device_group_size}" =~ ^[0-9]+$ ]] && (( present_bytes > 0 )); then
  echo "[artifact] dynamic_group_limit_bytes=${device_group_size}"
  if (( present_bytes > device_group_size )); then
    echo "[result] FAIL artifact bytes exceed dynamic group size" >&2
    exit 1
  fi
fi

if (( missing > 0 )); then
  echo "[result] INCOMPLETE missing_images=${missing}"
  exit 1
fi

echo "[result] PASS"
