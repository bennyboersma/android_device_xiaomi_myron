#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./tools/parity_check_myron.sh
# Optional env:
#   BASELINE_DIR=/home/john/android/lineage/_checkpoints/phone_baseline_20260304_121337
#   MARKERS_FILE=/path/to/boot_critical_markers.txt

BASELINE_DIR="${BASELINE_DIR:-/home/john/android/lineage/_checkpoints/phone_baseline_20260304_121337}"
MARKERS_FILE="${MARKERS_FILE:-$PWD/tools/boot_critical_markers.txt}"
OUT_DIR="${OUT_DIR:-$PWD/_checkpoints/parity_$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$OUT_DIR"

echo "[1/4] Collecting current device runtime snapshot..."
adb wait-for-device
adb shell service list > "$OUT_DIR/service_list.current.txt"
adb shell dumpsys -l > "$OUT_DIR/dumpsys_list.current.txt"
adb shell dumpsys telephony.registry > "$OUT_DIR/dumpsys_telephony_registry.current.txt" || true
adb shell dumpsys ims > "$OUT_DIR/dumpsys_ims.current.txt" || true
adb shell dumpsys media.camera > "$OUT_DIR/dumpsys_camera.current.txt" || true
adb shell dumpsys media.audio_policy > "$OUT_DIR/dumpsys_audio_policy.current.txt" || true
adb shell dumpsys wifi > "$OUT_DIR/dumpsys_wifi.current.txt" || true
adb shell dumpsys bluetooth_manager > "$OUT_DIR/dumpsys_bluetooth_manager.current.txt" || true
adb shell getprop > "$OUT_DIR/getprop.current.txt"

if [[ -f "$BASELINE_DIR/service_list.txt" ]]; then
  cp "$BASELINE_DIR/service_list.txt" "$OUT_DIR/service_list.baseline.txt"
else
  echo "Baseline service_list not found at: $BASELINE_DIR/service_list.txt" >&2
  exit 1
fi

echo "[2/4] Loading must-have runtime markers..."
if [[ -f "$MARKERS_FILE" ]]; then
  cp "$MARKERS_FILE" "$OUT_DIR/must_have_markers.txt"
else
  echo "Markers file not found: $MARKERS_FILE" >&2
  exit 1
fi

echo "[3/4] Checking must-have markers..."
missing=0
while IFS= read -r marker; do
  [[ -z "$marker" ]] && continue
  if ! grep -Fq "$marker" "$OUT_DIR/service_list.current.txt"; then
    echo "MISSING: $marker" | tee -a "$OUT_DIR/missing_must_have.txt"
    missing=$((missing + 1))
  fi
done < "$OUT_DIR/must_have_markers.txt"

echo "[4/4] Producing diffs..."
sort "$OUT_DIR/service_list.baseline.txt" > "$OUT_DIR/service_list.baseline.sorted.txt"
sort "$OUT_DIR/service_list.current.txt" > "$OUT_DIR/service_list.current.sorted.txt"
comm -23 "$OUT_DIR/service_list.baseline.sorted.txt" "$OUT_DIR/service_list.current.sorted.txt" > "$OUT_DIR/services_missing_vs_stock.txt" || true
comm -13 "$OUT_DIR/service_list.baseline.sorted.txt" "$OUT_DIR/service_list.current.sorted.txt" > "$OUT_DIR/services_added_vs_stock.txt" || true

echo
echo "Parity report directory: $OUT_DIR"
echo "Missing must-have marker count: $missing"
if [[ "$missing" -gt 0 ]]; then
  echo "Status: FAIL (missing runtime-critical markers)"
  exit 2
fi
echo "Status: PASS (must-have runtime markers present)"
