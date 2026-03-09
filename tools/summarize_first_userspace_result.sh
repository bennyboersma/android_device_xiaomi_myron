#!/usr/bin/env bash
set -euo pipefail

CAPTURE_DIR="${1:?usage: summarize_first_userspace_result.sh <firstboot_dir>}"

need_file() {
  [[ -f "$1" ]] || { echo "Missing required file: $1" >&2; exit 2; }
}

read_kv() {
  local file="$1" key="$2"
  awk -F= -v k="$key" '$1==k {print $2}' "$file" | tail -n 1
}

need_file "${CAPTURE_DIR}/verdict.txt"

boot_completed="$(read_kv "${CAPTURE_DIR}/verdict.txt" boot_completed)"
boot_completed_after_dwell="$(read_kv "${CAPTURE_DIR}/verdict.txt" boot_completed_after_dwell)"
must_have_result="$(read_kv "${CAPTURE_DIR}/verdict.txt" must_have_result)"
crash_loop_detected="$(read_kv "${CAPTURE_DIR}/verdict.txt" crash_loop_detected)"
active_slot="$(read_kv "${CAPTURE_DIR}/verdict.txt" active_slot)"
selinux_mode="$(read_kv "${CAPTURE_DIR}/verdict.txt" selinux_mode)"
boot_critical_avc_count="$(read_kv "${CAPTURE_DIR}/verdict.txt" boot_critical_avc_count)"

decryption_regression=no
if [[ -f "${CAPTURE_DIR}/firstboot.mount.txt" ]] && ! grep -Eq ' /data ' "${CAPTURE_DIR}/firstboot.mount.txt"; then
  decryption_regression=yes
fi

critical_hint="inspect critical logs"
if [[ -s "${CAPTURE_DIR}/firstboot.display_log_grep.txt" ]]; then
  critical_hint="inspect display/touch"
fi
if [[ -s "${CAPTURE_DIR}/firstboot.security_log_grep.txt" ]]; then
  critical_hint="inspect keymint/gatekeeper/tee"
fi
if [[ -s "${CAPTURE_DIR}/firstboot.radio_log_grep.txt" ]]; then
  critical_hint="inspect radio/ims"
fi
if [[ -s "${CAPTURE_DIR}/firstboot.connectivity_log_grep.txt" ]]; then
  critical_hint="inspect wifi/bluetooth"
fi
if [[ -s "${CAPTURE_DIR}/firstboot.camera_log_grep.txt" ]]; then
  critical_hint="inspect camera"
fi
if [[ -s "${CAPTURE_DIR}/firstboot.audio_log_grep.txt" ]]; then
  critical_hint="inspect audio"
fi
if [[ -s "${CAPTURE_DIR}/firstboot.nfc_log_grep.txt" ]]; then
  critical_hint="inspect nfc"
fi

decision="inspect"
reason="review capture"
if [[ "${boot_completed}" != "1" || "${boot_completed_after_dwell:-${boot_completed}}" != "1" ]]; then
  decision="rollback"
  reason="boot did not remain completed through dwell"
elif [[ "${crash_loop_detected}" == "yes" ]]; then
  decision="rollback"
  reason="catastrophic crash loop detected"
elif [[ "${decryption_regression}" == "yes" ]]; then
  decision="rollback"
  reason="/data not mounted as expected"
elif [[ "${must_have_result}" == "pass" ]]; then
  decision="pass"
  reason="core runtime gate passed"
else
  decision="inspect"
  reason="must-have runtime markers missing"
fi

cat > "${CAPTURE_DIR}/first_userspace_summary.txt" <<EOF
decision=${decision}
reason=${reason}
boot_completed=${boot_completed:-unknown}
boot_completed_after_dwell=${boot_completed_after_dwell:-unknown}
must_have_result=${must_have_result:-unknown}
crash_loop_detected=${crash_loop_detected:-unknown}
decryption_regression=${decryption_regression}
active_slot=${active_slot:-unknown}
selinux_mode=${selinux_mode:-unknown}
boot_critical_avc_count=${boot_critical_avc_count:-unknown}
next_focus=${critical_hint}
capture_dir=${CAPTURE_DIR}
EOF

cat "${CAPTURE_DIR}/first_userspace_summary.txt"
