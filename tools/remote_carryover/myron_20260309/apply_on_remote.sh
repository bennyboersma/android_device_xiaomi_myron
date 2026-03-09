#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES_DIR="${BUNDLE_DIR}/files"

copy_file() {
  local rel="$1"
  local src="${FILES_DIR}/${rel}"
  local dst="${TOP_DIR}/${rel}"
  [[ -f "${src}" ]] || {
    echo "Missing bundle file: ${src}" >&2
    exit 2
  }
  mkdir -p "$(dirname "${dst}")"
  cp "${src}" "${dst}"
  echo "[applied] ${rel}"
}

copy_file "hardware/qcom-caf/common/BoardConfigQcom.mk"
copy_file "hardware/qcom-caf/kaanapali/display/hal/config/display-product.mk"
copy_file "hardware/qcom-caf/kaanapali/display/hal/services/config/src/Android.bp"
copy_file "hardware/qcom-caf/kaanapali/display/core/sde-drm/drm_panel_feature_mgr.cpp"
copy_file "hardware/qcom-caf/kaanapali/display/hal/gralloc/Android.bp"
copy_file "hardware/qcom-caf/kaanapali/display/core/snapalloc/Android.bp"
copy_file "vendor/xiaomi/myron/Android.bp"
copy_file "vendor/xiaomi/sm8850-common/Android.bp"

echo "[done] carryover files copied into ${TOP_DIR}"

