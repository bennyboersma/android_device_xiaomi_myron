# Poco F8 Ultra (`myron`) Bring-up Status

Last updated: 2026-03-11

## Summary

This repository is for LineageOS bring-up on Xiaomi Poco F8 Ultra (`myron` / SM8850 / kaanapali).

Current project state:
- stock Android is safe and booting on slot `a`
- there is still no confirmed custom userspace boot
- custom `super.img` flashing works
- the best custom result so far is a real bootloop before fallback to `fastboot`
- the current blocker is early custom userspace abort, not flash transport

## What Is Proven

### Device and recovery

- bootloader `fastboot` flashing works
- custom `super.img` can be flashed cleanly
- stock recovery works reliably with the full stock boot chain plus stock `super`
- partial stock restore is not sufficient after these failures

Required stock recovery path:
- `boot_a`
- `vendor_boot_a`
- `dtbo_a`
- `init_boot_a`
- `vbmeta_a`
- `vbmeta_system_a`
- stock `super`
- `fastboot set_active a`
- reboot

### Build and image side

- stock-layout `super` repacking works
- artifact freshness gating works
- stale-image flashes were a real issue and are now blocked
- the earlier `system_a` size/layout problem was fixed by repacking from a live trimmed `system` tree

## What Has Already Been Eliminated

These are no longer the main blockers:
- `fastbootd`
- AVB experiments
- duplicate `service_contexts` warnings
- `super` geometry mismatch
- stale duplicate power HAL RC registration
- secure-element / strongbox / NXP/eSE package and VINTF exposure in the final repacked image

## Current Failure Shape

Latest clean bundle:
- [/home/john/android/lineage/_checkpoints/postfailure_myron_20260311_200750](/home/john/android/lineage/_checkpoints/postfailure_myron_20260311_200750)

Compared to the previous clean bootloop attempt:
- `classification=sideways`
- stage score stayed `4 -> 4`

Observed custom behavior:
- flashes cleanly
- reboots into a real bootloop
- never reaches `adb`
- eventually falls back to `fastboot`

## Current Best Signals

The earliest custom-only failures in the clean failed-boot segment are still:
- `linkerconfig` warning:
  - `failed to find generated linker configuration from "/linkerconfig/ld.config.txt"`
- `vendor_init` AVCs on:
  - `ro.adb.secure`
  - `persist.vendor.bt.a2dp_offload_cap`
  - `nfc.fw.is_downloading`
  - reads of `default_prop`

Later signals still present, but not earliest:
- `mi_ext` AVCs
- `tee/qseecomd` AVCs
- old perf/HIDL client spam

Important ordering:
- `init` aborts with `SIGABRT`
- the `mi_ext` AVCs show up after that abort point in the corrected clean slice

## Current Fix Direction

The active work is focused on the real property producers still surviving in the merged graph:

### `ro.adb.secure`

Still came from:
- `vendor/lineage/config/common.mk`
- merged into `PRODUCT_SYSTEM_EXT_PROPERTIES`

### `persist.vendor.bt.a2dp_offload_cap`

Still came from:
- `hardware/qcom-caf/kaanapali/audio/primary-hal/configs/qssi/qssi.mk`
- via `PRODUCT_PROPERTY_OVERRIDES`

That means earlier local filtering was not hitting the real graph producers.

## Current Rebuild In Progress

Remote host:
- `john@192.168.200.33`

Active builder session:
- `83427`

Targets:
- `systemextimage`
- `vendorimage`
- `odmimage`
- `productimage`

Current source changes:
- [device/xiaomi/myron/device.mk](/Users/benny/Homelab/ROM/device/xiaomi/myron/device.mk)
  - filters `persist.vendor.bt.a2dp_offload_cap` from both:
    - `PRODUCT_VENDOR_PROPERTIES`
    - `PRODUCT_PROPERTY_OVERRIDES`
- remote `vendor/lineage/config/common.mk`
  - no longer forces `ro.adb.secure=1` for non-`eng` bring-up builds

## Current Tooling

Main bring-up tooling:
- [tools/run_myron_userspace_iteration.sh](/Users/benny/Homelab/ROM/tools/run_myron_userspace_iteration.sh)
- [tools/prepare_myron_log_capture.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_log_capture.sh)
- [tools/capture_myron_postfailure_bundle.sh](/Users/benny/Homelab/ROM/tools/capture_myron_postfailure_bundle.sh)
- [tools/compare_myron_failure_bundles.sh](/Users/benny/Homelab/ROM/tools/compare_myron_failure_bundles.sh)
- [tools/verify_myron_userspace_artifacts.sh](/Users/benny/Homelab/ROM/tools/verify_myron_userspace_artifacts.sh)
- [tools/repack_super_stock_layout_myron.sh](/Users/benny/Homelab/ROM/tools/repack_super_stock_layout_myron.sh)

These now support:
- log clearing and marker-based capture
- actual image freshness checks
- stock-layout `super` repack
- consistent stock recovery after failure

## GSI Diagnostic Path

A diagnostic-only GSI flow is prepared but not active:
- [tools/prepare_myron_gsi_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_gsi_super.sh)
- [tools/runbooks/myron_gsi_diagnostic.md](/Users/benny/Homelab/ROM/tools/runbooks/myron_gsi_diagnostic.md)

This is for isolating `system` vs vendor/odm problems later, not the current primary path.

## Next Steps

1. Let session `83427` finish.
2. Verify the merged graph no longer carries:
   - `ro.adb.secure=1`
   - `persist.vendor.bt.a2dp_offload_cap=...`
3. Repack a fresh stock-layout `super.img`.
4. Run one more marker-based custom flash iteration.
5. If it still fails, inspect the next clean first-failure slice for:
   - whether the earliest `vendor_init` AVCs changed
   - whether `linkerconfig` is still the first custom-only warning
   - the first real service/process failure before `init` abort

## Repo Pointers

- Handoff summary: [HANDOFF.md](/Users/benny/Homelab/ROM/HANDOFF.md)
- Device tree: [device/xiaomi/myron](/Users/benny/Homelab/ROM/device/xiaomi/myron)
- Common tree: [device/xiaomi/sm8850-common](/Users/benny/Homelab/ROM/device/xiaomi/sm8850-common)
- Vendor packaging: [vendor/xiaomi/myron](/Users/benny/Homelab/ROM/vendor/xiaomi/myron)
- Runbooks: [tools/runbooks](/Users/benny/Homelab/ROM/tools/runbooks)
