#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
PRODUCT="${2:-myron}"

OUT_DIR="${TOP_DIR}/out/target/product/${PRODUCT}"
STOCK_SUPER_IMG="${STOCK_SUPER:-${TOP_DIR}/_transfer/rollback_wpm_eu/stock_userspace_20260308/super.img}"
WORK_DIR="${TOP_DIR}/_checkpoints/stock_product_miui_restore_super_${PRODUCT}_$(date +%Y%m%d_%H%M%S)"
STOCK_RAW="${WORK_DIR}/stock_super.raw"
UNPACK_DIR="${WORK_DIR}/stock_unpacked"
PATCH_ROOT="${WORK_DIR}/product_patch"
STOCK_PRODUCT_FS="${WORK_DIR}/stock_product_fs"
CUSTOM_PRODUCT_FS="${WORK_DIR}/custom_product_fs"
PATCHED_PRODUCT_IMG="${OUT_DIR}/product_stock_miui_restore.img"
OUTPUT_IMG="${OUTPUT_IMG:-${OUT_DIR}/super_stock_product_miui_restore.img}"
LPUNPACK_BIN="${LPUNPACK_BIN:-${TOP_DIR}/out/host/linux-x86/bin/lpunpack}"
SIMG2IMG_BIN="${SIMG2IMG_BIN:-${TOP_DIR}/out/host/linux-x86/bin/simg2img}"
MKFS_EROFS_BIN="${MKFS_EROFS_BIN:-$(command -v mkfs.erofs || true)}"

RESTORE_PATHS=(
  "pangu/system"
  "priv-app/MIUISecurityCenterGlobal"
  "priv-app/MISettings"
  "priv-app/MIServiceGlobal"
  "app/MIUIGlobalLayout"
  "app/MIUISecurityAdd"
  "app/MIUISystemUIPlugin"
  "overlay/MiuiFrameworkResOverlay.apk"
  "overlay/MiuiPermissionControllerOverlay.apk"
  "overlay/MiuiPowerInsightOverlay.apk"
  "overlay/MiuiServiceOverlay"
  "overlay/SafetyCenterMiuiConfigOverlay.apk"
  "overlay/SafetyCenterMiuiOverlay.apk"
)

REMOVE_PATHS=(
  "app/MIUISecurityCenterGlobal"
)

need_file() {
  [[ -f "$1" ]] || {
    echo "Missing file: $1" >&2
    exit 2
  }
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing host tool: $1" >&2
    exit 2
  }
}

extract_partition() {
  local img="$1"
  local dest="$2"
  local kind

  mkdir -p "${dest}"
  kind="$(file -b "${img}")"

  if [[ "${kind}" == Android\ sparse\ image* ]]; then
    local raw_img="${img}.raw"
    "${SIMG2IMG_BIN}" "${img}" "${raw_img}" >/dev/null
    extract_partition "${raw_img}" "${dest}"
    rm -f "${raw_img}"
    return 0
  fi

  if [[ "${kind}" == EROFS\ filesystem* ]]; then
    fsck.erofs --extract="${dest}" --no-preserve "${img}" >/dev/null
    return 0
  fi

  if [[ "${kind}" == Linux\ rev*filesystem* || "${kind}" == Linux\ extended\ file* ]]; then
    debugfs -R "rdump / ${dest}" "${img}" >/dev/null 2>&1
    return 0
  fi

  echo "Unsupported filesystem image: ${img} (${kind})" >&2
  exit 2
}

copy_stock_path() {
  local rel="$1"
  local src="${STOCK_PRODUCT_FS}/${rel}"
  local dest="${PATCH_ROOT}/${rel}"

  [[ -e "${src}" ]] || {
    echo "Missing stock restore path: ${src}" >&2
    exit 2
  }

  rm -rf "${dest}"
  mkdir -p "$(dirname "${dest}")"
  cp -a "${src}" "${dest}"
}

need_cmd file
need_cmd fsck.erofs
need_cmd debugfs
need_file "${STOCK_SUPER_IMG}"
need_file "${TOP_DIR}/tools/repack_super_stock_layout_myron.sh"
need_file "${LPUNPACK_BIN}"
need_file "${SIMG2IMG_BIN}"
need_file "${OUT_DIR}/product.img"
[[ -n "${MKFS_EROFS_BIN}" ]] || {
  echo "Missing mkfs.erofs; set MKFS_EROFS_BIN or install erofs-utils" >&2
  exit 2
}

mkdir -p "${WORK_DIR}" "${UNPACK_DIR}"

