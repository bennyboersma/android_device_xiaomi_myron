#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
PRODUCT="${2:-myron}"

OUT_DIR="${TOP_DIR}/out/target/product/${PRODUCT}"
HOST_BIN_DIR="${TOP_DIR}/out/host/linux-x86/bin"
WORK_DIR="${TOP_DIR}/_checkpoints/partition_provenance_super_${PRODUCT}_$(date +%Y%m%d_%H%M%S)"
OUTPUT_IMG="${OUTPUT_IMG:-${OUT_DIR}/super_partition_provenance.img}"
PATCHED_SYSTEM_IMG="${PATCHED_SYSTEM_IMG:-${OUT_DIR}/system_partition_provenance.img}"
PATCHED_SYSTEM_EXT_IMG="${PATCHED_SYSTEM_EXT_IMG:-${OUT_DIR}/system_ext_partition_provenance.img}"
PATCHED_PRODUCT_IMG="${PATCHED_PRODUCT_IMG:-${OUT_DIR}/product_partition_provenance.img}"
SYSTEM_DIR="${SYSTEM_DIR:-${OUT_DIR}/system}"
SYSTEM_EXT_IMG="${SYSTEM_EXT_IMG:-${OUT_DIR}/system_ext_boot_priority.img}"
PRODUCT_IMG="${PRODUCT_IMG:-${OUT_DIR}/product_boot_priority.img}"
VENDOR_IMG="${VENDOR_IMG:-${OUT_DIR}/vendor.img}"
ODM_IMG="${ODM_IMG:-${OUT_DIR}/odm.img}"
VENDOR_DLKM_IMG="${VENDOR_DLKM_IMG:-${OUT_DIR}/vendor_dlkm.img}"
MI_EXT_IMG="${MI_EXT_IMG:-${TOP_DIR}/_transfer/rollback_wpm_eu/mi_ext.img}"
SYSTEM_DLKM_IMG="${SYSTEM_DLKM_IMG:-${OUT_DIR}/system_dlkm.img}"
MKFS_EROFS="${MKFS_EROFS:-${HOST_BIN_DIR}/mkfs.erofs}"
FSCK_EROFS="${FSCK_EROFS:-${HOST_BIN_DIR}/fsck.erofs}"

PRODUCT_MARKER_REL="etc/myron_partition_provenance_marker.txt"
SYSTEM_EXT_MARKER_REL="etc/myron_partition_provenance_marker.txt"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

EXPECTED_REMOVALS=(
  "/product/app/MIUICloudServiceGlobal"
  "/product/app/MIUIMiCloudSync"
  "/product/priv-app/MIUISecurityCenterGlobal"
  "/product/app/MIUISecurityAdd"
  "/product/app/MIUIFileExplorerGlobal"
  "/system_ext/priv-app/FindDevice"
)

need_file() {
  [[ -f "$1" ]] || {
    echo "Missing file: $1" >&2
    exit 2
  }
}

need_dir() {
  [[ -d "$1" ]] || {
    echo "Missing directory: $1" >&2
    exit 2
  }
}

need_dir "${SYSTEM_DIR}"

for f in \
  "${SYSTEM_EXT_IMG}" \
  "${PRODUCT_IMG}" \
  "${VENDOR_IMG}" \
  "${ODM_IMG}" \
  "${VENDOR_DLKM_IMG}" \
  "${MI_EXT_IMG}" \
  "${SYSTEM_DLKM_IMG}" \
  "${MKFS_EROFS}" \
  "${FSCK_EROFS}" \
  "${TOP_DIR}/tools/repack_super_stock_layout_myron.sh"
do
  need_file "$f"
done

mkdir -p "${WORK_DIR}"
rm -rf "${WORK_DIR}/system" "${WORK_DIR}/system_ext" "${WORK_DIR}/product"
cp -a "${SYSTEM_DIR}" "${WORK_DIR}/system"
"${FSCK_EROFS}" --extract="${WORK_DIR}/system_ext" "${SYSTEM_EXT_IMG}" >/dev/null
"${FSCK_EROFS}" --extract="${WORK_DIR}/product" "${PRODUCT_IMG}" >/dev/null

