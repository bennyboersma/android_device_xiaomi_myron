#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
PRODUCT="${2:-myron}"
APPLY_PROACTIVE_PRUNE="${APPLY_PROACTIVE_PRUNE:-1}"
JOBS="${JOBS:-10}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

step() {
  printf '\n==> %s\n' "$1"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing host tool: $1" >&2
    exit 2
  }
}

need_cmd bash
need_cmd python3
need_cmd tee

if [[ "${APPLY_PROACTIVE_PRUNE}" == "1" ]]; then
  step "apply proactive retry-prep prune"
  python3 "${SCRIPT_DIR}/prune_generated_vendor_modules.py" \
    "${TOP_DIR}/vendor/xiaomi/myron/Android.bp" \
    --file "${SCRIPT_DIR}/retry_prep_drop_modules.txt" \
    --keep-file "${SCRIPT_DIR}/retry_prep_keep_modules.txt"

  prefix_args=()
  while IFS= read -r prefix; do
    [[ -n "${prefix}" ]] || continue
    [[ "${prefix}" =~ ^# ]] && continue
    prefix_args+=(--prefix "${prefix}")
  done < "${SCRIPT_DIR}/retry_prep_drop_prefixes.txt"

  if [[ ${#prefix_args[@]} -ne 0 ]]; then
    python3 "${SCRIPT_DIR}/prune_generated_vendor_modules.py" \
      "${TOP_DIR}/vendor/xiaomi/myron/Android.bp" \
      "${prefix_args[@]}" \
      --keep-file "${SCRIPT_DIR}/retry_prep_keep_modules.txt"
  fi
fi

run_gate1_build() {
  local log_path="$1"
  set +e
  m nothing -j"${JOBS}" 2>&1 | tee "${log_path}"
  local build_rc=${PIPESTATUS[0]}
  set -e
  return "${build_rc}"
}

step "gate 1"
set +u
source "${TOP_DIR}/build/envsetup.sh" >/dev/null
lunch "lineage_${PRODUCT}-trunk_staging-userdebug" >/dev/null
set -u

gate1_log="$(mktemp)"
if run_gate1_build "${gate1_log}"; then
  rm -f "${gate1_log}"
  exit 0
fi

if grep -q "includes non-existent modules in PRODUCT_PACKAGES" "${gate1_log}"; then
  missing_packages="$(mktemp)"
  awk '
    /Offending entries:/ { capture=1; next }
    capture && /^build\/make\/core\/main\.mk:1074: error: Build failed\.$/ { capture=0; next }
    capture && NF { print }
  ' "${gate1_log}" | awk '!seen[$0]++' > "${missing_packages}"

  if [[ -s "${missing_packages}" ]]; then
    step "prune unresolved generated PRODUCT_PACKAGES"
    python3 "${SCRIPT_DIR}/prune_generated_vendor_product_packages.py" \
      "${TOP_DIR}/vendor/xiaomi/myron/myron-vendor.mk" \
      --file "${missing_packages}"

    rm -f "${gate1_log}"
    gate1_log="$(mktemp)"
    if run_gate1_build "${gate1_log}"; then
      rm -f "${gate1_log}" "${missing_packages}"
      exit 0
    fi
  fi

  rm -f "${missing_packages}"
fi

cat "${gate1_log}" >&2
rm -f "${gate1_log}"
exit 1
