# Myron AI Handoff

Last updated: 2026-03-15

## Current Status

The phone is safe on stock Android on slot `a`.

Current verified state:
- upper-stack-only flashing through `fastbootd` works reliably
- stock userspace restore works reliably
- there is still no confirmed custom userspace boot
- the latest clean boot-first runs wipe both `userdata` and `metadata`
- even with that clean wipe, the bootloop remains in late userspace
- even with effectively empty flashed `product` and `system_ext`, the same Xiaomi runtime package set still appears
- the leading root-cause theory is now MIUI preinstall/materialization rebuilding a Xiaomi package graph during boot

## Newest Result

Empty-upper forcing-function bundle:
- [/home/john/android/lineage/_checkpoints/postfailure_myron_lineage_empty_upper_20260315_180520](/home/john/android/lineage/_checkpoints/postfailure_myron_lineage_empty_upper_20260315_180520)

What it proved:
- clean wipes do not remove the active blocker
- the flashed upper APK payload is not the only source of the runtime Xiaomi package graph
- the same failed-boot markers survive:
  - `/product/app/MIUICloudServiceGlobal`
  - `/product/app/MIUIFileExplorerGlobal`
  - `/product/app/MIUISecurityAdd`
  - `/product/priv-app/MIUISecurityCenterGlobal`
  - `/system_ext/priv-app/FindDevice`
  - duplicate `com.miui.cloudservice/...FileProvider`
  - duplicate `miui.cloud.finddevice.*`
  - `Manager wrapper not available: security`

## Current Interpretation

Default branch order now:
1. Disable MIUI preinstall/materialization in the Lineage-first upper stack.
2. Re-test with the same stock lower stack and clean wipe flow.
3. Only return to deeper runtime-source archaeology if the Xiaomi-heavy signature survives even with preinstall disabled.

Current baseline bundles:
- [/home/john/android/lineage/_checkpoints/postfailure_myron_lineage_empty_upper_20260315_180520](/home/john/android/lineage/_checkpoints/postfailure_myron_lineage_empty_upper_20260315_180520)
- [/home/john/android/lineage/_checkpoints/postfailure_myron_lineage_first_upper_stack_clean_20260315_172841](/home/john/android/lineage/_checkpoints/postfailure_myron_lineage_first_upper_stack_clean_20260315_172841)

Current active tools:
- [prepare_myron_lineage_first_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_lineage_first_super.sh)
- [prepare_myron_lineage_first_avb_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_lineage_first_avb_super.sh)
- [prepare_myron_lineage_empty_upper_avb.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_lineage_empty_upper_avb.sh)
- [flash_myron_upper_stack_via_fastbootd.sh](/Users/benny/Homelab/ROM/tools/flash_myron_upper_stack_via_fastbootd.sh)
- [run_myron_lineage_first_upper_stack_clean.sh](/Users/benny/Homelab/ROM/tools/run_myron_lineage_first_upper_stack_clean.sh)

## Current Fix Path

The current fix path is based on MIUI preinstall evidence from failed boot logs:
- `MiuiPreinstallHelper init`
- `MiuiPreinstallHelper: use Miui Preinstall Frame.`
- `MiuiPreinstallHelper scan preinstall`

And confirmed stock properties:
- `ro.miui.preinstall_to_data=1`
- `ro.miui.cust_img_path=/data/preinstall/cust.img`
- `ro.miui.pai.preinstall.path=/data/miui/pai/`
- `ro.appsflyer.preinstall.path=/data/miui/pai/pre_install.appsflyer`

The current mitigation disables those inputs in the flashed `product` image:
- `ro.miui.preinstall_to_data=0`
- `ro.miui.has_cust_partition=0`
- `ro.miui.cust_erofs=0`
- `ro.miui.cust_img_path=/dev/null`
- `ro.miui.pai.preinstall.path=/dev/null`
- `ro.appsflyer.preinstall.path=/dev/null`

Implemented in:
- [device/xiaomi/myron/device.mk](/Users/benny/Homelab/ROM/device/xiaomi/myron/device.mk)
- [prepare_myron_lineage_first_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_lineage_first_super.sh)

Latest signed artifacts carrying this change:
- `/home/john/android/lineage/_checkpoints/lineage_first_avb_super_myron_20260315_181743/`

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
   - `com.miui.cloudservice` / `com.xiaomi.finddevice` owner-family control
   - `com.miui.securitycenter` / `com.miui.securityadd` / `com.mi.android.globalFileexplorer` owner-family control
   - external-claimant restore
   - `yellowpage/rom` owner restore
   - combined runtime-state-inputs restore
3. Treat the framework/runtime-state patch lane as diagnostic history, not the current default fix lane:
   - built source is patched
   - compiled `services.core.unboosted` bytecode is patched
   - flashed no-preopt image contains only the patched `services.jar`
   - live logs still emit the old plain `PackageSettings` warning text
4. Record the useful discriminator:
   - removing `/system` `services` preopt alone did not move the log shape
   - removing `/system` `services` preopt and wiping `data` changed visible behavior to a bootloop
   - the clean-data + no-preopt captured failed segment no longer shows the broad `Missing permission state ...` wave
