# Poco F8 Ultra (`myron`) Bring-up Status

Last updated: 2026-03-13

## Summary

This repository is for LineageOS bring-up on Xiaomi Poco F8 Ultra (`myron` / SM8850 / `canoe` / `kaanapali`).

Current project state:
- stock Android is safe and booting on slot `a`
- there is still no confirmed custom userspace boot
- custom `super.img` flashing works
- failed custom boots are recoverable with the full stock boot chain plus stock `super`
- the project is now pivoting to a stock-vendor-first strategy
- the newest control says custom `product` alone is enough to break boot
- stock vs custom `product` diff points at missing MIUI `product` surface, not lower-stack regressions

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

## Major Strategies Already Tried

These are the major bring-up strategies and what they taught us:

1. Custom userspace against stock boot chain
- baseline custom `system` / `system_ext` / `product` / `vendor` / `odm`
- result: bootloop or POCO stall, then fallback to `fastboot`

2. Stock-framework control
- stock `product_a`
- stock `system_ext_a`
- stock `mi_ext_a`
- custom `system` / `vendor` / `odm`
- result: still failed
- conclusion: missing `product/system_ext` apps and overlays were real, but not sufficient

3. Stock-core control
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
- result: still failed
- conclusion: the strongest remaining suspect is custom `vendor` / `odm`

4. Vendor/ODM contract reconstruction
- restored minimal Qualcomm/Xiaomi vendor contract pieces in batches:
  - `qconfigservice`
  - `qesdk-manager`
  - `qesdk-secmanager`
  - `qguard`
  - `qms`
  - `poweropt-service`
  - `vendor.qti.syshealthmon-service`
  - `vendor.qti.hardware.perf2-hal-service`
  - Xiaomi security-side ODM services and manifests
- fixed several concrete runtime contract bugs:
  - `vendor.qti.hardware.perf2.IPerf/default`
  - `vendor.qti.qhcp.IQHDC/default`
  - Xiaomi AIDL RC/interface mismatches
- result: logs changed and more services came alive, but no boot
- conclusion: the current custom `vendor` / `odm` reconstruction path is too expensive to continue indefinitely

5. Stock-vendor-first pivot
- stock `vendor_a`
- stock `odm_a`
- stock `vendor_dlkm_a`
- stock `mi_ext_a`
- custom `system_a`
- custom `system_ext_a`
- custom `product_a`
- custom `system_dlkm_a`
- image:
  - [/home/john/android/lineage/out/target/product/myron/super_stock_vendor.img](/home/john/android/lineage/out/target/product/myron/super_stock_vendor.img)
- first result:
  - changed visible failure shape to a stable POCO-logo stall
- current strategy:
  - keep iterating from the stock-vendor-first baseline instead of reconstructing custom `vendor` / `odm` one service at a time

6. Tighter stock-vendor + stock-MIUI-upper control
- stock `vendor_a`
- stock `odm_a`
- stock `vendor_dlkm_a`
- stock `mi_ext_a`
- stock `product_a`
- stock `system_ext_a`
- custom `system_a`
- custom `system_dlkm_a`
- image:
  - [/home/john/android/lineage/out/target/product/myron/super_stock_vendor_miui_upper.img](/home/john/android/lineage/out/target/product/myron/super_stock_vendor_miui_upper.img)
- purpose:
  - isolate whether the remaining blocker is now in custom `system` alone

7. Stock-everything-except-product control
- stock `system_a`
- stock `system_ext_a`
- custom `product_a`
- stock `vendor_a`
- stock `odm_a`
- stock `vendor_dlkm_a`
- stock `system_dlkm_a`
- stock `mi_ext_a`
- image:
  - [/home/john/android/lineage/out/target/product/myron/super_stock_except_product.img](/home/john/android/lineage/out/target/product/myron/super_stock_except_product.img)
- result: still failed
- conclusion: custom `product` alone is already sufficient to break boot

8. Product surface diff and targeted restore prep
- compared stock `product_a` against custom `product.img`
- result:
  - stock `product` has `1613` files vs `521` in custom
  - focused boot-relevant set (`framework`, `priv-app`, `app`, overlays, permissions, sysconfig) is `451` vs `157`
- strongest missing stock paths:
  - `pangu/system`
  - `priv-app/MIUISecurityCenterGlobal`
  - `priv-app/MISettings`
  - `priv-app/MIServiceGlobal`
  - `app/MIUIGlobalLayout`
  - `app/MIUISecurityAdd`
  - `app/MIUISystemUIPlugin`
  - `overlay/MiuiFrameworkResOverlay.apk`
  - `overlay/MiuiPermissionControllerOverlay.apk`
  - `overlay/MiuiPowerInsightOverlay.apk`
  - `overlay/MiuiServiceOverlay`
  - `overlay/SafetyCenterMiuiConfigOverlay.apk`
  - `overlay/SafetyCenterMiuiOverlay.apk`
- conclusion:
  - the custom `product` failure is likely driven by missing MIUI framework surface, not a generic custom-`system` problem

## What Has Been Eliminated As The Main Blocker

These are no longer the primary problem:
- `fastbootd`
- AVB experimentation
- `super` geometry mismatch
- duplicate `service_contexts` warnings
- stale duplicate power HAL RC registration
- secure-element / strongbox / eSE exposure
- missing stock `mi_ext` lines alone
- the original custom-vendor-first strategy as the default path

## Strongest Current Result

