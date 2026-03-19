# Poco F8 Ultra (`myron`) Bring-up Status

Last updated: 2026-03-19

## Summary

This repository is for LineageOS bring-up on Xiaomi Poco F8 Ultra (`myron` / `sm8850`).

Current project state:
- stock Android is restored and safe
- the booting hybrid branch is frozen as rollback only
- app-layer migration is finished and no longer the main path
- the main path is now the lowest-risk Lineage bring-up ladder
- fresh Lineage artifacts are being rebuilt from the clean builder tree only
- active bring-up target = `lineage_myron_bringup-bp4a-userdebug`
- attempt 1 = stock `boot` + stock `init_boot` + stock `vendor_boot` + custom `system` + custom `system_ext` + custom `vbmeta_system`
- attempt 2 only if needed = same as attempt 1, but with Lineage `init_boot`

## Current Rollback Branch

Primary rollback branch:
- `system_a`:
  - [/home/john/android/lineage/out/target/product/myron/stock_based_system_cycle/system_stockbase_printrecommendation_extshared_captiveportal_pacprocessor_btmidi_camproxy_certinstaller_avb.img](/home/john/android/lineage/out/target/product/myron/stock_based_system_cycle/system_stockbase_printrecommendation_extshared_captiveportal_pacprocessor_btmidi_camproxy_certinstaller_avb.img)
  - sha256: `09fa2bb3712dbb32e11f0b2fc5ab4026c5bf257877929d543896eaed14380492`
- `vbmeta_system_a`:
  - [/home/john/android/lineage/out/target/product/myron/stock_based_system_cycle/vbmeta_system_stockbase_printrecommendation_extshared_captiveportal_pacprocessor_btmidi_camproxy_certinstaller.img](/home/john/android/lineage/out/target/product/myron/stock_based_system_cycle/vbmeta_system_stockbase_printrecommendation_extshared_captiveportal_pacprocessor_btmidi_camproxy_certinstaller.img)
  - sha256: `d7d522f2c08d7fdd1336f7389d5ef22e1077fb40e7cbfcf3fbb5cdbc2ded4928`

Rollback branch composition:
- `system_a` = rebuilt stock-based SAR system image
- `system_ext_a` = stock
- `product_a` = stock
- `mi_ext_a` = stock
- `vbmeta_system_a` = matching custom image for rebuilt `system_a`
- `vbmeta_a` = stock
- lower stack = stock

This branch boots to HyperOS UI and is recovery-only now.

## Proven Safe And Unsafe App Deltas

Safe on top of the stock-based hybrid branch:
- `PrintRecommendationService`
- `ExtShared`
- `CaptivePortalLogin`
- `PacProcessor`
- `BluetoothMidiService`
- `CameraExtensionsProxy`
- `CertInstaller`

Unsafe for now:
- `HTMLViewer`
- `DocumentsUI`
- `KeyChain`

Why those unsafe apps matter:
- `HTMLViewer` is not a simple viewer swap on stock; it carries MIUI/Settings/OTA/cloud behavior under the same package
- `DocumentsUI` changes package identity from `com.google.android.documentsui` to `com.android.documentsui`
- `KeyChain` regressed boot even though the manifest looked simple, so app-level safety is not enough by itself

## What We Tried So Far

1. Broad Lineage-heavy `system_a`
- failed early
- `POCO -> black -> POCO` style loop

2. SAR correction
- necessary
- not sufficient

3. AVB correction
- necessary
- not sufficient

4. Generic bootclasspath / framework micro-bridges
- not sufficient

5. Stock-based `system_a` pivot
- worked
- produced a booting baseline and then a stronger kept branch

6. App-layer micro-delta pass
- proved a selective set of app swaps is safe
- proved some apparently simple apps still block boot

7. System-ext sysconfig proof work
- identified package-scoped `system_ext` hooks for excluded apps
- not yet flashed as a standalone reduction cycle

8. Lineage-heavy `system_a` + `system_ext_a` test with stock first-stage
- still failed early
- no usable `adb` evidence

9. Clean builder reset
- old builder tree is no longer trusted for fresh artifacts
- clean tree at `/home/john/android/lineage_clean` is now the only build source for new Lineage-heavy tests

10. Bring-up target reduction
- `lineage_myron_bringup` now uses:
  - stock `boot`
  - stock `init_boot` by default
  - stock `vendor_boot`
  - no `mi_ext`
  - no overlay mounts in bring-up `fstab`
  - no inherited `manifest_kalama.xml`
  - a minimal bring-up manifest only
  - reduced common package surface for first `adb`

11. Current clean-build blocker sequence
- resolved:
  - `vendor_hal_soter_client` missing in Lineage QCOM sepolicy
  - broad inherited `manifest_kalama.xml` HAL surface
  - bring-up incorrectly defaulting to source `init_boot`
  - duplicate local `vendor_hal_soter*` declarations
- current build continues from the narrowed attempt-1 target

## What This Proves

