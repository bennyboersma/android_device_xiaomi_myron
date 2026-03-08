# Bootloop / Crash Loop Issue Template

## Symptom
- device reboots repeatedly or never stabilizes

## Required artifacts
- `verdict.txt`
- `firstboot.critical_log_grep.txt`
- `firstboot.logcat.txt`
- `firstboot.dmesg.txt`
- `firstboot.key_props.txt`

## First suspect processes
- `init`
- `system_server`
- `vendor_init`
- `surfaceflinger`
- `audioserver`
- `vold`
- `tee`
- `qseecomd`

## Candidate fix areas
- SELinux boot-critical denials
- service ownership / manifest mismatch
- decryption / mount failures
- userspace regression on logical partitions
