# Myron AI Handoff

Last updated: 2026-03-13

## Current Status

The phone is safe on stock Android on slot `a`.

Current verified state:
- custom `super.img` flashing works
- stock recovery works with the full stock boot chain plus stock `super`
- there is still no confirmed custom userspace boot
- the best custom result is a real bootloop before fallback to `fastboot`
- strategy is now pivoting to stock-vendor-first

## Most Important New Result

The pivot image changed the failure shape:
- stock `vendor_a`
- stock `odm_a`
- stock `vendor_dlkm_a`
- stock `mi_ext_a`
- custom `system_a`
- custom `system_ext_a`
- custom `product_a`
- custom `system_dlkm_a`

Built as:
- [/home/john/android/lineage/out/target/product/myron/super_stock_vendor.img](/home/john/android/lineage/out/target/product/myron/super_stock_vendor.img)

Observed result:
- stable POCO-logo stall instead of the earlier quick bootloop-to-`fastboot` path

Practical conclusion:
- stock lower partitions materially change behavior
- the new default strategy should be stock-vendor-first, not continued custom-vendor reconstruction

Fresh high-signal pivot bundle:
- [/home/john/android/lineage/_checkpoints/myron_20260312_234734](/home/john/android/lineage/_checkpoints/myron_20260312_234734)

What it proves:
- old early failures are gone:
  - no `ld.config.txt` warning
  - no early `vendor_init` property-denial storm
- boot now gets through:
  - `vold`
  - KeyMint / Gatekeeper / keystore2
  - `/data`
  - `apexd`
  - `system_server`
- later framework/runtime failures now dominate:
  - `Manager wrapper not available: security`
  - `Manager wrapper not available: MiuiWifiService`
  - `Manager wrapper not available: SlaveWifiService`
  - `Failed to create service com.android.server.location.LocationPolicyManagerService$Lifecycle`
  - `Failed to create service com.android.server.powerconsumpiton.PowerConsumptionService`
  - `SystemServerI: reboot init app level`
  - `SystemServerI: reboot init app anr level`

So the current primary suspect is the custom upper framework surface, not the lower vendor stack.

## What Is No Longer The Main Blocker

These have already been tested or eliminated as primary blockers:
- `fastbootd`
- AVB experiments
- `super` geometry mismatch
- stale repack inputs
- duplicate `service_contexts` warnings
- secure-element / strongbox / eSE exposure
- stale duplicate power HAL RC registration
- missing stock `mi_ext` mount lines alone
- custom `product` / `system_ext` surface by itself
- the custom-vendor-first strategy as the main path

## Current Failure Shape

Useful bundles for current analysis:
- [/home/john/android/lineage/_checkpoints/myron_20260312_234734](/home/john/android/lineage/_checkpoints/myron_20260312_234734)
- older custom-vendor reference:
  - [/home/john/android/lineage/_checkpoints/postfailure_myron_20260312_102812](/home/john/android/lineage/_checkpoints/postfailure_myron_20260312_102812)

## Strategy History

Important completed control tests:

1. Stock-framework control:
- stock `product_a`
- stock `system_ext_a`
- stock `mi_ext_a`
- custom `system` / `vendor` / `odm`
- failed

2. Stock-core control:
- stock `system_a`
- stock `product_a`
- stock `system_ext_a`
- stock `mi_ext_a`
- custom `vendor_a`
- custom `odm_a`
- custom `vendor_dlkm_a`
- custom `system_dlkm_a`
- image:
  - [/home/john/android/lineage/out/target/product/myron/super_stock_core.img](/home/john/android/lineage/out/target/product/myron/super_stock_core.img)
- failed

3. Custom-vendor reconstruction path:
- restored multiple Qualcomm/Xiaomi service batches
- fixed concrete RC/VINTF mismatches:
  - `vendor.qti.hardware.perf2.IPerf/default`
  - `vendor.qti.qhcp.IQHDC/default`
  - Xiaomi ODM AIDL interface declarations
- logs evolved, but no boot

4. Stock-vendor-first pivot:
- image:
  - [/home/john/android/lineage/out/target/product/myron/super_stock_vendor.img](/home/john/android/lineage/out/target/product/myron/super_stock_vendor.img)
- this is now the preferred baseline for the next stage of bring-up

## What To Do Next

1. Stop treating custom `vendor` / `odm` reconstruction as the default path.
2. Use stock-vendor-first images as the new control baseline.
3. Compare stock-vendor-first failure bundles against the old custom-vendor bundles.
4. Only reintroduce custom lower-stack pieces when a specific runtime contract is understood.
5. Keep `system/bin/init` instrumentation and broad property experiments deprioritized.

Current tighter control under test:
- stock `vendor`
- stock `odm`
- stock `vendor_dlkm`
- stock `mi_ext`
- stock `product`
- stock `system_ext`
- custom `system`
- custom `system_dlkm`
- image:
  - [/home/john/android/lineage/out/target/product/myron/super_stock_vendor_miui_upper.img](/home/john/android/lineage/out/target/product/myron/super_stock_vendor_miui_upper.img)

## Latest Useful Bundle

- [/home/john/android/lineage/_checkpoints/postfailure_myron_20260312_102812](/home/john/android/lineage/_checkpoints/postfailure_myron_20260312_102812)

Useful current comparison targets:
- stock-core image:
  - [/home/john/android/lineage/out/target/product/myron/super_stock_core.img](/home/john/android/lineage/out/target/product/myron/super_stock_core.img)
- stock-framework image:
  - [/home/john/android/lineage/out/target/product/myron/super_stock_framework.img](/home/john/android/lineage/out/target/product/myron/super_stock_framework.img)
- stock-vendor pivot image:
  - [/home/john/android/lineage/out/target/product/myron/super_stock_vendor.img](/home/john/android/lineage/out/target/product/myron/super_stock_vendor.img)
- tighter stock-vendor + stock-MIUI-upper control:
  - [/home/john/android/lineage/out/target/product/myron/super_stock_vendor_miui_upper.img](/home/john/android/lineage/out/target/product/myron/super_stock_vendor_miui_upper.img)

## Recovery Path

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

## Useful Paths

- Local workspace: [/Users/benny/Homelab/ROM](/Users/benny/Homelab/ROM)
- Remote tree: `/home/john/android/lineage`
- Current stock-core control image:
  - [/home/john/android/lineage/out/target/product/myron/super_stock_core.img](/home/john/android/lineage/out/target/product/myron/super_stock_core.img)
- Stock-framework control image:
  - [/home/john/android/lineage/out/target/product/myron/super_stock_framework.img](/home/john/android/lineage/out/target/product/myron/super_stock_framework.img)
- Stock-vendor pivot image:
  - [/home/john/android/lineage/out/target/product/myron/super_stock_vendor.img](/home/john/android/lineage/out/target/product/myron/super_stock_vendor.img)
