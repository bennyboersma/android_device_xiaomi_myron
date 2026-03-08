#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
PRODUCT="${2:-myron}"
OUT_DIR="${TOP_DIR}/out/target/product/${PRODUCT}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQUIRE_DEVICE="${REQUIRE_DEVICE:-0}"
CHECK_ROLLBACK="${CHECK_ROLLBACK:-1}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing host tool: $1" >&2
    exit 2
  }
}

need_cmd awk
need_cmd rg

images=(
  system.img
  system_ext.img
  product.img
  vendor.img
  odm.img
  vendor_dlkm.img
  system_dlkm.img
)

missing=0

echo "[artifacts] out_dir=${OUT_DIR}"
for image in "${images[@]}"; do
  path="${OUT_DIR}/${image}"
  if [[ -f "${path}" ]]; then
    printf '[ok] %s\n' "${path}"
  else
    printf '[missing] %s\n' "${path}"
    missing=$((missing + 1))
  fi
done

if [[ -f "${OUT_DIR}/vbmeta_system.img" ]]; then
  printf '[ok] %s\n' "${OUT_DIR}/vbmeta_system.img"
else
  printf '[info] optional missing: %s\n' "${OUT_DIR}/vbmeta_system.img"
fi

if [[ "${CHECK_ROLLBACK}" == "1" ]]; then
  need_cmd bash
  echo "[rollback] probing rollback helper defaults"
  DRY_RUN=1 REQUIRE_DEVICE=0 bash "${SCRIPT_DIR}/rollback_userspace_images.sh" "${PRODUCT}" >/tmp/rollback_userspace_readiness.$$ 2>&1 || true
  cat /tmp/rollback_userspace_readiness.$$
  if rg -q '^Missing stock super image:' /tmp/rollback_userspace_readiness.$$; then
    echo "[rollback] stock userspace assets are not staged on this host yet" >&2
    missing=$((missing + 1))
  fi
  rm -f /tmp/rollback_userspace_readiness.$$
fi

if [[ "${REQUIRE_DEVICE}" == "1" ]]; then
  need_cmd fastboot
  product="$(fastboot getvar product 2>&1 | awk -F': ' '/product:/{print $2}' | tail -n 1)"
  slot="$(fastboot getvar current-slot 2>&1 | awk -F': ' '/current-slot:/{print $2}' | tail -n 1)"
  userspace="$(fastboot getvar is-userspace 2>&1 | awk -F': ' '/is-userspace:/{print $2}' | tail -n 1)"
  printf '[device] product=%s slot=%s is_userspace=%s\n' "${product:-unknown}" "${slot:-unknown}" "${userspace:-unknown}"
  [[ "${product}" == "${PRODUCT}" ]] || {
    echo "[device] unexpected product: ${product}" >&2
    exit 2
  }
fi

if [[ ${missing} -ne 0 ]]; then
  echo "[result] FAIL missing_count=${missing}" >&2
  exit 1
fi

echo "[result] PASS"
