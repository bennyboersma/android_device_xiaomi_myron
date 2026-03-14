# Poco F8 Ultra (`myron`) Bring-up Status

Last updated: 2026-03-15

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
- package-removal slicing is no longer the leading strategy
- the next stage is runtime partition provenance, not more package-semantic guesses

## Newest High-Signal Result

Boot-priority control:
- image:
  - [/home/john/android/lineage/out/target/product/myron/super_boot_priority.img](/home/john/android/lineage/out/target/product/myron/super_boot_priority.img)
- bundle:
  - [/home/john/android/lineage/_checkpoints/postfailure_myron_boot_priority_20260314_232530](/home/john/android/lineage/_checkpoints/postfailure_myron_boot_priority_20260314_232530)

What it proved:
- the repacked `product_boot_priority.img` and `system_ext_boot_priority.img` were extracted offline and do not contain:
  - `MIUICloudServiceGlobal`
  - `MIUIMiCloudSync`
  - `MIUISecurityCenterGlobal`
  - `MIUISecurityAdd`
  - `MIUIFileExplorerGlobal`
  - `FindDevice`
- the failed custom boot still logged those same package families from `/product/...` and `/system_ext/...`
- so image contents and effective runtime package set no longer match

Current default interpretation:
1. wrong mounted source for `/product` or `/system_ext`
2. runtime rebind / overlay / snapshot-backed view
3. package-manager reconstruction only if mounted-disk evidence comes back clean

Current default baseline:
- [/home/john/android/lineage/_checkpoints/postfailure_myron_boot_priority_20260314_232530](/home/john/android/lineage/_checkpoints/postfailure_myron_boot_priority_20260314_232530)

Current default next tools:
- [prepare_myron_partition_provenance_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_partition_provenance_super.sh)
- [capture_myron_postfailure_bundle.sh](/Users/benny/Homelab/ROM/tools/capture_myron_postfailure_bundle.sh)
- [analyze_myron_partition_provenance.sh](/Users/benny/Homelab/ROM/tools/analyze_myron_partition_provenance.sh)

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

Focus has shifted again, from framework-side runtime-state patching to runtime-source attribution and the surviving MIUI owner/provider/security graph:
- keep the lower stock baseline frozen for future targeted tests
- keep the completed restore-image controls frozen; that lane is exhausted
- the framework/runtime-state experiments produced one useful discriminator:
  - the flashed no-preopt image really contained only the patched `system/framework/services.jar`
  - the compiled `Settings$RuntimePermissionPersistence` bytecode is patched
  - but live logs still emitted the old plain `PackageSettings` warning text
- the clean-data + no-preopt run finally moved the visible behavior:
  - previous no-preopt run: blind stall
  - clean-data no-preopt run: bootloop
- the clean-data + no-preopt captured failed segment also changed:
  - the broad `Missing permission state ...` wave is absent there
  - the surviving failures are now centered on the MIUI owner/provider/security graph

Current best next work:
1. freeze the completed targeted issue classes:
   - package-conflict cleanup
   - security privilege/layout restore
   - `com.miui.cloudservice` / `com.xiaomi.finddevice` owner-family control
   - `com.miui.securitycenter` / `com.miui.securityadd` / `com.mi.android.globalFileexplorer` owner-family control
   - external-claimant restore
   - `yellowpage/rom` owner restore
   - combined runtime-state-inputs restore
2. stop building more restore images until the surviving runtime blocker is better explained
3. treat stale runtime reuse as part of the earlier noise:
   - removing `/system` `services` preopt alone did not move logs
   - removing `/system` `services` preopt plus wiping `data` did change visible behavior
4. treat the current active blocker as the surviving MIUI owner/provider/security path:
   - duplicate provider: `com.miui.cloudservice/androidx.core.content.FileProvider`
   - duplicate owners:
     - `POWER_CENTER_COMMON_PERMISSION`
     - `READ_AIACTION`
     - `SYSTEM_PERMISSION_DECLARE`
     - `CONTROL_VPN`
     - `miui.cloud.finddevice.*`
   - repeated `Manager wrapper not available: security`
