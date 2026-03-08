#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
PRODUCT="${2:-myron}"
OUT_DIR="${TOP_DIR}/out/target/product/${PRODUCT}"
DRY_RUN="${DRY_RUN:-1}"
FLASH_BOOT="${FLASH_BOOT:-1}"
FLASH_INIT_BOOT="${FLASH_INIT_BOOT:-1}"
FLASH_VENDOR_BOOT="${FLASH_VENDOR_BOOT:-1}"

boot_img="${OUT_DIR}/boot.img"
init_boot_img="${OUT_DIR}/init_boot.img"
vendor_boot_img="${OUT_DIR}/vendor_boot.img"

if [[ "${FLASH_BOOT}" == "1" ]]; then
  [[ -f "${boot_img}" ]] || { echo "Missing artifact: ${boot_img}" >&2; exit 2; }
fi
if [[ "${FLASH_INIT_BOOT}" == "1" ]]; then
  [[ -f "${init_boot_img}" ]] || { echo "Missing artifact: ${init_boot_img}" >&2; exit 2; }
fi
if [[ "${FLASH_VENDOR_BOOT}" == "1" ]]; then
  [[ -f "${vendor_boot_img}" ]] || { echo "Missing artifact: ${vendor_boot_img}" >&2; exit 2; }
fi

product="$(fastboot getvar product 2>&1 | awk -F': ' '/product:/{print $2}' | tail -n 1)"
slot="$(fastboot getvar current-slot 2>&1 | awk -F': ' '/current-slot:/{print $2}' | tail -n 1)"

[[ "${product}" == "${PRODUCT}" ]] || { echo "Unexpected product: ${product}" >&2; exit 2; }
[[ -n "${slot}" ]] || { echo "Unable to resolve current slot" >&2; exit 2; }

echo "target_product=${product}"
echo "target_slot=${slot}"
echo "boot_partition=boot_${slot}"
echo "init_boot_partition=init_boot_${slot}"
echo "vendor_boot_partition=vendor_boot_${slot}"
echo "flash_boot=${FLASH_BOOT}"
echo "flash_init_boot=${FLASH_INIT_BOOT}"
echo "flash_vendor_boot=${FLASH_VENDOR_BOOT}"

if [[ "${DRY_RUN}" == "1" ]]; then
  echo "DRY_RUN=1, no flashing performed"
  exit 0
fi

if [[ "${FLASH_BOOT}" == "1" ]]; then
  fastboot flash "boot_${slot}" "${boot_img}"
fi
if [[ "${FLASH_INIT_BOOT}" == "1" ]]; then
  fastboot flash "init_boot_${slot}" "${init_boot_img}"
fi
if [[ "${FLASH_VENDOR_BOOT}" == "1" ]]; then
  fastboot flash "vendor_boot_${slot}" "${vendor_boot_img}"
fi
