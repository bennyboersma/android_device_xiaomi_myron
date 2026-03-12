# Poco F8 Ultra (`myron`) Bring-up Status

Last updated: 2026-03-12

## Summary

This repository is for LineageOS bring-up on Xiaomi Poco F8 Ultra (`myron` / SM8850 / `canoe` / `kaanapali`).

Current project state:
- stock Android is safe and booting on slot `a`
- there is still no confirmed custom userspace boot
- custom `super.img` flashing works
- failed custom boots are recoverable with the full stock boot chain plus stock `super`

## What Is Proven

### Flash and recovery

- bootloader `fastboot` flashing works
- custom `super.img` can be flashed cleanly
- stock recovery works reliably with:
  - `boot_a`
  - `vendor_boot_a`
  - `dtbo_a`
  - `init_boot_a`
  - `vbmeta_a`
  - `vbmeta_system_a`
  - stock `super`

### Image side

- stock-layout `super` repacking works
- artifact freshness gating works
- stale-image flashes were a real issue and are now blocked
- stock `mi_ext_a` can be embedded successfully

## What Has Been Eliminated As The Main Blocker

These are no longer the primary problem:
- `fastbootd`
- AVB experimentation
- `super` geometry mismatch
- duplicate `service_contexts` warnings
- stale duplicate power HAL RC registration
- secure-element / strongbox / eSE exposure
- missing stock `mi_ext` lines alone
- custom `product/system_ext` surface by itself

## Strongest Current Result

The strongest control image still fails:
- stock `system_a`
- stock `product_a`
- stock `system_ext_a`
- stock `mi_ext_a`
- custom `vendor_a`
- custom `odm_a`
- custom `vendor_dlkm_a`
- custom `system_dlkm_a`

Built as:
- [/home/john/android/lineage/out/target/product/myron/super_stock_core.img](/home/john/android/lineage/out/target/product/myron/super_stock_core.img)

That image still bootloops and falls back to `fastboot`.

Meaning:
- missing stock `product/system_ext` apps and overlays were real mismatches
- but they were not sufficient to make the device boot
- the best remaining suspect is now custom `vendor` / `odm` runtime behavior

## Current Failure Shape

High-signal bundle:
- [/home/john/android/lineage/_checkpoints/postfailure_myron_20260312_102812](/home/john/android/lineage/_checkpoints/postfailure_myron_20260312_102812)

Useful late-stage signals from that bundle:
- `SystemServer: Entered the Android system server!`
- then package / overlay / framework failure storm
- later:
  - `SystemServiceRegistry: Manager wrapper not available: security`
  - `SystemServerI: reboot init app level`
  - `SystemServerI: reboot init app anr level`

This means the current debugging surface is later than classic early-init bring-up.

## Current Direction

Focus has shifted from `init` and property experiments to runtime contract mismatches between:
- custom `vendor` / `odm`
- stock or near-stock framework surface

Best next work:
1. diff stock vs custom `vendor_a` / `odm_a`
2. focus on:
   - init rc
   - VINTF manifests
   - sysconfig / permissions XMLs
   - package inventory XMLs
   - MIUI/QTI security, telephony, and performance integrations
3. only flash again after one concrete vendor/odm-side fix is identified

## Useful Tools

- [tools/prepare_myron_log_capture.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_log_capture.sh)
- [tools/run_myron_userspace_iteration.sh](/Users/benny/Homelab/ROM/tools/run_myron_userspace_iteration.sh)
- [tools/capture_myron_postfailure_bundle.sh](/Users/benny/Homelab/ROM/tools/capture_myron_postfailure_bundle.sh)
- [tools/compare_myron_failure_bundles.sh](/Users/benny/Homelab/ROM/tools/compare_myron_failure_bundles.sh)
- [tools/verify_myron_userspace_artifacts.sh](/Users/benny/Homelab/ROM/tools/verify_myron_userspace_artifacts.sh)
- [tools/repack_super_stock_layout_myron.sh](/Users/benny/Homelab/ROM/tools/repack_super_stock_layout_myron.sh)
- [tools/prepare_myron_stock_framework_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_stock_framework_super.sh)
- [tools/prepare_myron_stock_core_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_stock_core_super.sh)

## Related Docs

- [HANDOFF.md](/Users/benny/Homelab/ROM/HANDOFF.md)
- [device/xiaomi/myron](/Users/benny/Homelab/ROM/device/xiaomi/myron)
- [device/xiaomi/sm8850-common](/Users/benny/Homelab/ROM/device/xiaomi/sm8850-common)
- [vendor/xiaomi/myron](/Users/benny/Homelab/ROM/vendor/xiaomi/myron)
