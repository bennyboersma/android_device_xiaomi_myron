# Myron AI Handoff

Last updated: 2026-03-13

## Current Status

The phone is safe on stock Android on slot `a`.

Current verified state:
- custom `super.img` flashing works
- stock recovery works with the full stock boot chain plus stock `super`
- there is still no confirmed custom userspace boot
- the best custom result is a real bootloop before fallback to `fastboot`
- broad stock-slice rollback testing is now closed
- newest control says custom `product` alone is enough to break boot
- whole-partition rollback of `product`, `system_ext`, and `system` all stayed sideways
- next work is failure-signature and effective-userspace analysis

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

So the current primary suspect is now custom `product`, more specifically the MIUI-facing framework surface it carries and injects into `/system`, not the lower vendor stack.

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

5. Stock-everything-except-product control:
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
- still failed
- strongest new conclusion:
  - custom `product` alone is enough to break boot

6. Focused stock-vs-custom `product` diff:
- stock `product` file count: `1613`
- custom `product` file count: `521`
- focused boot-relevant surface (`framework`, `priv-app`, `app`, overlays, permissions, sysconfig):
  - stock: `451`
  - custom: `157`
- strongest stock-only gaps:
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
- highest-signal package mismatch:
  - stock carries `MIUISecurityCenterGlobal` as `priv-app`
  - custom currently carries it only as plain `app`
- interpretation:
  - this looks like a missing MIUI `product` contract, not a lower-stack vendor failure

## What To Do Next

1. Treat the broad rollback matrix as complete:
   - `stock product` stayed sideways
   - `stock product + stock system_ext` stayed sideways
   - `stock product + stock system` stayed sideways
2. Treat the targeted issue classes below as complete and exhausted:
   - package-conflict cleanup
   - security privilege/layout restore
3. Stop creating broader stock-slice controls unless a later focused finding reopens that branch.
4. Pivot to owner-conflict isolation:
   - add `tools/inspect_myron_owner_conflicts.sh`
   - report all visible owners for the surviving provider/permission conflicts
   - identify the canonical stock owner
   - recommend one owner-family control
5. Use `/home/john/android/lineage/_checkpoints/postfailure_myron_product_security_contract_20260313_183049` as the new nearest baseline.
6. Start with the `com.miui.cloudservice` vs `com.xiaomi.finddevice` owner-conflict family unless the new inspection disproves it.
7. If that family is still sideways, move next to the `com.miui.securitycenter` / `com.miui.securityadd` owner-conflict family.
8. Keep `system/bin/init` instrumentation and broad property experiments deprioritized.

Completed targeted package-conflict control:
- image:
  - `/home/john/android/lineage/out/target/product/myron/super_product_pkg_cleanup.img`
- bundle:
  - `/home/john/android/lineage/_checkpoints/postfailure_myron_product_pkg_cleanup_20260313_173920`
- comparison against `postfailure_myron_stock_product_stock_system_20260313_141009`:
  - `classification=sideways`
  - stage score stayed `5 -> 5`
- the targeted package-duplication / parse-path issue class did not move the failure
- the exact parse/duplicate/provider signatures survived unchanged:
  - `/product/app/Calendar`
  - `/product/app/GoogleCalendarSyncAdapter`
  - `/product/app/messaging`
  - `/product/app/MiuiCalendarGlobalPad`
  - `/product/priv-app/MiuiCalendarGlobalPad`
  - duplicate `com.miui.miwallpaper.overlay`
  - duplicate `com.miui.wallpaper.overlay`
  - duplicate provider/component declarations such as `com.miui.cloudservice/androidx.core.content.FileProvider`
  - `Manager wrapper not available: security`

Current default next issue class from the new reports:
Completed targeted security-contract restore control:
- image:
  - `/home/john/android/lineage/out/target/product/myron/super_product_security_contract.img`
- bundle:
  - `/home/john/android/lineage/_checkpoints/postfailure_myron_product_security_contract_20260313_183049`
- comparison against `postfailure_myron_product_pkg_cleanup_20260313_173920`:
  - `classification=sideways`
  - stage score stayed `5 -> 5`
- the targeted security-contract issue class did not move the failure
- the specific surviving conflict set is now centered on ownership:
  - `com.miui.cloudservice/androidx.core.content.FileProvider`
  - `miui.cloud.finddevice.AccessFindDevice`
  - `miui.cloud.finddevice.ManageFindDevice`
  - `com.miui.securitycenter.POWER_CENTER_COMMON_PERMISSION`
  - `com.miui.securitycenter.permission.CONTROL_VPN`
  - `Manager wrapper not available: security`

Current default next issue class:
- owner-conflict isolation for surviving provider/permission ownership
- security-contract inspection report:
  - `/home/john/android/lineage/_checkpoints/security_contract_inspection_20260313_175857/summary.md`
- new nearest baseline:
  - `/home/john/android/lineage/_checkpoints/postfailure_myron_product_security_contract_20260313_183049`
- first owner-conflict family to isolate:
  - `com.miui.cloudservice` vs `com.xiaomi.finddevice`
- second family if the first stays sideways:
  - `com.miui.securitycenter` / `com.miui.securityadd`
- next planned tooling:
  - `tools/inspect_myron_owner_conflicts.sh`
  - intended output:
    - report all visible owners for the surviving provider/permission conflicts
    - identify the canonical stock owner
    - recommend one owner-family control

Current mechanism that still matters:
- Xiaomi overlays `/product/pangu/system/*` back into `/system/*` through [fstab.qcom](/Users/benny/Homelab/ROM/device/xiaomi/sm8850-common/init/fstab.qcom#L63)
- stock `product` has that subtree; custom `product` does not
- but restoring whole stock `product` alone was still not enough, so the problem is now likely layout/composition rather than raw absence of one whole partition

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
- stock-except-product control:
  - [/home/john/android/lineage/out/target/product/myron/super_stock_except_product.img](/home/john/android/lineage/out/target/product/myron/super_stock_except_product.img)
- targeted stock-MIUI-product restore helper:
  - [tools/prepare_myron_stock_product_miui_restore_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_stock_product_miui_restore_super.sh)
- failure-signature analyzer:
  - [tools/analyze_myron_failure_signatures.sh](/Users/benny/Homelab/ROM/tools/analyze_myron_failure_signatures.sh)
- effective-userspace diff:
  - [tools/diff_myron_effective_userspace.sh](/Users/benny/Homelab/ROM/tools/diff_myron_effective_userspace.sh)
- product package-conflict inspector:
  - [tools/inspect_myron_product_pkg_conflicts.sh](/Users/benny/Homelab/ROM/tools/inspect_myron_product_pkg_conflicts.sh)
- product package-cleanup builder:
  - [tools/prepare_myron_product_pkg_cleanup_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_product_pkg_cleanup_super.sh)
- security-contract inspector:
  - [tools/inspect_myron_security_contract.sh](/Users/benny/Homelab/ROM/tools/inspect_myron_security_contract.sh)
- security-contract builder:
  - [tools/prepare_myron_product_security_contract_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_product_security_contract_super.sh)

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
- Stock-except-product control image:
  - [/home/john/android/lineage/out/target/product/myron/super_stock_except_product.img](/home/john/android/lineage/out/target/product/myron/super_stock_except_product.img)
- Next targeted control output:
  - [/home/john/android/lineage/out/target/product/myron/super_stock_product_miui_restore.img](/home/john/android/lineage/out/target/product/myron/super_stock_product_miui_restore.img)
