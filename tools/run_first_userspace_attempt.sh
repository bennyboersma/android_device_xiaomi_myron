#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
PRODUCT="${2:-myron}"
BASELINE_DIR="${3:-${TOP_DIR}/_checkpoints/phone_baseline_20260304_121337}"
DRY_RUN="${DRY_RUN:-1}"
DWELL_SECONDS="${DWELL_SECONDS:-900}"
FLASH_VBMETA_SYSTEM="${FLASH_VBMETA_SYSTEM:-0}"
USE_SUPER="${USE_SUPER:-0}"
ADB_WAIT_SECONDS="${ADB_WAIT_SECONDS:-180}"
ATTEMPT_DIR="${TOP_DIR}/_checkpoints/first_userspace_attempt_$(date +%Y%m%d_%H%M%S)"

step() {
  printf '\n==> %s\n' "$1"
}

capture_fastboot_state() {
  mkdir -p "${ATTEMPT_DIR}"
  if command -v fastboot >/dev/null 2>&1 && fastboot devices | awk 'NF {print $1}' | grep -q .; then
    fastboot getvar product > "${ATTEMPT_DIR}/fastboot_product.txt" 2>&1 || true
    fastboot getvar current-slot > "${ATTEMPT_DIR}/fastboot_current_slot.txt" 2>&1 || true
    fastboot getvar is-userspace > "${ATTEMPT_DIR}/fastboot_is_userspace.txt" 2>&1 || true
    fastboot getvar slot-successful:a > "${ATTEMPT_DIR}/fastboot_slot_successful_a.txt" 2>&1 || true
    fastboot getvar slot-successful:b > "${ATTEMPT_DIR}/fastboot_slot_successful_b.txt" 2>&1 || true
    fastboot getvar slot-unbootable:a > "${ATTEMPT_DIR}/fastboot_slot_unbootable_a.txt" 2>&1 || true
    fastboot getvar slot-unbootable:b > "${ATTEMPT_DIR}/fastboot_slot_unbootable_b.txt" 2>&1 || true
    fastboot getvar slot-retry-count:a > "${ATTEMPT_DIR}/fastboot_slot_retry_count_a.txt" 2>&1 || true
    fastboot getvar slot-retry-count:b > "${ATTEMPT_DIR}/fastboot_slot_retry_count_b.txt" 2>&1 || true
  fi
}

capture_preflash_state() {
  mkdir -p "${ATTEMPT_DIR}"
  if command -v adb >/dev/null 2>&1 && adb get-state >/dev/null 2>&1; then
    adb shell getprop > "${ATTEMPT_DIR}/preflash_getprop.txt" || true
    adb shell service list > "${ATTEMPT_DIR}/preflash_service_list.txt" || true
  fi
  capture_fastboot_state
}

wait_for_adb_with_timeout() {
  local waited=0
  while (( waited < ADB_WAIT_SECONDS )); do
    if command -v adb >/dev/null 2>&1 && adb get-state >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done
  return 1
}

step "capture preflash baseline"
capture_preflash_state

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
if ! wait_for_adb_with_timeout; then
  echo "ADB did not come up within ${ADB_WAIT_SECONDS}s" | tee "${ATTEMPT_DIR}/failure_reason.txt"
  capture_fastboot_state
  echo "Attempt artifacts saved to ${ATTEMPT_DIR}"
  exit 3
fi
DWELL_SECONDS="${DWELL_SECONDS}" bash "${TOP_DIR}/tools/first_boot_capture_and_diff.sh" "${TOP_DIR}" "${BASELINE_DIR}"

LATEST_CAPTURE="$(find "${TOP_DIR}/_checkpoints" -maxdepth 1 -type d -name 'firstboot_*' | sort | tail -n 1)"
if [[ -n "${LATEST_CAPTURE}" && -x "${TOP_DIR}/tools/summarize_first_userspace_result.sh" ]]; then
  step "summary"
  bash "${TOP_DIR}/tools/summarize_first_userspace_result.sh" "${LATEST_CAPTURE}"
fi

step "done"
echo "Inspect latest firstboot_* capture and apply tools/runbooks/first_userspace_triage_checklist.md"
