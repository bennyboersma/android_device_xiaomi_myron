#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
PRODUCT="${2:-myron}"
OUT_DIR="${TOP_DIR}/out/target/product/${PRODUCT}"
MANIFEST_FILE="${MANIFEST_FILE:-${TOP_DIR}/tools/userspace_image_manifest.txt}"

step() {
  printf '\n==> %s\n' "$1"
}

[[ -f "${MANIFEST_FILE}" ]] || {
  echo "Missing manifest: ${MANIFEST_FILE}" >&2
  exit 2
}

step "readiness"
CHECK_ROLLBACK=1 REQUIRE_DEVICE=0 bash "${TOP_DIR}/tools/check_userspace_flash_readiness.sh" "${TOP_DIR}" "${PRODUCT}" || true

step "partition sanity"
bash "${TOP_DIR}/tools/check_partition_package_sanity.sh" "${TOP_DIR}" "${PRODUCT}" || true

step "boot-critical vendor stack"
bash "${TOP_DIR}/tools/check_retry_boot_critical_vendor_stack.sh" "${TOP_DIR}" "${PRODUCT}" || true

step "artifacts"
while read -r kind image; do
  [[ -n "${kind}" ]] || continue
  [[ "${kind}" =~ ^# ]] && continue
  path="${OUT_DIR}/${image}"
  if [[ -f "${path}" ]]; then
    printf '[%s] ' "${kind}"
    ls -lh "${path}"
  else
    printf '[missing:%s] %s\n' "${kind}" "${path}"
  fi
done < "${MANIFEST_FILE}"

step "dry-run flash plan"
DRY_RUN=1 REBOOT_TO_FASTBOOTD=1 bash "${TOP_DIR}/tools/flash_userspace_images.sh" "${TOP_DIR}" "${PRODUCT}" || true
