#!/usr/bin/env bash
set -euo pipefail

TOP_DIR="${1:-$PWD}"
CHECKPOINT_DIR="${2:-${TOP_DIR}/_checkpoints}"

latest_capture="$(find "${CHECKPOINT_DIR}" -maxdepth 1 -type d -name 'firstboot_*' | sort | tail -n 1)"
[[ -n "${latest_capture}" ]] || {
  echo "No firstboot_* capture found in ${CHECKPOINT_DIR}" >&2
  exit 2
}

echo "latest_capture=${latest_capture}"

bash "${TOP_DIR}/tools/summarize_first_userspace_result.sh" "${latest_capture}"

summary_file="${latest_capture}/first_userspace_summary.txt"
decision="$(awk -F= '$1=="decision"{print $2}' "${summary_file}" | tail -n 1)"
next_focus="$(awk -F= '$1=="next_focus"{print $2}' "${summary_file}" | tail -n 1)"

echo
echo "Top files to inspect next:"
echo "1. ${latest_capture}/first_userspace_summary.txt"
echo "2. ${latest_capture}/verdict.txt"
echo "3. ${latest_capture}/must_have_gate.txt"

case "${decision}" in
  pass)
    echo "4. ${latest_capture}/firstboot.critical_log_grep.txt"
    ;;
  rollback)
    echo "4. ${latest_capture}/firstboot.mount.txt"
    echo "5. ${latest_capture}/firstboot.critical_log_grep.txt"
    ;;
  *)
    case "${next_focus}" in
      *display*)
        echo "4. ${latest_capture}/firstboot.display_log_grep.txt"
        ;;
      *keymint*|*gatekeeper*|*tee*)
        echo "4. ${latest_capture}/firstboot.security_log_grep.txt"
        ;;
      *radio*|*ims*)
        echo "4. ${latest_capture}/firstboot.radio_log_grep.txt"
        ;;
      *wifi*|*bluetooth*)
        echo "4. ${latest_capture}/firstboot.connectivity_log_grep.txt"
        ;;
      *camera*)
        echo "4. ${latest_capture}/firstboot.camera_log_grep.txt"
        ;;
      *audio*)
        echo "4. ${latest_capture}/firstboot.audio_log_grep.txt"
        ;;
      *nfc*)
        echo "4. ${latest_capture}/firstboot.nfc_log_grep.txt"
        ;;
      *)
        echo "4. ${latest_capture}/firstboot.critical_log_grep.txt"
        ;;
    esac
    ;;
esac

