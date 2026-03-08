#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
BASELINE_DIR="${2:-${TOP_DIR}/_checkpoints/phone_baseline_20260304_121337}"
DWELL_SECONDS="${DWELL_SECONDS:-0}"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="${TOP_DIR}/_checkpoints/firstboot_${STAMP}"
mkdir -p "${OUT_DIR}"

echo "[info] output=${OUT_DIR}"

adb wait-for-device

adb shell getprop > "${OUT_DIR}/firstboot.getprop.txt"
adb shell getprop | grep -E '^\[(ro\.boot|init\.svc|sys\.boot_completed|vendor\.)' > "${OUT_DIR}/firstboot.key_props.txt" || true
adb shell service list > "${OUT_DIR}/firstboot.service_list.txt"
adb shell dumpsys -l > "${OUT_DIR}/firstboot.dumpsys_l.txt"
adb shell dumpsys nfc > "${OUT_DIR}/firstboot.dumpsys_nfc.txt" || true
adb shell logcat -b all -d > "${OUT_DIR}/firstboot.logcat.txt"
adb shell dmesg > "${OUT_DIR}/firstboot.dmesg.txt" || true
adb shell lshal > "${OUT_DIR}/firstboot.lshal.txt" || true
adb shell mount > "${OUT_DIR}/firstboot.mount.txt" || true
adb shell ps -A > "${OUT_DIR}/firstboot.ps.txt" || true
adb shell lsmod > "${OUT_DIR}/firstboot.lsmod.txt" || true
adb shell ls -l /dev > "${OUT_DIR}/firstboot.dev.txt" || true
adb shell getenforce > "${OUT_DIR}/firstboot.getenforce.txt" || true
adb shell getprop ro.boot.slot_suffix > "${OUT_DIR}/firstboot.slot_suffix.txt" || true
adb shell getprop sys.boot_completed > "${OUT_DIR}/firstboot.boot_completed.txt" || true
adb shell getprop ro.boot.bootreason > "${OUT_DIR}/firstboot.bootreason.txt" || true
adb shell getprop | grep -Ei 'init\.svc.*(nfc|nqnfc|st21|vendor\.nfc)|nfc|nqnfc|st21' > "${OUT_DIR}/firstboot.nfc_props.txt" || true
adb shell ps -A | grep -Ei 'nfc|nxp|secure_element' > "${OUT_DIR}/firstboot.ps_nfc.txt" || true
adb shell lsmod | grep -Ei 'nfc|nxp|st21' > "${OUT_DIR}/firstboot.lsmod_nfc.txt" || true
adb shell ls -l /dev | grep -Ei 'nfc|nq-nci|st21' > "${OUT_DIR}/firstboot.dev_nfc.txt" || true
grep -Ei 'avc:|vintf|servicemanager|hwservicemanager|fatal|crash|watchdog|recovery' "${OUT_DIR}/firstboot.logcat.txt" > "${OUT_DIR}/firstboot.critical_log_grep.txt" || true
grep -Ei 'radio|ims|qcril|telephony|iwlan' "${OUT_DIR}/firstboot.logcat.txt" > "${OUT_DIR}/firstboot.radio_log_grep.txt" || true
grep -Ei 'wifi|wlan|supplicant|hostapd|bluetooth|bt_' "${OUT_DIR}/firstboot.logcat.txt" > "${OUT_DIR}/firstboot.connectivity_log_grep.txt" || true
grep -Ei 'camera|camx|provider|mivi|mm-camera' "${OUT_DIR}/firstboot.logcat.txt" > "${OUT_DIR}/firstboot.camera_log_grep.txt" || true
grep -Ei 'audio|audioserver|audioflinger|pal|agm|sthal' "${OUT_DIR}/firstboot.logcat.txt" > "${OUT_DIR}/firstboot.audio_log_grep.txt" || true
grep -Ei 'gatekeeper|keymint|keystore|tee|qseecom|trust' "${OUT_DIR}/firstboot.logcat.txt" > "${OUT_DIR}/firstboot.security_log_grep.txt" || true
grep -Ei 'surfaceflinger|composer|display|gralloc|hwcomposer|inputflinger|touch' "${OUT_DIR}/firstboot.logcat.txt" > "${OUT_DIR}/firstboot.display_log_grep.txt" || true
grep -Ei 'nfc|nxp|secure_element|ese' "${OUT_DIR}/firstboot.logcat.txt" > "${OUT_DIR}/firstboot.nfc_log_grep.txt" || true

if [[ "${DWELL_SECONDS}" -gt 0 ]]; then
  sleep "${DWELL_SECONDS}"
  adb wait-for-device
  adb shell getprop sys.boot_completed > "${OUT_DIR}/firstboot.boot_completed_after_dwell.txt" || true
  adb devices > "${OUT_DIR}/adb_devices_after_dwell.txt"
  adb shell service list > "${OUT_DIR}/firstboot.service_list_after_dwell.txt"
  adb shell dumpsys -l > "${OUT_DIR}/firstboot.dumpsys_l_after_dwell.txt" || true
  adb shell dumpsys nfc > "${OUT_DIR}/firstboot.dumpsys_nfc_after_dwell.txt" || true
  adb shell getprop | grep -E '^\[(ro\.boot|init\.svc|sys\.boot_completed|vendor\.)' > "${OUT_DIR}/firstboot.key_props_after_dwell.txt" || true
