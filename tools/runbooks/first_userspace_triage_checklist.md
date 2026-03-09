# Myron First Userspace Triage Checklist

Last updated: 2026-03-09

Use this immediately after the first custom userspace boot.

## Order

1. Read `first_userspace_summary.txt`
2. Read `verdict.txt`
3. Read `must_have_gate.txt`
4. Read `firstboot.critical_log_grep.txt`
5. Read `firstboot.mount.txt`

## Stop And Roll Back

Rollback immediately if any of these are true:

- device returns to `fastboot`
- device lands in recovery
- `adb` never appears
- `boot_completed` is not `1`
- `boot_completed_after_dwell` is not `1`
- `crash_loop_detected=yes`
- `/data` is not mounted

## Then Triage In This Order

1. Decryption / userdata
   - inspect `firstboot.mount.txt`
   - inspect `firstboot.critical_log_grep.txt`
2. Keymint / gatekeeper / TEE
   - inspect `firstboot.security_log_grep.txt`
   - inspect `firstboot.lshal.txt`
3. Display / touch / USB
   - inspect `firstboot.display_log_grep.txt`
   - inspect `firstboot.dumpsys_l.txt`
4. Radio / IMS
   - inspect `firstboot.radio_log_grep.txt`
   - inspect `firstboot.service_list.txt`
   - inspect `firstboot.key_props.txt`
5. Wi-Fi / Bluetooth
   - inspect `firstboot.connectivity_log_grep.txt`
6. Camera
   - inspect `firstboot.camera_log_grep.txt`
7. Audio
   - inspect `firstboot.audio_log_grep.txt`
8. NFC
   - inspect `firstboot.nfc_log_grep.txt`
   - inspect `firstboot.dumpsys_nfc.txt`

## Expected Decision Outputs

- `decision=pass`
  - continue subsystem validation
- `decision=inspect`
  - follow `next_focus` from `first_userspace_summary.txt`
- `decision=rollback`
  - restore userspace images and debug the base path before subsystem work
