#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
PRODUCT="${2:-myron}"
DRY_RUN="${DRY_RUN:-1}"
FLASH_VBMETA_SYSTEM="${FLASH_VBMETA_SYSTEM:-1}"
REBOOT_TO_FASTBOOTD="${REBOOT_TO_FASTBOOTD:-1}"

step() {
  printf '\n==> %s\n' "$1"
}

step "rollback userspace"
DRY_RUN="${DRY_RUN}" \
FLASH_VBMETA_SYSTEM="${FLASH_VBMETA_SYSTEM}" \
REBOOT_TO_FASTBOOTD="${REBOOT_TO_FASTBOOTD}" \
  bash "${TOP_DIR}/tools/rollback_userspace_images.sh" "${PRODUCT}"

if [[ "${DRY_RUN}" == "1" ]]; then
  echo "DRY_RUN=1, stopping before reboot"
  exit 0
fi

step "reboot"
fastboot reboot

step "verify"
adb wait-for-device
echo "Run these next:"
echo "adb shell getprop sys.boot_completed"
echo "adb shell getprop ro.build.display.id"
echo "adb shell getprop ro.boot.slot_suffix"