1. A stock-based `system_a` runtime core can boot on this device.
2. Earlier Lineage-heavy failures were not just AVB or SAR mistakes.
3. Mixing stock first-stage behavior with Lineage-heavy userspace is a likely early blocker.
4. Hybrid polish is not the fastest route to Lineage anymore.
5. The next serious test should minimize first-stage change and keep `init_boot` stock by default.
6. The broad inherited common manifest/package surface was itself a blocker and has now been reduced for bring-up.

## Main Bring-up Path Now

Next serious bring-up branch:
- product target = `lineage_myron_bringup`
- `system_a` = Lineage-heavy SAR
- `system_ext_a` = Lineage-heavy
- `init_boot_a` = stock for attempt 1, Lineage-built only for attempt 2
- `vendor_boot_a` = stock
- `vbmeta_system_a` = matching custom image

Still stock for that first matched-stack test:
- `product_a`
- `mi_ext_a`
- `vbmeta_a`
- `vendor_a`
- `odm_a`
- `boot_a`
- `vendor_boot_a`
- lower stack other than `init_boot_a` on attempt 2

Bring-up config now also guarantees:
- no inherited `manifest_kalama.xml`
- no `mi_ext`
- no overlay remounts into Lineage partitions
- reduced common feature surface:
  - no NFC
  - no sensors
  - no thermal
  - no GNSS permission surface
  - no secure-element permission surface

Default success target:
- first boot to `adb`
- not first boot to UI

## Current Clean Builder State

Active clean builder:
- `/home/john/android/lineage_clean`

Old builder:
- `/home/john/android/lineage`
- forensic reference only

Clean builder status as of 2026-03-19:
- `m nothing`: passes
- `m checkvintf`: passes
- `m host_init_verifier`: passes
- full build running for:
  - `systemimage`
  - `systemextimage`
  - `vbmetasystemimage`

Attempt-1 artifacts are not accepted yet until all of these exist and are fresh:
- `system.img`
- `system_ext.img`
- `vbmeta_system.img`
and stock path presence is confirmed for:
- `init_boot.img`
- `vendor_boot.img`

## Current Known Blockers

The clean build is not flash-ready yet because:
- the 3 attempt-1 artifacts are not all present yet
- the bring-up contract gate must pass for:
  - minimal bring-up `fstab`
  - minimal bring-up manifest
  - bring-up product wiring
  - stock `init_boot` by default
  - no inherited `manifest_kalama.xml`

Legacy later-phase source-vendor output list:
- [boot_critical_vendor_outputs.txt](/Users/benny/Homelab/ROM/tools/boot_critical_vendor_outputs.txt)

## Current Logging And Flash Workflow

Use these scripts for the next serious Lineage bring-up run:
- [prepare_myron_log_capture.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_log_capture.sh)
- [first_boot_capture_and_diff.sh](/Users/benny/Homelab/ROM/tools/first_boot_capture_and_diff.sh)
- [capture_myron_postfailure_bundle.sh](/Users/benny/Homelab/ROM/tools/capture_myron_postfailure_bundle.sh)

Matched-stack bring-up helpers:
- [check_myron_clean_matched_stack_artifacts.sh](/Users/benny/Homelab/ROM/tools/check_myron_clean_matched_stack_artifacts.sh)
- [check_myron_clean_boot_critical_vendor_stack.sh](/Users/benny/Homelab/ROM/tools/check_myron_clean_boot_critical_vendor_stack.sh)
- [flash_myron_clean_matched_stack.sh](/Users/benny/Homelab/ROM/tools/flash_myron_clean_matched_stack.sh)
- [recover_myron_hybrid_rollback_slot_a.sh](/Users/benny/Homelab/ROM/tools/recover_myron_hybrid_rollback_slot_a.sh)
- [recover_myron_stock_slot_a.sh](/Users/benny/Homelab/ROM/tools/recover_myron_stock_slot_a.sh)

Runbook:
- [matched_lineage_first_stack_checklist.md](/Users/benny/Homelab/ROM/tools/runbooks/matched_lineage_first_stack_checklist.md)

## What Must Stay Frozen

Do not spend more cycles on:
- app-layer migration
- HTMLViewer/DocumentsUI/KeyChain retry work
- hybrid polish for its own sake

The hybrid branch is rollback only.

## Recommended Next Step

Wait for the clean build to finish, then:
1. run the attempt-1 artifact gate
2. run the bring-up contract gate
3. flash attempt 1 with stock `init_boot`
4. only if it fails the same way, enable custom `init_boot` for attempt 2

Keep in mind:
- do not proactively force a stronger `sm8750`/`kalama` fallback as a fix
- if the narrowed stock-first-stage userspace test still fails early, the next serious step is a real `kaanapali` kernel/vendor_boot bring-up

For full historical context:
- [HANDOFF.md](/Users/benny/Homelab/ROM/HANDOFF.md)
- [myron_builder_reset_20260319.md](/Users/benny/Homelab/ROM/tools/runbooks/myron_builder_reset_20260319.md)
- [myron_bringup_history_20260319.md](/Users/benny/Homelab/ROM/tools/runbooks/myron_bringup_history_20260319.md)
