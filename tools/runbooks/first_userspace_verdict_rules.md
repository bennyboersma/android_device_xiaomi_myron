# Myron First Userspace Verdict Rules

Purpose: make the first custom-userspace boot decision objective.

## PASS

Declare the first custom-userspace boot a pass only if all are true:

- `boot_completed=1`
- `boot_completed_after_dwell=1`
- stable `adb`
- no catastrophic crash loop
- no decryption regression
- no unexpected slot switch
- no major service-surface regression versus the proven baseline

## SUSPICIOUS BUT NOT IMMEDIATE ROLLBACK

Treat these as suspicious and investigate before deciding:

- one subsystem missing, but base system remains stable
- increased AVC count without boot-core regression
- NFC still missing while core runtime remains healthy
- Wi-Fi or Bluetooth partially present but not functional

## IMMEDIATE ROLLBACK

Rollback immediately if any of these happen:

- device returns to `fastboot`
- device lands in recovery instead of Android
- `adb` never appears after reasonable boot window
- repeated catastrophic crash loop in:
  - `init`
  - `system_server`
  - `vendor_init`
  - `vold`
  - `surfaceflinger`
  - `audioserver`
  - `tee`
  - `qseecomd`
- decryption or `/data` mount is broken

## FIRST FILES TO READ

In order:

1. `verdict.txt`
2. `must_have_gate.txt`
3. `firstboot.critical_log_grep.txt`
4. `firstboot.mount.txt`
5. `firstboot.key_props.txt`
6. subsystem-specific grep file for the failing area

## Current baseline this verdict is compared against

- stock `boot`
- stock `vendor_boot`
- custom `init_boot`
- temporary boot and persistent `init_boot` path already proven on hardware