cat > "${WORK_DIR}/product/${PRODUCT_MARKER_REL}" <<EOF
variant=partition_provenance
timestamp_utc=${TIMESTAMP}
expected_source=/product
base_product_img=${PRODUCT_IMG}
expected_removed_paths=$(IFS=,; echo "${EXPECTED_REMOVALS[*]}")
EOF

cat > "${WORK_DIR}/system_ext/${SYSTEM_EXT_MARKER_REL}" <<EOF
variant=partition_provenance
timestamp_utc=${TIMESTAMP}
expected_source=/system_ext
base_system_ext_img=${SYSTEM_EXT_IMG}
expected_removed_paths=$(IFS=,; echo "${EXPECTED_REMOVALS[*]}")
EOF

{
  printf 'output_img=%s\n' "${OUTPUT_IMG}"
  printf 'patched_system_img=%s\n' "${PATCHED_SYSTEM_IMG}"
  printf 'patched_system_ext_img=%s\n' "${PATCHED_SYSTEM_EXT_IMG}"
  printf 'patched_product_img=%s\n' "${PATCHED_PRODUCT_IMG}"
  printf 'system_dir=%s\n' "${SYSTEM_DIR}"
  printf 'base_system_ext_img=%s\n' "${SYSTEM_EXT_IMG}"
  printf 'base_product_img=%s\n' "${PRODUCT_IMG}"
  printf 'product_marker=%s\n' "/product/${PRODUCT_MARKER_REL}"
  printf 'system_ext_marker=%s\n' "/system_ext/${SYSTEM_EXT_MARKER_REL}"
  printf 'timestamp_utc=%s\n' "${TIMESTAMP}"
  for path in "${EXPECTED_REMOVALS[@]}"; do
    printf 'expected_removed_path=%s\n' "${path}"
  done
} | tee "${WORK_DIR}/summary.txt"

rm -f "${PATCHED_SYSTEM_IMG}" "${PATCHED_SYSTEM_EXT_IMG}" "${PATCHED_PRODUCT_IMG}"
"${MKFS_EROFS}" \
  --product-out="${OUT_DIR}" \
  --mount-point=/ \
  -b 4096 \
  -z lz4hc,9 \
  -T 0 \
  "${PATCHED_SYSTEM_IMG}" \
  "${WORK_DIR}/system" \
  | tee -a "${WORK_DIR}/summary.txt"

"${MKFS_EROFS}" \
  --product-out="${OUT_DIR}" \
  --mount-point=/ \
  -b 4096 \
  -z lz4hc,9 \
  -T 0 \
  "${PATCHED_SYSTEM_EXT_IMG}" \
  "${WORK_DIR}/system_ext" \
  | tee -a "${WORK_DIR}/summary.txt"

"${MKFS_EROFS}" \
  --product-out="${OUT_DIR}" \
  --mount-point=/ \
  -b 4096 \
  -z lz4hc,9 \
  -T 0 \
  "${PATCHED_PRODUCT_IMG}" \
  "${WORK_DIR}/product" \
  | tee -a "${WORK_DIR}/summary.txt"

TRIM_SYSTEM_FROM_DIR=0 \
SYSTEM_IMG="${PATCHED_SYSTEM_IMG}" \
SYSTEM_EXT_IMG="${PATCHED_SYSTEM_EXT_IMG}" \
PRODUCT_IMG="${PATCHED_PRODUCT_IMG}" \
VENDOR_IMG="${VENDOR_IMG}" \
ODM_IMG="${ODM_IMG}" \
VENDOR_DLKM_IMG="${VENDOR_DLKM_IMG}" \
MI_EXT_IMG="${MI_EXT_IMG}" \
SYSTEM_DLKM_IMG="${SYSTEM_DLKM_IMG}" \
OUTPUT_SUPER="${OUTPUT_IMG}" \
bash "${TOP_DIR}/tools/repack_super_stock_layout_myron.sh" "${TOP_DIR}" "${PRODUCT}" \
  | tee -a "${WORK_DIR}/summary.txt"
