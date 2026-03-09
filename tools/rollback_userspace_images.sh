#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_LOCAL_SUPER="${SCRIPT_DIR}/../extracted_20260302_140152/_super_from_fastboot/myron_eea_global_images_OS3.0.7.0.WPMEUXM_16.0/images/super.img"
DEFAULT_LOCAL_VBMETA_SYSTEM="${SCRIPT_DIR}/../_transfer/rollback_wpm_eu/stock_vbmeta_20260308/myron_eea_global_images_OS3.0.7.0.WPMEUXM_16.0/images/vbmeta_system.img"
DEFAULT_REMOTE_SUPER="${SCRIPT_DIR}/../_transfer/rollback_wpm_eu/stock_userspace_20260308/super.img"
DEFAULT_REMOTE_VBMETA_SYSTEM="${SCRIPT_DIR}/../_transfer/rollback_wpm_eu/stock_userspace_20260308/vbmeta_system.img"

resolve_first_existing() {
  local candidate
  for candidate in "$@"; do
    if [[ -n "${candidate}" && -f "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  return 1
}

STOCK_SUPER_IMG="${STOCK_SUPER_IMG:-}"
if [[ -z "${STOCK_SUPER_IMG}" ]]; then
  STOCK_SUPER_IMG="$(resolve_first_existing \
    "${DEFAULT_REMOTE_SUPER}" \
    "${DEFAULT_LOCAL_SUPER}" || true)"
fi

STOCK_VBMETA_SYSTEM_IMG="${STOCK_VBMETA_SYSTEM_IMG:-}"
if [[ -z "${STOCK_VBMETA_SYSTEM_IMG}" ]]; then
  STOCK_VBMETA_SYSTEM_IMG="$(resolve_first_existing \
    "${DEFAULT_REMOTE_VBMETA_SYSTEM}" \
    "${DEFAULT_LOCAL_VBMETA_SYSTEM}" || true)"
fi
DRY_RUN="${DRY_RUN:-1}"
REBOOT_TO_FASTBOOTD="${REBOOT_TO_FASTBOOTD:-1}"
FLASH_VBMETA_SYSTEM="${FLASH_VBMETA_SYSTEM:-1}"
REQUIRE_DEVICE="${REQUIRE_DEVICE:-1}"
PRODUCT="${1:-myron}"
TARGET_SLOT="${TARGET_SLOT:-}"
ALLOW_ACTIVE_SLOT_ROLLBACK="${ALLOW_ACTIVE_SLOT_ROLLBACK:-0}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing host tool: $1" >&2
    exit 2
  }
}

need_cmd awk
if [[ "${REQUIRE_DEVICE}" == "1" ]]; then
  need_cmd fastboot
fi

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

[[ -f "${STOCK_SUPER_IMG}" ]] || {
  echo "Missing stock super image: ${STOCK_SUPER_IMG}" >&2
  exit 2
}
if [[ "${FLASH_VBMETA_SYSTEM}" == "1" ]]; then
  [[ -f "${STOCK_VBMETA_SYSTEM_IMG}" ]] || {
    echo "Missing stock vbmeta_system image: ${STOCK_VBMETA_SYSTEM_IMG}" >&2
    exit 2
  }
fi

product="not-checked"
current_slot="not-checked"
userspace="not-checked"
if [[ "${REQUIRE_DEVICE}" == "1" ]]; then
  if [[ "${REBOOT_TO_FASTBOOTD}" == "1" ]]; then
    enter_fastbootd
  fi

  product="$(fastboot getvar product 2>&1 | awk -F': ' '/product:/{print $2}' | tail -n 1)"
  current_slot="$(fastboot getvar current-slot 2>&1 | awk -F': ' '/current-slot:/{print $2}' | tail -n 1)"
  userspace="$(fastboot getvar is-userspace 2>&1 | awk -F': ' '/is-userspace:/{print $2}' | tail -n 1)"

  [[ "${product}" == "${PRODUCT}" ]] || { echo "Unexpected product: ${product}" >&2; exit 2; }
  [[ -n "${current_slot}" ]] || { echo "Unable to resolve current slot" >&2; exit 2; }

  if [[ "${TARGET_SLOT}" == "${current_slot}" && "${ALLOW_ACTIVE_SLOT_ROLLBACK}" != "1" ]]; then
    echo "Refusing to rollback active slot ${current_slot}. Set ALLOW_ACTIVE_SLOT_ROLLBACK=1 to override." >&2
    exit 2
  fi
fi

echo "target_product=${product}"
echo "current_slot=${current_slot}"
echo "target_slot=${TARGET_SLOT}"
echo "is_userspace_fastboot=${userspace:-unknown}"
echo "stock_super_img=${STOCK_SUPER_IMG}"
echo "stock_vbmeta_system_img=${STOCK_VBMETA_SYSTEM_IMG}"
echo "fastboot flash super ${STOCK_SUPER_IMG}"
if [[ "${FLASH_VBMETA_SYSTEM}" == "1" ]]; then
  echo "fastboot flash vbmeta_system_${TARGET_SLOT} ${STOCK_VBMETA_SYSTEM_IMG}"
fi

echo "Note: this preserves the current boot/init_boot/vendor_boot path."

if [[ "${DRY_RUN}" == "1" ]]; then
  echo "DRY_RUN=1, no flashing performed"
  exit 0
fi

fastboot flash super "${STOCK_SUPER_IMG}"
if [[ "${FLASH_VBMETA_SYSTEM}" == "1" ]]; then
  fastboot flash "vbmeta_system_${TARGET_SLOT}" "${STOCK_VBMETA_SYSTEM_IMG}"
fi
