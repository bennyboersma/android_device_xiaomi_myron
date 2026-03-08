# Myron Fastboot Command Sheet

## Scope
Use this to avoid slot mistakes and wrong-scope flashing.

Current operational model:
- reference/debug path: `fastboot boot` with custom `boot.img`
- proven persistent path: stock `boot` + stock `vendor_boot` + custom `init_boot`
- next flash target: logical userspace partitions only

## Preconditions
- Device: Poco F8 Ultra (`myron`)
- Firmware baseline on phone: `3.0.7.0.WPMEUXM`
- Build artifacts available:
  - `out/target/product/myron/boot.img`
  - `out/target/product/myron/init_boot.img`
  - `out/target/product/myron/vendor_boot.img`

## 1) Connectivity and identity
```bash
adb devices
adb reboot bootloader
fastboot devices
fastboot getvar product
fastboot getvar current-slot
```
Expected product: `myron`

## 2) Boot-only validation path (reference)
```bash
fastboot boot out/target/product/myron/boot.img
```
If you need userspace fastboot for your existing workflow:
```bash
fastboot reboot fastboot
fastboot devices
# then run your known temporary boot flow for boot/init_boot/vendor_boot
```

## 3) Proven persistent init_boot-only path
```bash
FLASH_BOOT=0 FLASH_INIT_BOOT=1 FLASH_VENDOR_BOOT=0 DRY_RUN=1 \
  bash tools/minimal_boot_chain_flash.sh ~/android/lineage myron
```

Actual command:
```bash
FLASH_BOOT=0 FLASH_INIT_BOOT=1 FLASH_VENDOR_BOOT=0 DRY_RUN=0 \
  bash tools/minimal_boot_chain_flash.sh ~/android/lineage myron
fastboot reboot
```

## 4) First custom userspace path (active next step)
```bash
CHECK_ROLLBACK=1 REQUIRE_DEVICE=0 \
  bash tools/check_userspace_flash_readiness.sh ~/android/lineage myron

DRY_RUN=1 REBOOT_TO_FASTBOOTD=1 USE_SUPER=0 FLASH_VBMETA_SYSTEM=0 \
  bash tools/flash_userspace_images.sh ~/android/lineage myron
```

## 5) Immediate first-boot capture
```bash
adb wait-for-device
bash tools/first_boot_capture_and_diff.sh /Users/benny/Homelab/ROM /Users/benny/Homelab/ROM/_checkpoints/phone_baseline_20260304_121337
```

## 6) Hard safety rules
- Do not mix firmware from different stock releases.
- Do not replace `boot` by default in the current phase.
- Do not replace `vendor_boot` by default in the current phase.
- Do not flash userspace partitions until readiness passes.
- Capture logs on every failed boot attempt before retrying.
- Flash only the current slot during the minimal boot-chain stage.