5. Use `/home/john/android/lineage/_checkpoints/postfailure_myron_clean_data_no_preopt_20260314_155244` as the newest high-signal failing bundle.
6. Treat the current active blocker as the surviving MIUI owner/provider/security path:
   - duplicate provider `com.miui.cloudservice/androidx.core.content.FileProvider`
   - duplicate MIUI permission-owner conflicts:
     - `POWER_CENTER_COMMON_PERMISSION`
     - `READ_AIACTION`
     - `SYSTEM_PERMISSION_DECLARE`
     - `CONTROL_VPN`
     - `miui.cloud.finddevice.*`
   - repeated `Manager wrapper not available: security`
7. Focus the next source-level work on:
   - `com.miui.cloudservice` / `com.xiaomi.finddevice`
   - `com.miui.securitycenter` / `com.miui.securityadd` / `com.mi.android.globalFileexplorer`
   - `SystemServiceRegistry` `security` fetch fallout
8. Keep `system/bin/init` instrumentation, broad property experiments, and new restore-image slicing deprioritized.

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
- owner-conflict inspection report:
  - `/home/john/android/lineage/_checkpoints/owner_conflicts_20260313_184219/summary.md`
- first owner-family control:
  - image: `/home/john/android/lineage/out/target/product/myron/super_product_cloudservice_owner.img`
  - bundle: `/home/john/android/lineage/_checkpoints/postfailure_myron_product_cloudservice_owner_20260313_200712`
  - comparison against `postfailure_myron_product_security_contract_20260313_183049`:
    - `classification=sideways`
    - stage score stayed `5 -> 5`
  - unchanged target-family signatures:
    - `Provider ComponentInfo{com.miui.cloudservice/androidx.core.content.FileProvider} already defined`
    - `miui.cloud.finddevice.AccessFindDevice`
    - `miui.cloud.finddevice.ManageFindDevice`
- second owner-family control:
  - image: `/home/john/android/lineage/out/target/product/myron/super_product_security_owner.img`
  - bundle: `/home/john/android/lineage/_checkpoints/postfailure_myron_product_security_owner_20260313_203158`
  - comparison against `postfailure_myron_product_cloudservice_owner_20260313_200712`:
    - `classification=sideways`
    - stage score stayed `5 -> 5`
  - unchanged target-family signatures:
    - `Missing permission state for package com.miui.securityadd`
    - `Missing permission state for package com.mi.android.globalFileexplorer`
    - `com.miui.securitycenter.permission.SYSTEM_PERMISSION_DECLARE`
    - `com.miui.securitycenter.permission.CONTROL_VPN`
    - `com.miui.securitycenter.POWER_CENTER_COMMON_PERMISSION`
    - `Manager wrapper not available: security`

Current default next issue class:
- deeper static ownership/source analysis around the remaining external claimants
- supporting reports:
  - `/home/john/android/lineage/_checkpoints/owner_conflicts_20260313_184219/summary.md`
  - `/home/john/android/lineage/_checkpoints/security_contract_inspection_20260313_175857/summary.md`
- external-claimant restore:
  - image: `/home/john/android/lineage/out/target/product/myron/super_product_external_claimants.img`
  - bundle: `/home/john/android/lineage/_checkpoints/postfailure_myron_20260313_213402`
  - comparison against `postfailure_myron_product_security_owner_20260313_203158`:
    - `classification=sideways`
    - stage score stayed `5 -> 5`
  - restored:
    - `data-app/MiuiScanner`
    - `priv-app/MIUIAICR`
    - `etc/device_features/myron.xml`
    - `etc/removable_apk_info.xml`
    - `etc/permissions/privapp-permissions-product.xml`
- `yellowpage/rom` owner restore:
  - image: `/home/john/android/lineage/out/target/product/myron/super_product_yellowpage_rom_owner.img`
  - bundle: `/home/john/android/lineage/_checkpoints/postfailure_myron_20260313_221344`
  - comparison against `postfailure_myron_20260313_213402`:
    - `classification=sideways`
    - stage score stayed `5 -> 5`
  - restored:
    - `/product/priv-app/MIUIYellowPageGlobal`
    - `/system_ext/framework/framework-ext-res`

Current default next issue class:
- runtime-state materialization analysis
- latest reports:
  - `/home/john/android/lineage/_checkpoints/stock_runtime_packages_20260313_222827/summary.md`
  - `/home/john/android/lineage/_checkpoints/fake_package_flow_20260313_222827/summary.md`
  - `/home/john/android/lineage/_checkpoints/runtime_state_gaps_20260313_224150/summary.md`
  - `/home/john/android/lineage/_checkpoints/framework_policy_paths_20260313_224328/summary.md`
  - `/home/john/android/lineage/_checkpoints/owner_identity_graph_20260313_233251/summary.md`
  - `/home/john/android/lineage/_checkpoints/runtime_state_materialization_20260313_233251/summary.md`
  - `/home/john/android/lineage/_checkpoints/miui_reverse_trace_20260314_005227/summary.md`
