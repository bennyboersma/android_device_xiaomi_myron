# Poco F8 Ultra (`myron`) Bring-up Status

Last updated: 2026-03-13

## Summary

This repository is for LineageOS bring-up on Xiaomi Poco F8 Ultra (`myron` / SM8850 / `canoe` / `kaanapali`).

Current project state:
- stock Android is safe and booting on slot `a`
- there is still no confirmed custom userspace boot
- custom `super.img` flashing works
- failed custom boots are recoverable with the full stock boot chain plus stock `super`
- the broad stock-slice rollback matrix is now closed
- custom `product` alone is enough to break boot
- restoring full stock `product`, stock `system_ext`, or stock `system` on top of that does not fix boot
- the next stage is failure-signature and userspace-composition analysis, not broader partition swaps

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

The broad stock-slice rollback matrix is now closed:
- stock-everything-except-product still fails
- stock `product` with custom `system` and `system_ext` still fails
- stock `product` plus stock `system_ext` still fails
- stock `product` plus stock `system` still fails

Meaning:
- custom `product` alone is sufficient to break boot
- whole-partition rollback of `product`, `system_ext`, or `system` does not move the failure
- the stable blocker now looks like a tighter cross-partition composition problem:
  - package parsing
  - package duplication
  - privilege/layout mismatch
  - overlay/package-manager conflicts
- further broad stock-slice flashing is no longer the default path

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

Focus has shifted from broad rollback controls to stable-failure analysis:
- keep the lower stock baseline frozen for future targeted tests
- stop building larger stock-slice `super` controls unless a later finding justifies reopening that branch
- the first targeted package-conflict cleanup control is now complete and was **sideways**
- the targeted security-contract restore control is now also complete and was **sideways**
- both owner-conflict family controls are now also complete and **sideways**
- the external-claimant restore control and the `yellowpage/rom` owner restore are now also complete and **sideways**
- the next stage is runtime package-state and framework-policy analysis, not more APK-owner restore images

Current best next work:
1. freeze the completed targeted issue classes:
   - package-conflict cleanup
   - security privilege/layout restore
   - `com.miui.cloudservice` / `com.xiaomi.finddevice` owner-family control
   - `com.miui.securitycenter` / `com.miui.securityadd` / `com.mi.android.globalFileexplorer` owner-family control
   - external-claimant restore
   - `yellowpage/rom` owner restore
2. stop building more narrow restore images until a runtime-state finding justifies one
3. treat the surviving blocker as a package-state / framework-policy problem:
   - stock creates valid runtime permission state for `com.miui.rom`, `com.miui.yellowpage`, `com.xiaomi.aicr`, and `com.xiaomi.scanner`
   - failing custom userspace still reports `Missing permission state` for those same packages
4. trace the runtime/package-policy path through:
   - `frameworks/base/services/core/java/com/android/server/pm/Settings.java`
   - `frameworks/base/services/permission/java/com/android/server/permission/access/permission/AppIdPermissionPolicy.kt`
   - `frameworks/base/core/java/android/app/SystemServiceRegistry.java`
5. only build another image if that analysis identifies one concrete missing runtime-state input or one concrete framework-policy fix

Completed targeted package-conflict control:
- image:
  - `/home/john/android/lineage/out/target/product/myron/super_product_pkg_cleanup.img`
- bundle:
  - `/home/john/android/lineage/_checkpoints/postfailure_myron_product_pkg_cleanup_20260313_173920`
- comparison against `postfailure_myron_stock_product_stock_system_20260313_141009`:
  - `classification=sideways`
  - stage score stayed `5 -> 5`
- the exact targeted signatures still survived unchanged:
  - `/product/app/Calendar`
  - `/product/app/GoogleCalendarSyncAdapter`
  - `/product/app/messaging`
  - `/product/app/MiuiCalendarGlobalPad`
  - `/product/priv-app/MiuiCalendarGlobalPad`
  - duplicate `com.miui.miwallpaper.overlay`
  - duplicate `com.miui.wallpaper.overlay`
  - duplicate provider/component declarations such as `com.miui.cloudservice/androidx.core.content.FileProvider`
  - `Manager wrapper not available: security`

Current default next issue class from the March 13 reports:
Completed targeted security-contract restore control:
- image:
  - `/home/john/android/lineage/out/target/product/myron/super_product_security_contract.img`
- bundle:
  - `/home/john/android/lineage/_checkpoints/postfailure_myron_product_security_contract_20260313_183049`
- comparison against `postfailure_myron_product_pkg_cleanup_20260313_173920`:
  - `classification=sideways`
  - stage score stayed `5 -> 5`
- the specific security-side warnings still survived unchanged:
  - `com.miui.cloudservice/androidx.core.content.FileProvider`
  - `miui.cloud.finddevice.AccessFindDevice`
  - `miui.cloud.finddevice.ManageFindDevice`
  - `com.miui.securitycenter.POWER_CENTER_COMMON_PERMISSION`
  - `com.miui.securitycenter.permission.CONTROL_VPN`
  - `Manager wrapper not available: security`

