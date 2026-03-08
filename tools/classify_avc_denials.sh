#!/usr/bin/env bash
set -euo pipefail

INPUT_FILE="${1:-}"
OUT_DIR="${2:-}"

if [[ -z "${INPUT_FILE}" || -z "${OUT_DIR}" ]]; then
  echo "Usage: $0 <avc_denials.txt> <out_dir>" >&2
  exit 2
fi

if [[ ! -f "${INPUT_FILE}" ]]; then
  echo "Missing AVC file: ${INPUT_FILE}" >&2
  exit 2
fi

# Normalize away timestamps, audit ids, and volatile pid/ino fields so
# cross-boot comparisons reflect policy changes instead of log noise.
normalize_avc() {
  sed -E \
    -e "s/^.*msg='(avc:  denied .*?)'$/\1/" \
    -e 's/^.*(avc:  denied .*)$/\1/' \
    -e 's/audit\([^)]+\)//g' \
    -e 's/\b(pid|uid|gid|ino|ses|auid)=[0-9]+\b//g' \
    -e 's/  +/ /g' \
    -e 's/[[:space:]]+$//'
}

normalize_avc < "${INPUT_FILE}" | sed '/^$/d' | sort -u > "${OUT_DIR}/avc_denials.normalized.txt"

boot_re='vendor_init|scontext=u:r:init:s0|scontext=u:r:vendor_init:s0|scontext=u:r:tee:s0|comm="qseecomd"|scontext=u:r:vold:s0|servicemanager|hwservicemanager|surfaceflinger|system_server|audioserver|gatekeeper|keymint'

grep -Ei "${boot_re}" "${OUT_DIR}/avc_denials.normalized.txt" | grep -Eiv 'scontext=u:r:shell:s0' > "${OUT_DIR}/avc_boot_critical.txt" || true
grep -Eiv "${boot_re}" "${OUT_DIR}/avc_denials.normalized.txt" > "${OUT_DIR}/avc_deferable.txt" || true

echo "boot_critical_count=$(wc -l < "${OUT_DIR}/avc_boot_critical.txt" | tr -d ' ')"
echo "deferable_count=$(wc -l < "${OUT_DIR}/avc_deferable.txt" | tr -d ' ')"
