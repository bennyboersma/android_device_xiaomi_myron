#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
PRODUCT="${2:-myron}"
OUT_DIR="${TOP_DIR}/out/target/product/${PRODUCT}"
DRY_RUN="${DRY_RUN:-1}"
REBOOT_TO_FASTBOOTD="${REBOOT_TO_FASTBOOTD:-1}"
USE_SUPER="${USE_SUPER:-0}"
FLASH_VBMETA_SYSTEM="${FLASH_VBMETA_SYSTEM:-0}"
FLASH_SYSTEM="${FLASH_SYSTEM:-1}"
FLASH_SYSTEM_EXT="${FLASH_SYSTEM_EXT:-1}"
FLASH_PRODUCT="${FLASH_PRODUCT:-1}"
FLASH_VENDOR="${FLASH_VENDOR:-1}"
FLASH_ODM="${FLASH_ODM:-1}"
FLASH_VENDOR_DLKM="${FLASH_VENDOR_DLKM:-1}"
FLASH_SYSTEM_DLKM="${FLASH_SYSTEM_DLKM:-1}"
TARGET_SLOT="${TARGET_SLOT:-}"
ALLOW_ACTIVE_SLOT_FLASH="${ALLOW_ACTIVE_SLOT_FLASH:-0}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing host tool: $1" >&2
    exit 2
  }
}

need_cmd fastboot
need_cmd awk

has_fastboot_device() {
  fastboot devices | awk 'NF {print $1}' | grep -q .
}

wait_for_fastboot() {
  local tries=0
  until has_fastboot_device; do
    tries=$((tries + 1))
    if [[ ${tries} -ge 30 ]]; then
      echo "Timed out waiting for fastboot" >&2
      exit 2
    fi
    sleep 1
  done
}

wait_for_fastbootd() {
  local tries=0
  local state=""
  until state="$(fastboot getvar is-userspace 2>&1 | awk -F': ' '/is-userspace:/{print $2}' | tail -n 1)" \
    && [[ "${state}" == "yes" ]]; do
    tries=$((tries + 1))
    if [[ ${tries} -ge 30 ]]; then
      echo "Timed out waiting for fastbootd" >&2
      exit 2
    fi
    sleep 1
  done
}

enter_fastbootd() {
  if has_fastboot_device && fastboot getvar is-userspace 2>&1 | grep -q 'yes'; then
    return 0
  fi

  if command -v adb >/dev/null 2>&1 && adb get-state >/dev/null 2>&1; then
    adb reboot fastboot >/dev/null 2>&1 || true
    wait_for_fastboot
    wait_for_fastbootd
    return 0
  fi

  if has_fastboot_device; then
    fastboot reboot fastboot >/dev/null 2>&1 || true
    wait_for_fastboot
    wait_for_fastbootd
    return 0
  fi

  echo "No adb or fastboot device available to enter fastbootd" >&2
  exit 2
}

require_image() {
  local part="$1"
  local path="$2"
  if [[ ! -f "${path}" ]]; then
    echo "Missing artifact for ${part}: ${path}" >&2
    exit 2
  fi
}

require_valid_slot() {
  local slot="$1"
  case "${slot}" in
    a|b) ;;
    *)
      echo "Invalid TARGET_SLOT: ${slot}. Expected 'a' or 'b'." >&2
      exit 2
      ;;
  esac
}

[[ -n "${TARGET_SLOT}" ]] || {
  echo "TARGET_SLOT is required. Example: TARGET_SLOT=b" >&2
  exit 2
}
require_valid_slot "${TARGET_SLOT}"

if [[ "${USE_SUPER}" == "1" ]]; then
  require_image super "${OUT_DIR}/super.img"
else
  [[ "${FLASH_SYSTEM}" == "0" ]] || require_image system "${OUT_DIR}/system.img"
  [[ "${FLASH_SYSTEM_EXT}" == "0" ]] || require_image system_ext "${OUT_DIR}/system_ext.img"
  [[ "${FLASH_PRODUCT}" == "0" ]] || require_image product "${OUT_DIR}/product.img"
  [[ "${FLASH_VENDOR}" == "0" ]] || require_image vendor "${OUT_DIR}/vendor.img"
  [[ "${FLASH_ODM}" == "0" ]] || require_image odm "${OUT_DIR}/odm.img"
  [[ "${FLASH_VENDOR_DLKM}" == "0" ]] || require_image vendor_dlkm "${OUT_DIR}/vendor_dlkm.img"
  [[ "${FLASH_SYSTEM_DLKM}" == "0" ]] || require_image system_dlkm "${OUT_DIR}/system_dlkm.img"
