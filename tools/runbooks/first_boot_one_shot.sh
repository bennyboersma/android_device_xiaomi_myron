#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$PWD}"
PARITY_SCRIPT="${PARITY_SCRIPT:-$ROOT_DIR/tools/parity_check_myron.sh}"
MARKERS_FILE="${MARKERS_FILE:-$ROOT_DIR/tools/boot_critical_markers.txt}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/_checkpoints/first_boot_$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$OUT_DIR"

adb wait-for-device

adb shell getprop > "$OUT_DIR/getprop.txt"
adb shell service list > "$OUT_DIR/service_list.txt"
adb shell dumpsys -l > "$OUT_DIR/dumpsys_list.txt"
adb shell dumpsys display > "$OUT_DIR/dumpsys_display.txt" || true
adb shell dumpsys SurfaceFlinger > "$OUT_DIR/dumpsys_surfaceflinger.txt" || true
adb shell dumpsys telephony.registry > "$OUT_DIR/dumpsys_telephony_registry.txt" || true
adb shell dumpsys ims > "$OUT_DIR/dumpsys_ims.txt" || true
adb shell dumpsys wifi > "$OUT_DIR/dumpsys_wifi.txt" || true
adb shell dumpsys bluetooth_manager > "$OUT_DIR/dumpsys_bluetooth_manager.txt" || true
adb shell dumpsys media.camera > "$OUT_DIR/dumpsys_camera.txt" || true
adb shell dumpsys media.audio_policy > "$OUT_DIR/dumpsys_audio_policy.txt" || true
adb shell dumpsys power > "$OUT_DIR/dumpsys_power.txt" || true
adb shell dumpsys thermalservice > "$OUT_DIR/dumpsys_thermalservice.txt" || true
adb shell dumpsys battery > "$OUT_DIR/dumpsys_battery.txt" || true
adb shell logcat -b all -d > "$OUT_DIR/logcat_all.txt" || true

BASELINE_DIR="${BASELINE_DIR:-/home/john/android/lineage/_checkpoints/phone_baseline_20260304_121337}"
MARKERS_FILE="$MARKERS_FILE" OUT_DIR="$OUT_DIR/parity" BASELINE_DIR="$BASELINE_DIR" "$PARITY_SCRIPT" || true

echo "First-boot runbook output: $OUT_DIR"