fi

if [[ -x "${TOP_DIR}/tools/parity_check_myron.sh" ]]; then
  (cd "${TOP_DIR}" && bash tools/parity_check_myron.sh) > "${OUT_DIR}/parity_check.txt" 2>&1 || true
fi

service_list_for_gate="${OUT_DIR}/firstboot.service_list.txt"
dumpsys_list_for_diff="${OUT_DIR}/firstboot.dumpsys_l.txt"
if [[ -f "${OUT_DIR}/firstboot.service_list_after_dwell.txt" ]]; then
  service_list_for_gate="${OUT_DIR}/firstboot.service_list_after_dwell.txt"
fi
if [[ -f "${OUT_DIR}/firstboot.dumpsys_l_after_dwell.txt" ]]; then
  dumpsys_list_for_diff="${OUT_DIR}/firstboot.dumpsys_l_after_dwell.txt"
fi

if [[ -f "${BASELINE_DIR}/service_list.txt" ]]; then
  diff -u "${BASELINE_DIR}/service_list.txt" "${service_list_for_gate}" > "${OUT_DIR}/diff_service_list.txt" || true
fi

if [[ -f "${TOP_DIR}/tools/boot_critical_markers.txt" ]]; then
  awk 'NF && $0 !~ /^#/' "${TOP_DIR}/tools/boot_critical_markers.txt" | while IFS= read -r marker; do
    grep -F "${marker}" "${service_list_for_gate}" >/dev/null 2>&1 || echo "MISSING_RUNTIME_MARKER ${marker}"
  done > "${OUT_DIR}/missing_runtime_markers.txt" || true
fi

if [[ -x "${TOP_DIR}/tools/check_must_have_services.sh" ]]; then
  "${TOP_DIR}/tools/check_must_have_services.sh" \
    "${service_list_for_gate}" \
    "${TOP_DIR}/tools/boot_critical_markers.txt" \
    > "${OUT_DIR}/must_have_gate.txt" 2>&1 || true
fi

if [[ -f "${BASELINE_DIR}/dumpsys-l.txt" ]]; then
  diff -u "${BASELINE_DIR}/dumpsys-l.txt" "${dumpsys_list_for_diff}" > "${OUT_DIR}/diff_dumpsys_l.txt" || true
fi

grep 'avc:  denied' "${OUT_DIR}/firstboot.logcat.txt" > "${OUT_DIR}/avc_denials.logcat.txt" || true
grep 'avc:  denied' "${OUT_DIR}/firstboot.dmesg.txt" > "${OUT_DIR}/avc_denials.dmesg.txt" || true
cat "${OUT_DIR}/avc_denials.logcat.txt" "${OUT_DIR}/avc_denials.dmesg.txt" | sort -u > "${OUT_DIR}/avc_denials.txt" || true

if [[ -x "${TOP_DIR}/tools/classify_avc_denials.sh" ]]; then
  "${TOP_DIR}/tools/classify_avc_denials.sh" "${OUT_DIR}/avc_denials.txt" "${OUT_DIR}" > "${OUT_DIR}/avc_classification.txt" 2>&1 || true
fi

boot_completed="$(tr -d '\r' < "${OUT_DIR}/firstboot.boot_completed.txt" 2>/dev/null || true)"
boot_completed_after_dwell="$(tr -d '\r' < "${OUT_DIR}/firstboot.boot_completed_after_dwell.txt" 2>/dev/null || true)"
crash_loop=no
if grep -Eiq 'service .* has crashed .* times|service .* crashed and will not be restarted|restarting crashed process|System server process has died|watchdog bite|Shutdown due to error' "${OUT_DIR}/firstboot.logcat.txt"; then
  crash_loop=yes
fi
must_have_result=unknown
if grep -Fq 'must_have_missing_count=0' "${OUT_DIR}/must_have_gate.txt" 2>/dev/null; then
  must_have_result=pass
elif [[ -f "${OUT_DIR}/must_have_gate.txt" ]]; then
  must_have_result=fail
fi
boot_critical_avc_count=0
if [[ -f "${OUT_DIR}/avc_boot_critical.txt" ]]; then
  boot_critical_avc_count="$(wc -l < "${OUT_DIR}/avc_boot_critical.txt" | tr -d ' ')"
fi

cat > "${OUT_DIR}/verdict.txt" <<EOF
boot_completed=${boot_completed:-unknown}
boot_completed_after_dwell=${boot_completed_after_dwell:-unknown}
adb_stable_initial=yes
must_have_result=${must_have_result}
crash_loop_detected=${crash_loop}
selinux_mode=$(tr -d '\r' < "${OUT_DIR}/firstboot.getenforce.txt" 2>/dev/null || echo unknown)
active_slot=$(tr -d '\r' < "${OUT_DIR}/firstboot.slot_suffix.txt" 2>/dev/null || echo unknown)
boot_reason=$(tr -d '\r' < "${OUT_DIR}/firstboot.bootreason.txt" 2>/dev/null || echo unknown)
must_have_source=$(basename "${service_list_for_gate}")
boot_critical_avc_count=${boot_critical_avc_count}
EOF

echo "[done] saved first-boot capture to ${OUT_DIR}"