5. pivot the next source-level work toward:
   - `com.miui.cloudservice` / `com.xiaomi.finddevice`
   - `com.miui.securitycenter` / `com.miui.securityadd` / `com.mi.android.globalFileexplorer`
   - `SystemServiceRegistry` `security` service fetch fallout
6. keep the runtime-source attribution result recorded:
   - built source is patched
   - compiled `services.core.unboosted` bytecode is patched
   - flashed no-preopt image contains only the patched `services.jar`
   - live logs still show the old plain warning text
   - so the patched `Settings` warning path is not the active on-device emitter in the captured failing boot

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

Completed clean-data and combined runtime-state-inputs controls:
- clean-data rerun of `yellowpage/rom` owner restore:
  - marker: `/home/john/android/lineage/_checkpoints/myron_prepare_20260313_230205`
  - bundle: `/home/john/android/lineage/_checkpoints/postfailure_myron_clean_data_20260313_232200`
  - comparison against `postfailure_myron_20260313_213402`:
    - `classification=sideways`
    - stage score stayed `5 -> 5`
  - result:
    - wiping `data` did not change the visible failure class
    - stale carry-over poisoning was deprioritized, but deterministic first-boot state creation bugs remained possible
- combined runtime-state-inputs restore:
  - image: `/home/john/android/lineage/out/target/product/myron/super_product_runtime_state_inputs.img`
  - bundle: `/home/john/android/lineage/_checkpoints/postfailure_myron_20260314_012147`
  - comparison against `postfailure_myron_clean_data_20260313_232200`:
    - `classification=sideways`
    - stage score stayed `5 -> 5`
  - restored together:
    - `priv-app/MIUIYellowPageGlobal`
    - `priv-app/MIUIAICR`
    - `data-app/MiuiScanner`
    - `etc/device_features/myron.xml`
    - `etc/removable_apk_info.xml`
    - `etc/permissions/privapp-permissions-product.xml`
    - `pangu/system/etc/permissions/signature-permission-pangu.xml`
    - `/system_ext/framework/framework-ext-res`
  - important log result:
    - same duplicate owner/provider graph survived unchanged
    - `Manager wrapper not available: security` survived unchanged
    - the failed segment again showed a broad `Missing permission state ...` wave

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
- newest valid failing baseline bundle:
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
  - `Settings.java:6522` emits `Missing permission state` when per-user runtime-permission entries are absent
  - `AppIdPermissionPolicy.kt:505` emits the duplicate system-owner warnings
  - `SystemServiceRegistry.java:2111` emits `Manager wrapper not available: security` as downstream `null` service fetch fallout
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
  - do not build another restore image
  - the restore-image lane is exhausted again
  - the next useful control is framework-side, not another `product` restore
  - current framework patch status:
    - builder-side `systemimage` rebuild is in progress for a `Settings.java` normalization patch
    - no flash result exists yet for that patch

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
- [tools/prepare_myron_runtime_state_diag_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_runtime_state_diag_super.sh)
- [tools/analyze_myron_runtime_state_diag.sh](/Users/benny/Homelab/ROM/tools/analyze_myron_runtime_state_diag.sh)
- [tools/prepare_myron_runtime_state_no_preopt_super.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_runtime_state_no_preopt_super.sh)

## Related Docs

- [HANDOFF.md](/Users/benny/Homelab/ROM/HANDOFF.md)
- [device/xiaomi/myron](/Users/benny/Homelab/ROM/device/xiaomi/myron)
- [device/xiaomi/sm8850-common](/Users/benny/Homelab/ROM/device/xiaomi/sm8850-common)
- [vendor/xiaomi/myron](/Users/benny/Homelab/ROM/vendor/xiaomi/myron)
