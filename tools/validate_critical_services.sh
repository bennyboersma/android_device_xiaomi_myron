#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
PRODUCT="${2:-myron}"
MODE="${3:-auto}"
OUT_DIR="${TOP_DIR}/out/target/product/${PRODUCT}"
MARKERS_FILE="${TOP_DIR}/tools/boot_critical_markers.txt"

if [[ ! -d "${TOP_DIR}" ]]; then
  echo "E: TOP_DIR not found: ${TOP_DIR}" >&2
  exit 2
fi

if [[ ! -f "${MARKERS_FILE}" ]]; then
  echo "E: Missing markers file: ${MARKERS_FILE}" >&2
  exit 2
fi

echo "[info] TOP_DIR=${TOP_DIR}"
echo "[info] PRODUCT=${PRODUCT}"
echo "[info] OUT_DIR=${OUT_DIR}"
echo "[info] MODE=${MODE}"

declare -a RC_FILES
mapfile -t RC_FILES < <(find "${TOP_DIR}/device/xiaomi" "${TOP_DIR}/vendor/xiaomi" -type f -name '*.rc' 2>/dev/null | sort)
declare -a VINTF_FILES
mapfile -t VINTF_FILES < <(find "${TOP_DIR}/device/xiaomi" "${TOP_DIR}/vendor/xiaomi" -type f \( -name 'manifest*.xml' -o -name '*compatibility_matrix*.xml' \) 2>/dev/null | sort)

if [[ ${#RC_FILES[@]} -eq 0 ]]; then
  echo "W: no rc files found under device/vendor trees"
fi

echo "[check] service binary references in rc files"
missing_bins=0
checked_bins=0
bin_check_enabled=1

if [[ "${MODE}" == "structural" ]]; then
  bin_check_enabled=0
  echo "[warn] structural mode selected; skipping binary existence checks"
elif [[ ! -d "${OUT_DIR}/vendor" && ! -d "${OUT_DIR}/system" && ! -d "${OUT_DIR}/odm" ]]; then
  echo "[warn] product output tree is not populated yet; skipping binary existence checks"
  echo "[warn] run after broader build to enable binary existence validation"
  bin_check_enabled=0
fi

while IFS= read -r path; do
  [[ -z "${path}" || "${path}" =~ ^# ]] && continue
  if [[ "${path}" != vendor/bin/* && "${path}" != system/bin/* && "${path}" != odm/bin/* ]]; then
    continue
  fi
  ((checked_bins+=1))
  if [[ ${bin_check_enabled} -eq 1 ]]; then
    rel="${path#/}"
    base="${OUT_DIR}/${rel}"
    vend_alt="${OUT_DIR}/vendor/${rel}"
    if [[ -e "${base}" || -e "${vend_alt}" ]]; then
      continue
    fi
    echo "MISSING_BIN ${path}"
    ((missing_bins+=1))
  fi
done < <(awk '
  $1=="service" {
    for (i=3;i<=NF;i++) {
      if ($i ~ /^\// || $i ~ /^(vendor|system|odm)\/bin\//) {
        gsub(/^\//, "", $i);
        print $i;
        break;
      }
    }
  }
' "${RC_FILES[@]}" | sort -u)

echo "[check] critical marker coverage in rc/vintf"
missing_markers=0
present_markers=0

while IFS= read -r marker; do
  [[ -z "${marker}" || "${marker}" =~ ^# ]] && continue
  found=0
  if [[ ${#RC_FILES[@]} -gt 0 ]] && grep -Rqs -- "${marker}" "${RC_FILES[@]}" 2>/dev/null; then
    found=1
  elif [[ ${#VINTF_FILES[@]} -gt 0 ]] && grep -Rqs -- "${marker}" "${VINTF_FILES[@]}" 2>/dev/null; then
    found=1
  fi

  if [[ ${found} -eq 1 ]]; then
    ((present_markers+=1))
  else
    echo "MISSING_MARKER ${marker}"
    ((missing_markers+=1))
  fi
done < "${MARKERS_FILE}"

echo
echo "[summary]"
echo "checked_rc_bins=${checked_bins}"
echo "missing_rc_bins=${missing_bins}"
echo "bin_check_enabled=${bin_check_enabled}"
echo "present_markers=${present_markers}"
echo "missing_markers=${missing_markers}"

if [[ ${missing_bins} -gt 0 || ${missing_markers} -gt 0 ]]; then
  exit 1
fi
