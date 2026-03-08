# Firmware Lock Runbook (POCO F8 Ultra / myron)

Baseline lock:
- Device firmware baseline: `3.0.7.0.WPMEUXM` (EU)
- Do not mix firmware partitions across unrelated releases.

Required preflash assumptions:
1. Bootloader unlocked.
2. ADB/Fastboot stable connection verified.
3. Rollback images staged from the same release family:
   - `boot.img`
   - `init_boot.img`
   - `vendor_boot.img`
   - `dtbo.img`
4. For the first custom userspace flash, also stage:
   - `super.img`
   - `vbmeta_system.img`

Verification commands (stock before custom test):
```bash
adb shell getprop ro.build.fingerprint
adb shell getprop ro.vendor.build.fingerprint
adb shell getprop ro.boot.slot_suffix
adb shell getprop ro.boot.verifiedbootstate
adb shell getprop ro.boot.vbmeta.digest
```

Rollback quick path:
```bash
adb reboot bootloader
fastboot devices
fastboot flash boot boot.img
fastboot flash init_boot init_boot.img
fastboot flash vendor_boot vendor_boot.img
fastboot flash dtbo dtbo.img
fastboot reboot
```

Current install-path insight:
- keep `boot` stock-exact
- keep `vendor_boot` stock-exact
- treat `init_boot` as the mutable boot-chain partition in the current phase
- move userspace separately after that path is stable

A/B slot fallback:
```bash
fastboot getvar current-slot
fastboot --set-active=a   # or b
fastboot reboot
```
