# Rollback Pack Preparation (Before Unlock/Flash)

## Goal
Guarantee quick recovery to known-good stock if custom boot/flash fails.

## Inputs
- Stock image archive:
  - `/Users/benny/Homelab/ROM/myron_eea_global_images_OS3.0.7.0.WPMEUXM_20260112.0000.00_16.0_eea_cee0eaf4a6.tgz`
- Optional OTA archive:
  - `/Users/benny/Homelab/ROM/myron_eea_global-ota_full-OS3.0.7.0.WPMEUXM-user-16.0-c18845911d.zip`

## 1) Create checksums now
```bash
cd /Users/benny/Homelab/ROM
shasum -a 256 myron_eea_global_images_OS3.0.7.0.WPMEUXM_20260112.0000.00_16.0_eea_cee0eaf4a6.tgz > _transfer/rollback_wpm_eu/images.sha256
shasum -a 256 myron_eea_global-ota_full-OS3.0.7.0.WPMEUXM-user-16.0-c18845911d.zip > _transfer/rollback_wpm_eu/ota.sha256
```

## 2) Verify archive integrity before use
```bash
cd /Users/benny/Homelab/ROM
shasum -a 256 -c _transfer/rollback_wpm_eu/images.sha256
shasum -a 256 -c _transfer/rollback_wpm_eu/ota.sha256
```

## 3) Save device identity before any flashing
```bash
adb shell getprop ro.product.device > _transfer/rollback_wpm_eu/device.txt
adb shell getprop ro.build.fingerprint > _transfer/rollback_wpm_eu/fingerprint.txt
adb shell getprop ro.vendor.build.fingerprint > _transfer/rollback_wpm_eu/vendor_fingerprint.txt
adb shell getprop ro.boot.slot_suffix > _transfer/rollback_wpm_eu/slot_suffix.txt
```

## 4) Keep a ready-to-run restore command file
Store vendor-provided restore commands in:
- `_transfer/rollback_wpm_eu/restore_commands.sh`

Rules:
- Keep commands exactly from stock package tooling for this release.
- Do not mix firmware from other releases.
- Keep slot handling explicit.

## 5) Recovery policy
- If first custom boot fails hard: restore stock boot chain first.
- If first custom userspace flash fails hard: restore stock userspace (`super.img` + `vbmeta_system.img`) while preserving the proven boot path as needed.
- If radio/firmware regressions appear: return fully to stock `3.0.7.0.WPMEUXM` baseline before next attempt.

Current rollback asset split:
- boot-chain rollback:
  - `boot.img`
  - `init_boot.img`
  - `vendor_boot.img`
  - `dtbo.img`
- userspace rollback:
  - `super.img`
  - `vbmeta_system.img`