The strongest current result is now the newest control after the pivot:
- stock-everything-except-product still fails
- that means custom `product` alone is enough to break boot

The pivot result still matters:
- stock-vendor-first changed the visible failure shape to a stable POCO-logo stall
- that is a stronger signal than the older quick bootloop-to-`fastboot` behavior

Meaning:
- stock `vendor` / `odm` does matter materially
- custom `product` is now the highest-confidence upper-layer blocker
- Xiaomi's `product` content also feeds `/system` through overlay mounts, so this is not just an isolated app-packaging issue
- the next work should be framed around a stock-vendor-first baseline with `product` isolation first, not continued custom-vendor reconstruction

## Current Failure Shape

High-signal stock-vendor-first pivot bundle:
- [/home/john/android/lineage/_checkpoints/myron_20260312_234734](/home/john/android/lineage/_checkpoints/myron_20260312_234734)

Useful late-stage signals from that pivot bundle:
- old early failures are gone:
  - no `ld.config.txt` warning
  - no early `vendor_init` property-denial storm
- boot now gets through:
  - `vold`
  - KeyMint / Gatekeeper / keystore2
  - `/data` mount
  - `apexd.status=activated`
  - `SystemServer: Entered the Android system server!`
- later framework/runtime failures:
  - `Manager wrapper not available: security`
  - `Manager wrapper not available: MiuiWifiService`
  - `Manager wrapper not available: SlaveWifiService`
  - `Failed to create service com.android.server.location.LocationPolicyManagerService$Lifecycle`
  - `Failed to create service com.android.server.powerconsumpiton.PowerConsumptionService`
  - `SystemServerI: reboot init app level`
  - `SystemServerI: reboot init app anr level`

This means the current debugging surface has shifted up into the upper framework / `product` layer, not the lower vendor stack.

Why `product` can still break apparent `/system` services:
- Xiaomi overlays `product` content back onto `/system` at boot through:
  - [fstab.qcom](/Users/benny/Homelab/ROM/device/xiaomi/sm8850-common/init/fstab.qcom#L63)
  - [fstab.qcom](/Users/benny/Homelab/ROM/device/xiaomi/sm8850-common/init/fstab.qcom#L64)
  - [fstab.qcom](/Users/benny/Homelab/ROM/device/xiaomi/sm8850-common/init/fstab.qcom#L65)
  - [fstab.qcom](/Users/benny/Homelab/ROM/device/xiaomi/sm8850-common/init/fstab.qcom#L67)
- stock `product` contains `/product/pangu/system/*`
- custom `product` currently has no `pangu/system` subtree
- that gives a direct mechanism for `product`-only changes to break framework service bring-up

## Current Direction

Focus has shifted from `init` and property experiments to a stock-vendor-first pivot:
- keep stock lower partitions intact
- adapt upper framework layers around them

Current baseline for the pivot:
- stock `vendor` / `odm` / `vendor_dlkm` / `mi_ext`
- custom `system` / `system_ext` / `product` / `system_dlkm`

Current best next work:
1. use the stock-vendor-first image as the new control baseline
2. compare its failure bundles against the old custom-vendor bundles
3. use the `product` diff result to restore the smallest stock MIUI surface first
4. test a patched `product` that restores stock `pangu/system`, security-center privilege, MIUI settings/service apps, and key MIUI overlays
5. compare stock vs custom `product` contents, overlays, priv-apps, and framework jars that feed:
   - `LocationPolicyManagerService`
   - `PowerConsumptionService`
   - MIUI security / wifi wrapper classes
6. avoid further lower-stack restoration unless the pivot evidence points back downward

The older vendor/odm contract-restoration work is still useful history, but it is no longer the default strategy.

## Useful Tools

- [tools/prepare_myron_log_capture.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_log_capture.sh)
- [tools/run_myron_userspace_iteration.sh](/Users/benny/Homelab/ROM/tools/run_myron_userspace_iteration.sh)
- [tools/capture_myron_postfailure_bundle.sh](/Users/benny/Homelab/ROM/tools/capture_myron_postfailure_bundle.sh)
- [tools/compare_myron_failure_bundles.sh](/Users/benny/Homelab/ROM/tools/compare_myron_failure_bundles.sh)
- [tools/verify_myron_userspace_artifacts.sh](/Users/benny/Homelab/ROM/tools/verify_myron_userspace_artifacts.sh)
- [tools/repack_super_stock_layout_myron.sh](/Users/benny/Homelab/ROM/tools/repack_super_stock_layout_myron.sh)
- [tools/prepare_myron_stock_framework_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_stock_framework_super.sh)
- [tools/prepare_myron_stock_core_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_stock_core_super.sh)
- [tools/prepare_myron_stock_vendor_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_stock_vendor_super.sh)
- [tools/prepare_myron_stock_vendor_miui_upper_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_stock_vendor_miui_upper_super.sh)
- [tools/prepare_myron_stock_except_product_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_stock_except_product_super.sh)
- [tools/prepare_myron_stock_product_miui_restore_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_stock_product_miui_restore_super.sh)

## Related Docs

- [HANDOFF.md](/Users/benny/Homelab/ROM/HANDOFF.md)
- [device/xiaomi/myron](/Users/benny/Homelab/ROM/device/xiaomi/myron)
- [device/xiaomi/sm8850-common](/Users/benny/Homelab/ROM/device/xiaomi/sm8850-common)
- [vendor/xiaomi/myron](/Users/benny/Homelab/ROM/vendor/xiaomi/myron)
