#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
PRODUCT="${2:-myron}"
BASELINE_DIR="${3:-${TOP_DIR}/_checkpoints/phone_baseline_20260304_121337}"
DRY_RUN="${DRY_RUN:-1}"
DWELL_SECONDS="${DWELL_SECONDS:-900}"
FLASH_VBMETA_SYSTEM="${FLASH_VBMETA_SYSTEM:-0}"
USE_SUPER="${USE_SUPER:-0}"

step() {
  printf '\n==> %s\n' "$1"
}

step "readiness"
CHECK_ROLLBACK=1 REQUIRE_DEVICE=0 bash "${TOP_DIR}/tools/check_userspace_flash_readiness.sh" "${TOP_DIR}" "${PRODUCT}"

step "partition sanity"
bash "${TOP_DIR}/tools/check_partition_package_sanity.sh" "${TOP_DIR}" "${PRODUCT}"

step "flash dry-run"
DRY_RUN=1 REBOOT_TO_FASTBOOTD=1 USE_SUPER="${USE_SUPER}" FLASH_VBMETA_SYSTEM="${FLASH_VBMETA_SYSTEM}" \
  bash "${TOP_DIR}/tools/flash_userspace_images.sh" "${TOP_DIR}" "${PRODUCT}"

if [[ "${DRY_RUN}" == "1" ]]; then
  echo "DRY_RUN=1, stopping before real flash"
  exit 0
fi

step "flash"
DRY_RUN=0 REBOOT_TO_FASTBOOTD=1 USE_SUPER="${USE_SUPER}" FLASH_VBMETA_SYSTEM="${FLASH_VBMETA_SYSTEM}" \
  bash "${TOP_DIR}/tools/flash_userspace_images.sh" "${TOP_DIR}" "${PRODUCT}"
fastboot reboot

step "capture"
adb wait-for-device
DWELL_SECONDS="${DWELL_SECONDS}" bash "${TOP_DIR}/tools/first_boot_capture_and_diff.sh" "${TOP_DIR}" "${BASELINE_DIR}"

LATEST_CAPTURE="$(find "${TOP_DIR}/_checkpoints" -maxdepth 1 -type d -name 'firstboot_*' | sort | tail -n 1)"
if [[ -n "${LATEST_CAPTURE}" && -x "${TOP_DIR}/tools/summarize_first_userspace_result.sh" ]]; then
  step "summary"
  bash "${TOP_DIR}/tools/summarize_first_userspace_result.sh" "${LATEST_CAPTURE}"
fi

step "done"
echo "Inspect latest firstboot_* capture and apply tools/runbooks/first_userspace_triage_checklist.md"
