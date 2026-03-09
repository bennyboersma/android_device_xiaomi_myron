#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
PRODUCT="${2:-myron}"
OUT_DIR="${TOP_DIR}/out/target/product/${PRODUCT}"

step() {
  printf '\n==> %s\n' "$1"
}

step "readiness"
CHECK_ROLLBACK=1 REQUIRE_DEVICE=0 bash "${TOP_DIR}/tools/check_userspace_flash_readiness.sh" "${TOP_DIR}" "${PRODUCT}" || true

step "partition sanity"
bash "${TOP_DIR}/tools/check_partition_package_sanity.sh" "${TOP_DIR}" "${PRODUCT}" || true

step "artifacts"
for image in \
  system.img \
  system_ext.img \
  product.img \
  vendor.img \
  odm.img \
  vendor_dlkm.img \
  system_dlkm.img \
  vbmeta_system.img \
  super.img; do
  path="${OUT_DIR}/${image}"
  if [[ -f "${path}" ]]; then
    ls -lh "${path}"
  else
    echo "[missing] ${path}"
  fi
done

step "dry-run flash plan"
DRY_RUN=1 REBOOT_TO_FASTBOOTD=1 bash "${TOP_DIR}/tools/flash_userspace_images.sh" "${TOP_DIR}" "${PRODUCT}" || true

