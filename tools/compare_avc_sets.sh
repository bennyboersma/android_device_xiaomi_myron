#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${1:-}"
NEW_DIR="${2:-}"

if [[ -z "${BASE_DIR}" || -z "${NEW_DIR}" ]]; then
  echo "Usage: $0 <baseline_capture_dir> <new_capture_dir>" >&2
  exit 2
fi

base_file="${BASE_DIR}/avc_boot_critical.txt"
new_file="${NEW_DIR}/avc_boot_critical.txt"
base_norm_file="${BASE_DIR}/avc_boot_critical.normalized.txt"
new_norm_file="${NEW_DIR}/avc_boot_critical.normalized.txt"

[[ -f "${base_file}" ]] || { echo "Missing baseline AVC file: ${base_file}" >&2; exit 2; }
[[ -f "${new_file}" ]] || { echo "Missing new AVC file: ${new_file}" >&2; exit 2; }

normalize_if_needed() {
  local in_file="$1"
  local out_file="$2"
  if [[ -f "${out_file}" ]]; then
    return
  fi
  sed -E \
    -e "s/^.*msg='(avc:  denied .*?)'$/\1/" \
    -e 's/^.*(avc:  denied .*)$/\1/' \
    -e 's/audit\([^)]+\)//g' \
    -e 's/\b(pid|uid|gid|ino|ses|auid)=[0-9]+\b//g' \
    -e 's/  +/ /g' \
    -e 's/[[:space:]]+$//' \
    "${in_file}" | sed '/^$/d' | sort -u > "${out_file}"
}

normalize_if_needed "${base_file}" "${base_norm_file}"
normalize_if_needed "${new_file}" "${new_norm_file}"

comm -23 "${base_norm_file}" "${new_norm_file}" > "${NEW_DIR}/avc_boot_critical_resolved.txt" || true
comm -13 "${base_norm_file}" "${new_norm_file}" > "${NEW_DIR}/avc_boot_critical_new.txt" || true

echo "baseline_count=$(wc -l < "${base_norm_file}" | tr -d ' ')"
echo "new_count=$(wc -l < "${new_norm_file}" | tr -d ' ')"
echo "resolved_count=$(wc -l < "${NEW_DIR}/avc_boot_critical_resolved.txt" | tr -d ' ')"
echo "new_only_count=$(wc -l < "${NEW_DIR}/avc_boot_critical_new.txt" | tr -d ' ')"