- newest valid failing baseline:
  - `/home/john/android/lineage/_checkpoints/postfailure_myron_20260314_012147`
- stock runtime truth now confirms:
  - `com.miui.rom` is a real framework APK identity from `/system_ext/framework/framework-ext-res/framework-ext-res.apk`
  - `com.miui.yellowpage` is a real stock package on the live device at `/product/priv-app/MIUIYellowPageGlobal/MIUIYellowPageGlobal.apk`
  - `com.xiaomi.aicr` is a stock product priv-app at `/product/priv-app/MIUIAICR/MIUIAICR.apk`
  - `com.xiaomi.scanner` is a stock product data-app at `/product/data-app/MiuiScanner/MiuiScanner.apk`
- owner-identity reports now confirm the stock owner is winning the core duplicate-permission families:
  - `com.miui.rom` wins `POWER_CENTER_COMMON_PERMISSION`
  - `com.xiaomi.aicr` wins `READ_AIACTION`
  - `com.miui.securitycenter` wins `SYSTEM_PERMISSION_DECLARE`
  - `com.miui.securitycenter` wins `CONTROL_VPN`
- the latest combined runtime-state-inputs run still reports:
  - a broad `Missing permission state ...` wave in the failed segment
  - duplicate `com.miui.cloudservice/androidx.core.content.FileProvider`
  - duplicate `miui.cloud.finddevice.*`
  - duplicate `POWER_CENTER_COMMON_PERMISSION`
  - duplicate `READ_AIACTION`
  - duplicate `SYSTEM_PERMISSION_DECLARE`
  - duplicate `CONTROL_VPN`
- source-level choke points are now identified:
  - `frameworks/base/services/core/java/com/android/server/pm/Settings.java:6522`
  - `frameworks/base/services/permission/java/com/android/server/permission/access/permission/AppIdPermissionPolicy.kt:505`
  - `frameworks/base/core/java/android/app/SystemServiceRegistry.java:2111`
- newest sequencing evidence:
  - `/home/john/android/lineage/_checkpoints/permission_state_sequence_20260314_014131/summary.md`
  - `340` `Missing permission state ...` lines were found in the failed segment
  - the first missing-state line appears before `MiuiPreinstallHelper init`
  - target packages in that early wave include:
    - `com.miui.rom`
    - `com.miui.yellowpage`
    - `com.xiaomi.aicr`
    - `com.xiaomi.scanner`
    - `com.miui.securityadd`
- current conclusion:
  - do not build another generic restore image
  - the restore-image lane is exhausted again
  - stale runtime reuse was part of the earlier noise
  - the current active blocker is the surviving MIUI owner/provider/security path after the clean-data + no-preopt discriminator

Latest discriminator runs:
- no-preopt diagnostic run:
  - image:
    - `/home/john/android/lineage/out/target/product/myron/super_runtime_state_no_preopt.img`
  - bundle:
    - `/home/john/android/lineage/_checkpoints/postfailure_myron_20260314_152552`
  - result:
    - `classification=sideways`
    - old plain `PackageSettings` warning text still survived
- clean-data + no-preopt diagnostic run:
  - marker:
    - `/home/john/android/lineage/_checkpoints/myron_prepare_20260314_153403`
  - bundle:
    - `/home/john/android/lineage/_checkpoints/postfailure_myron_clean_data_no_preopt_20260314_155244`
  - comparison against `postfailure_myron_20260314_152552`:
    - `classification=sideways`
    - stage score stayed `5 -> 5`
  - important differences:
    - visible result changed to bootloop
    - the captured failed segment no longer shows the broad `Missing permission state ...` wave
    - surviving failures remain:
      - duplicate provider `com.miui.cloudservice/androidx.core.content.FileProvider`
      - duplicate MIUI permission-owner conflicts
      - repeated `Manager wrapper not available: security`

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
- preinstall claimant inspector:
  - [tools/inspect_myron_preinstall_claimants.sh](/Users/benny/Homelab/ROM/tools/inspect_myron_preinstall_claimants.sh)
- external-claimant builder:
  - [tools/prepare_myron_product_external_claimants_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_product_external_claimants_super.sh)
- `yellowpage/rom` owner builder:
  - [tools/prepare_myron_product_yellowpage_rom_owner_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_product_yellowpage_rom_owner_super.sh)
- stock runtime package inspector:
  - [tools/inspect_myron_stock_runtime_packages.sh](/Users/benny/Homelab/ROM/tools/inspect_myron_stock_runtime_packages.sh)
- fake-package flow inspector:
  - [tools/inspect_myron_fake_package_flow.sh](/Users/benny/Homelab/ROM/tools/inspect_myron_fake_package_flow.sh)
- runtime-state gap analyzer:
  - [tools/analyze_myron_runtime_state_gaps.sh](/Users/benny/Homelab/ROM/tools/analyze_myron_runtime_state_gaps.sh)
- framework policy path inspector:
  - [tools/inspect_myron_framework_policy_paths.sh](/Users/benny/Homelab/ROM/tools/inspect_myron_framework_policy_paths.sh)

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