fi
if [[ "${FLASH_VBMETA_SYSTEM}" == "1" ]]; then
  require_image vbmeta_system "${OUT_DIR}/vbmeta_system.img"
fi

if [[ "${REBOOT_TO_FASTBOOTD}" == "1" ]]; then
  enter_fastbootd
fi

product="$(fastboot getvar product 2>&1 | awk -F': ' '/product:/{print $2}' | tail -n 1)"
current_slot="$(fastboot getvar current-slot 2>&1 | awk -F': ' '/current-slot:/{print $2}' | tail -n 1)"
userspace="$(fastboot getvar is-userspace 2>&1 | awk -F': ' '/is-userspace:/{print $2}' | tail -n 1)"

[[ "${product}" == "${PRODUCT}" ]] || { echo "Unexpected product: ${product}" >&2; exit 2; }
[[ -n "${current_slot}" ]] || { echo "Unable to resolve current slot" >&2; exit 2; }

if [[ "${TARGET_SLOT}" == "${current_slot}" && "${ALLOW_ACTIVE_SLOT_FLASH}" != "1" ]]; then
  echo "Refusing to flash active slot ${current_slot}. Set ALLOW_ACTIVE_SLOT_FLASH=1 to override." >&2
  exit 2
fi

flash_cmds=()
if [[ "${USE_SUPER}" == "1" ]]; then
  flash_cmds+=("fastboot flash super ${OUT_DIR}/super.img")
else
  [[ "${FLASH_SYSTEM}" == "0" ]] || flash_cmds+=("fastboot flash system_${TARGET_SLOT} ${OUT_DIR}/system.img")
  [[ "${FLASH_SYSTEM_EXT}" == "0" ]] || flash_cmds+=("fastboot flash system_ext_${TARGET_SLOT} ${OUT_DIR}/system_ext.img")
  [[ "${FLASH_PRODUCT}" == "0" ]] || flash_cmds+=("fastboot flash product_${TARGET_SLOT} ${OUT_DIR}/product.img")
  [[ "${FLASH_VENDOR}" == "0" ]] || flash_cmds+=("fastboot flash vendor_${TARGET_SLOT} ${OUT_DIR}/vendor.img")
  [[ "${FLASH_ODM}" == "0" ]] || flash_cmds+=("fastboot flash odm_${TARGET_SLOT} ${OUT_DIR}/odm.img")
  [[ "${FLASH_VENDOR_DLKM}" == "0" ]] || flash_cmds+=("fastboot flash vendor_dlkm_${TARGET_SLOT} ${OUT_DIR}/vendor_dlkm.img")
  [[ "${FLASH_SYSTEM_DLKM}" == "0" ]] || flash_cmds+=("fastboot flash system_dlkm_${TARGET_SLOT} ${OUT_DIR}/system_dlkm.img")
fi
if [[ "${FLASH_VBMETA_SYSTEM}" == "1" ]]; then
  flash_cmds+=("fastboot flash vbmeta_system_${TARGET_SLOT} ${OUT_DIR}/vbmeta_system.img")
fi

echo "target_product=${product}"
echo "current_slot=${current_slot}"
echo "target_slot=${TARGET_SLOT}"
echo "is_userspace_fastboot=${userspace:-unknown}"
echo "use_super=${USE_SUPER}"
echo "flash_vbmeta_system=${FLASH_VBMETA_SYSTEM}"
echo "allow_active_slot_flash=${ALLOW_ACTIVE_SLOT_FLASH}"
printf '%s\n' "${flash_cmds[@]}"

if [[ "${DRY_RUN}" == "1" ]]; then
  echo "DRY_RUN=1, no flashing performed"
  exit 0
fi

for cmd in "${flash_cmds[@]}"; do
  eval "${cmd}"
done
