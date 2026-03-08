#!/usr/bin/env bash
set -euo pipefail

SERVICE_FILE="${1:-}"
MARKERS_FILE="${2:-/Users/benny/Homelab/ROM/tools/boot_critical_markers.txt}"

if [[ -z "$SERVICE_FILE" || ! -f "$SERVICE_FILE" ]]; then
  echo "Usage: $0 <service_list_file> [markers_file]" >&2
  exit 2
fi
if [[ ! -f "$MARKERS_FILE" ]]; then
  echo "Missing markers file: $MARKERS_FILE" >&2
  exit 2
fi

missing=0
while IFS= read -r marker; do
  [[ -z "$marker" || "$marker" =~ ^# ]] && continue
  if ! grep -F "$marker" "$SERVICE_FILE" >/dev/null 2>&1; then
    echo "MISSING_MUST_HAVE $marker"
    missing=$((missing+1))
  fi
done < "$MARKERS_FILE"

echo "must_have_missing_count=$missing"
if (( missing > 0 )); then
  exit 1
fi
