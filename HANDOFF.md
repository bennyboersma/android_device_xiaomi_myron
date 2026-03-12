# Myron AI Handoff

Last updated: 2026-03-12

## Current Status

The phone is safe on stock Android on slot `a`.

Current verified state:
- custom `super.img` flashing works
- stock recovery works with the full stock boot chain plus stock `super`
- there is still no confirmed custom userspace boot
- the best custom result is a real bootloop before fallback to `fastboot`

## Most Important New Result

The strongest control test now also fails:
- stock `system_a`
- stock `product_a`
- stock `system_ext_a`
- stock `mi_ext_a`
- custom `vendor_a`
- custom `odm_a`
- custom `vendor_dlkm_a`
- custom `system_dlkm_a`

That image was built as:
- [/home/john/android/lineage/out/target/product/myron/super_stock_core.img](/home/john/android/lineage/out/target/product/myron/super_stock_core.img)

It still bootlooped and fell back to `fastboot`.

Practical conclusion:
- custom `product` / `system_ext` / `mi_ext` were real mismatches
- but they are not sufficient to explain the boot failure
- the strongest remaining suspect is now custom `vendor` / `odm` runtime behavior

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

## Current Failure Shape

Useful bundle for late-stage analysis:
- [/home/john/android/lineage/_checkpoints/postfailure_myron_20260312_102812](/home/john/android/lineage/_checkpoints/postfailure_myron_20260312_102812)

What the logs now show:
- boot gets into `system_server`
- then package / overlay / framework failures begin
- later:
  - `SystemServiceRegistry: Manager wrapper not available: security`
  - `SystemServerI: reboot init app level`
  - `SystemServerI: reboot init app anr level`

This is later and more useful than the earlier early-init theories.

## Strongest Current Lead

Stock `system` carries framework surface that custom `system` does not, including MIUI/QTI/Xiaomi jars and permissions.

Important stock-only examples:
- `QPerformance.jar`
- `QXPerformance.jar`
- `UxPerformance.jar`
- `WfdCommon.jar`
- `framework-nfc.jar`
- `telephony-ext.jar`
- `vendor.qti.hardware.data.connectionaidl-V1-java.jar`
- MIUI/QTI permissions XMLs such as:
  - `privapp-permissions-miui-system.xml`
  - `privapp-permissions-qti.xml`
  - `signature-permissions-miui-system.xml`

But the stock-core control still failed, so the current best interpretation is:
- custom `vendor` / `odm` are still violating a framework/runtime contract
- the next work should focus there, not on `system/bin/init`

## What To Do Next

1. Stop spending time on `system/bin/init` instrumentation.
2. Diff stock vs custom `vendor_a` and `odm_a` semantically:
   - init rc
   - VINTF manifests
   - sysconfig / permissions XMLs
   - package inventory XMLs
   - anything related to MIUI security / telephony / performance manager wrappers
3. Only flash again after one concrete vendor/odm-side contract fix is identified.

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