The two targeted issue classes now exhausted:
- package-conflict cleanup
- security privilege/layout restore

Completed owner-conflict tooling and controls:
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

The owner-family controls now also exhausted:
- `com.miui.cloudservice` / `com.xiaomi.finddevice`
- `com.miui.securitycenter` / `com.miui.securityadd` / `com.mi.android.globalFileexplorer`

Completed external-claimant and `yellowpage/rom` controls:
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
- runtime package-state and framework-policy analysis
- latest reports:
  - `/home/john/android/lineage/_checkpoints/stock_runtime_packages_20260313_222827/summary.md`
  - `/home/john/android/lineage/_checkpoints/fake_package_flow_20260313_222827/summary.md`
  - `/home/john/android/lineage/_checkpoints/runtime_state_gaps_20260313_224150/summary.md`
  - `/home/john/android/lineage/_checkpoints/framework_policy_paths_20260313_224328/summary.md`
- newest valid failing baseline bundle:
  - `/home/john/android/lineage/_checkpoints/postfailure_myron_20260313_221344`
- stock runtime truth now confirms:
  - `com.miui.rom` is a real framework APK identity from `/system_ext/framework/framework-ext-res/framework-ext-res.apk`
  - `com.miui.yellowpage` is a real stock package on the live device at `/product/priv-app/MIUIYellowPageGlobal/MIUIYellowPageGlobal.apk`
  - `com.xiaomi.aicr` is a stock product priv-app at `/product/priv-app/MIUIAICR/MIUIAICR.apk`
  - `com.xiaomi.scanner` is a stock product data-app at `/product/data-app/MiuiScanner/MiuiScanner.apk`
- but the failing custom userspace still reports:
  - `Missing permission state for package com.miui.rom`
  - `Missing permission state for package com.miui.yellowpage`
  - `Missing permission state for package com.xiaomi.aicr`
  - `Missing permission state for package com.xiaomi.scanner`
- source-level choke points are now identified:
  - `Settings.java:6522` emits `Missing permission state` when per-user runtime-permission entries are absent
  - `AppIdPermissionPolicy.kt:505` emits the duplicate system-owner warnings
  - `SystemServiceRegistry.java:2111` emits `Manager wrapper not available: security` as downstream fallout
- current conclusion:
  - do not build another image yet
  - the next fix is more likely a `system` / `system_ext` framework-policy or runtime-state-input fix than another `product` APK restore

The older vendor/odm contract-restoration work is still useful history, but it is no longer the default strategy, and the broad product-first ladder is now complete.

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
- [tools/analyze_myron_failure_signatures.sh](/Users/benny/Homelab/ROM/tools/analyze_myron_failure_signatures.sh)
- [tools/diff_myron_effective_userspace.sh](/Users/benny/Homelab/ROM/tools/diff_myron_effective_userspace.sh)
- [tools/inspect_myron_product_pkg_conflicts.sh](/Users/benny/Homelab/ROM/tools/inspect_myron_product_pkg_conflicts.sh)
- [tools/prepare_myron_product_pkg_cleanup_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_product_pkg_cleanup_super.sh)
- [tools/inspect_myron_security_contract.sh](/Users/benny/Homelab/ROM/tools/inspect_myron_security_contract.sh)
- [tools/prepare_myron_product_security_contract_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_product_security_contract_super.sh)
- [tools/inspect_myron_owner_conflicts.sh](/Users/benny/Homelab/ROM/tools/inspect_myron_owner_conflicts.sh)
- [tools/prepare_myron_product_cloudservice_owner_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_product_cloudservice_owner_super.sh)
- [tools/prepare_myron_product_security_owner_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_product_security_owner_super.sh)
- [tools/inspect_myron_preinstall_claimants.sh](/Users/benny/Homelab/ROM/tools/inspect_myron_preinstall_claimants.sh)
- [tools/prepare_myron_product_external_claimants_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_product_external_claimants_super.sh)
- [tools/prepare_myron_product_yellowpage_rom_owner_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_product_yellowpage_rom_owner_super.sh)
- [tools/inspect_myron_stock_runtime_packages.sh](/Users/benny/Homelab/ROM/tools/inspect_myron_stock_runtime_packages.sh)
- [tools/inspect_myron_fake_package_flow.sh](/Users/benny/Homelab/ROM/tools/inspect_myron_fake_package_flow.sh)
- [tools/analyze_myron_runtime_state_gaps.sh](/Users/benny/Homelab/ROM/tools/analyze_myron_runtime_state_gaps.sh)
- [tools/inspect_myron_framework_policy_paths.sh](/Users/benny/Homelab/ROM/tools/inspect_myron_framework_policy_paths.sh)

## Related Docs

- [HANDOFF.md](/Users/benny/Homelab/ROM/HANDOFF.md)
- [device/xiaomi/myron](/Users/benny/Homelab/ROM/device/xiaomi/myron)
- [device/xiaomi/sm8850-common](/Users/benny/Homelab/ROM/device/xiaomi/sm8850-common)
- [vendor/xiaomi/myron](/Users/benny/Homelab/ROM/vendor/xiaomi/myron)
