#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
PRODUCT="${2:-myron}"

step() {
  printf '\n==> %s\n' "$1"
}

step "boot-critical vendor outputs"
bash "${TOP_DIR}/tools/check_retry_boot_critical_vendor_stack.sh" "${TOP_DIR}" "${PRODUCT}"

step "userspace flash readiness"
CHECK_ROLLBACK=1 REQUIRE_DEVICE=0 bash "${TOP_DIR}/tools/check_userspace_flash_readiness.sh" "${TOP_DIR}" "${PRODUCT}"

step "partition sanity"
bash "${TOP_DIR}/tools/check_partition_package_sanity.sh" "${TOP_DIR}" "${PRODUCT}"

step "artifact audit"
bash "${TOP_DIR}/tools/audit_userspace_outputs.sh" "${TOP_DIR}" "${PRODUCT}"
