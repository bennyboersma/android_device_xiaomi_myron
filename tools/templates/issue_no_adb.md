# No ADB Issue Template

## Symptom
- Device does not appear via `adb` after boot window.

## Required artifacts
- bootloader / recovery / fastboot screen state
- `fastboot getvar current-slot`
- `logcat` if any capture exists
- `firstboot.critical_log_grep.txt`
- `verdict.txt`

## Required checks
- did the device return to `fastboot` or `recovery`
- did `sys.boot_completed` ever become `1`
- did `adb` ever enumerate during dwell

## Candidate fix areas
- boot/userspace handoff
- decryption / userdata mount
- catastrophic service crash loop
- slot confusion