stock_kind="$(file -b "${STOCK_SUPER_IMG}")"
if [[ "${stock_kind}" == Android\ sparse\ image* ]]; then
  "${SIMG2IMG_BIN}" "${STOCK_SUPER_IMG}" "${STOCK_RAW}" >/dev/null
else
  cp "${STOCK_SUPER_IMG}" "${STOCK_RAW}"
fi
"${LPUNPACK_BIN}" "${STOCK_RAW}" "${UNPACK_DIR}" >/dev/null

for img in \
  system_a.img \
  system_ext_a.img \
  product_a.img \
  vendor_a.img \
  odm_a.img \
  vendor_dlkm_a.img \
  system_dlkm_a.img \
  mi_ext_a.img
do
  need_file "${UNPACK_DIR}/${img}"
done

extract_partition "${UNPACK_DIR}/product_a.img" "${STOCK_PRODUCT_FS}"
extract_partition "${OUT_DIR}/product.img" "${CUSTOM_PRODUCT_FS}"

rm -rf "${PATCH_ROOT}"
mkdir -p "${PATCH_ROOT}"
cp -a "${CUSTOM_PRODUCT_FS}/." "${PATCH_ROOT}/"

for rel in "${REMOVE_PATHS[@]}"; do
  rm -rf "${PATCH_ROOT}/${rel}"
done

for rel in "${RESTORE_PATHS[@]}"; do
  copy_stock_path "${rel}"
done

rm -f "${PATCHED_PRODUCT_IMG}"
"${MKFS_EROFS_BIN}" -z lz4hc "${PATCHED_PRODUCT_IMG}" "${PATCH_ROOT}" >/dev/null

printf 'stock_super=%s\n' "${STOCK_SUPER_IMG}" | tee "${WORK_DIR}/summary.txt"
printf 'stock_super_kind=%s\n' "${stock_kind}" | tee -a "${WORK_DIR}/summary.txt"
printf 'output_img=%s\n' "${OUTPUT_IMG}" | tee -a "${WORK_DIR}/summary.txt"
printf 'patched_product_img=%s\n' "${PATCHED_PRODUCT_IMG}" | tee -a "${WORK_DIR}/summary.txt"
printf 'using_stock_system=%s\n' "${UNPACK_DIR}/system_a.img" | tee -a "${WORK_DIR}/summary.txt"
printf 'using_stock_system_ext=%s\n' "${UNPACK_DIR}/system_ext_a.img" | tee -a "${WORK_DIR}/summary.txt"
printf 'using_patched_product=%s\n' "${PATCHED_PRODUCT_IMG}" | tee -a "${WORK_DIR}/summary.txt"
printf 'using_stock_system_dlkm=%s\n' "${UNPACK_DIR}/system_dlkm_a.img" | tee -a "${WORK_DIR}/summary.txt"
printf 'using_stock_vendor=%s\n' "${UNPACK_DIR}/vendor_a.img" | tee -a "${WORK_DIR}/summary.txt"
printf 'using_stock_odm=%s\n' "${UNPACK_DIR}/odm_a.img" | tee -a "${WORK_DIR}/summary.txt"
printf 'using_stock_vendor_dlkm=%s\n' "${UNPACK_DIR}/vendor_dlkm_a.img" | tee -a "${WORK_DIR}/summary.txt"
printf 'using_stock_mi_ext=%s\n' "${UNPACK_DIR}/mi_ext_a.img" | tee -a "${WORK_DIR}/summary.txt"
for rel in "${RESTORE_PATHS[@]}"; do
  printf 'restored_path=%s\n' "${rel}" | tee -a "${WORK_DIR}/summary.txt"
done

TRIM_SYSTEM_FROM_DIR=0 \
SYSTEM_IMG="${UNPACK_DIR}/system_a.img" \
SYSTEM_EXT_IMG="${UNPACK_DIR}/system_ext_a.img" \
PRODUCT_IMG="${PATCHED_PRODUCT_IMG}" \
VENDOR_IMG="${UNPACK_DIR}/vendor_a.img" \
ODM_IMG="${UNPACK_DIR}/odm_a.img" \
VENDOR_DLKM_IMG="${UNPACK_DIR}/vendor_dlkm_a.img" \
SYSTEM_DLKM_IMG="${UNPACK_DIR}/system_dlkm_a.img" \
STOCK_MI_EXT_IMG="${UNPACK_DIR}/mi_ext_a.img" \
OUTPUT_IMG="${OUTPUT_IMG}" \
  bash "${TOP_DIR}/tools/repack_super_stock_layout_myron.sh" "${TOP_DIR}" "${PRODUCT}" | tee -a "${WORK_DIR}/summary.txt"

printf 'work_dir=%s\n' "${WORK_DIR}" | tee -a "${WORK_DIR}/summary.txt"
