# Myron AI Handoff

Last updated: 2026-03-11

## Current Status

The phone is safe on stock Android on slot `a` and reachable over `adb`.

Current verified state:
- flashing custom `super.img` works
- stock recovery works when using the full stock boot chain plus stock `super`
- there is still no confirmed custom userspace boot
- the current best custom result is a real bootloop before fallback to `fastboot`

The project is no longer blocked on:
- `fastbootd`
- AVB experimentation
- `super` geometry mismatch
- duplicate `service_contexts` warnings
- secure-element / strongbox / eSE VINTF exposure

## Latest Custom Boot Result

Latest clean failed-boot bundle:
- `/home/john/android/lineage/_checkpoints/postfailure_myron_20260311_200750`

Compared to the previous clean bootloop attempt:
- `classification=sideways`
- stage score stayed `4 -> 4`
- still no `adb`
- still falls back to `fastboot`

What the current custom image now does:
- flashes cleanly
- boots past the static POCO stall into a real rebooting bootloop
- then falls back to bootloader `fastboot`

## What Has Already Been Fixed

These were real issues and are already addressed:
- `system_a` oversize / shifted `super` geometry
- stale repack path using an old `system.img`
- missing Xiaomi ODM binaries and manifests needed for bring-up
- duplicate service-context collisions
- stale duplicate `android.hardware.power-service.rc`
- secure-element / strongbox / NXP/eSE binaries, permissions, and merged VINTF exposure in the repacked `super.img`
- stale image flashes due to old `vendor.img` / `super.img`
- missing stock `mi_ext` mount/bind/overlay lines in `vendor/etc/fstab.qcom`

## Current Best Leads

The earliest custom-only signals in the clean failed-boot segment are still:
- `linkerconfig` warning:
  - `failed to find generated linker configuration from "/linkerconfig/ld.config.txt"`
- very early `vendor_init` AVCs:
  - `ro.adb.secure`
  - `persist.vendor.bt.a2dp_offload_cap`
  - `nfc.fw.is_downloading`
  - reads of `default_prop`

Important ordering:
- `init` aborts with `SIGABRT` before the later `mi_ext` AVCs
- `mi_ext` is still not correct at runtime, but it is not the earliest signal anymore

Important non-conclusions:
- `linkerconfig` is a top suspect, but not yet proven as the root cause
- `mi_ext` is still broken, but not the earliest visible divergence in the current clean boot slice

## Current Work In Progress

Active builder session:
- remote host: `john@192.168.200.33`
- session: `83427`

Current rebuild target:
- `systemextimage`
- `vendorimage`
- `odmimage`
- `productimage`

Why this rebuild matters:
- `ro.adb.secure` was still being injected by `vendor/lineage/config/common.mk`
- `persist.vendor.bt.a2dp_offload_cap` was still being injected by Qualcomm audio `PRODUCT_PROPERTY_OVERRIDES`
- the old local filters were not removing the real producers

Current source changes in effect:
- `device/xiaomi/myron/device.mk`
  - filters `persist.vendor.bt.a2dp_offload_cap` from `PRODUCT_VENDOR_PROPERTIES`
  - filters `persist.vendor.bt.a2dp_offload_cap` from `PRODUCT_PROPERTY_OVERRIDES`
- remote `vendor/lineage/config/common.mk`
  - no longer forces `ro.adb.secure=1` for non-`eng` bring-up builds

## Recovery Path

Do not use partial stock restore after a failed custom flash.

Reliable stock recovery path:
- `fastboot flash boot_a .../boot.img`
- `fastboot flash vendor_boot_a .../vendor_boot.img`
- `fastboot flash dtbo_a .../dtbo.img`
- `fastboot flash init_boot_a .../init_boot.img`
- `fastboot flash vbmeta_a .../vbmeta.img`
- `fastboot flash vbmeta_system_a .../vbmeta_system.img`
- `fastboot flash super .../stock super.img`
- `fastboot set_active a`
- `fastboot reboot`

The `super` flash is the long part:
- 13 sparse chunks
- roughly low-20 seconds per chunk on the current setup

## Marker-Based Capture Loop

The repo now has a repeatable iteration flow:
- prepare logs on stock
- flash one verified custom `super.img`
- dwell and classify
- recover stock
- capture a postfailure bundle
- compare against the previous bundle using the first failed-boot segment

Key tools:
- [tools/prepare_myron_log_capture.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_log_capture.sh)
- [tools/run_myron_userspace_iteration.sh](/Users/benny/Homelab/ROM/tools/run_myron_userspace_iteration.sh)
- [tools/capture_myron_postfailure_bundle.sh](/Users/benny/Homelab/ROM/tools/capture_myron_postfailure_bundle.sh)
- [tools/compare_myron_failure_bundles.sh](/Users/benny/Homelab/ROM/tools/compare_myron_failure_bundles.sh)
- [tools/verify_myron_userspace_artifacts.sh](/Users/benny/Homelab/ROM/tools/verify_myron_userspace_artifacts.sh)
- [tools/repack_super_stock_layout_myron.sh](/Users/benny/Homelab/ROM/tools/repack_super_stock_layout_myron.sh)

## Next Steps

1. Let builder session `83427` finish.
2. Verify that the merged graph really dropped:
   - `ro.adb.secure=1`
   - `persist.vendor.bt.a2dp_offload_cap=...`
3. Repack `super.img` from the fresh coherent image set.
4. Run one more marker-based custom flash iteration.
5. If the boot still fails, inspect the next clean failed-boot segment for:
   - first crashing service before `init` abort
   - whether the earliest `vendor_init` AVCs changed
   - whether `linkerconfig` remains the first custom-only warning

## Important Paths

- Local workspace: `/Users/benny/Homelab/ROM`
- Remote tree: `john@192.168.200.33:/home/john/android/lineage`
- Latest clean bootloop bundle:
  - `/home/john/android/lineage/_checkpoints/postfailure_myron_20260311_200750`
- Previous clean bootloop bundle:
  - `/home/john/android/lineage/_checkpoints/postfailure_myron_20260311_190632`
