# Poco F8 Ultra (`myron`) Bring-up Status

Last updated: 2026-03-20

## Summary

This repository is for LineageOS bring-up on Xiaomi Poco F8 Ultra (`myron` / `sm8850`).

Current project state:
- the only confirmed booting custom path is the stock-based hybrid rollback branch
- the recent Lineage convergence work has reached a confirmed blocker in `systemserverclasspath.pb`
- the latest partial rollback guidance was too narrow; use the full hybrid rollback script from arbitrary mixed states
- fresh clean-builder artifacts exist, but the recent Family 2 / 2B / 2D images are reference-only because none of them booted

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

11. Stock-shaped carrier pivot
- patched stock `vendor_boot` plus stock `init_boot` passed `fastbootd`
- first-stage stopped being the primary blocker

12. Full Lineage `system` remained unbootable
- patched stock `vendor_boot` + stock `init_boot` + custom `system` still bootlooped
- stock `system_ext` did not save it

13. Family 2 protobuf isolation
- changing both `bootclasspath.pb` and `systemserverclasspath.pb` broke the booting baseline

14. Family 2b isolation
- changing only `systemserverclasspath.pb` still broke the booting baseline
- `systemserverclasspath.pb` is a confirmed blocker surface

15. Family 2d widening
- adding `org.lineageos.platform.jar` plus the matching Lineage-side `systemserverclasspath.pb` still bootlooped
- the missing jar was not sufficient to explain the failure by itself

## What This Proves

1. A stock-based `system_a` runtime core can boot on this device.
2. The first-stage carrier can be made good enough to pass `fastbootd`.
3. The critical remaining blocker moved into `system`.
4. `system_ext` is not the first blocker.
5. `systemserverclasspath.pb` is a confirmed blocker surface.
6. Adding `org.lineageos.platform.jar` alone is not sufficient to make the Lineage-side `systemserverclasspath` transition bootable.

## Current Recovery Rule

If the device is in a mixed failed state, use the full hybrid rollback:

```bash
cd /home/john/android/lineage_clean
DRY_RUN=0 bash tools/recover_myron_hybrid_rollback_slot_a.sh /home/john/android/lineage_clean myron
```

Do not assume that flashing only `system_a` and `vbmeta_system_a` is enough to recover the booting branch.

## Current Clean Builder State

Active clean builder:
- `/home/john/android/lineage_clean`

Old builder:
- `/home/john/android/lineage`
- forensic reference only

Clean builder status:
- produced the Family 2 / 2B / 2D artifacts successfully
- those artifacts are not a booting path
- they should be treated as analysis artifacts, not as the next flash default

## Current Known Blocker

Confirmed blocker surface:
- `system/etc/classpaths/systemserverclasspath.pb`

Current highest-confidence conclusion:
- the broader Lineage-side `systemserverclasspath` transition is incompatible with the kept booting Family 0 `system`

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

Recover to the known-good hybrid branch and stop there.

The next future attempt should start from the confirmed `systemserverclasspath` dead end, not from the older matched-stack plan.

For full historical context:
- [HANDOFF.md](/Users/benny/Homelab/ROM/HANDOFF.md)
- [myron_builder_reset_20260319.md](/Users/benny/Homelab/ROM/tools/runbooks/myron_builder_reset_20260319.md)
- [myron_bringup_history_20260319.md](/Users/benny/Homelab/ROM/tools/runbooks/myron_bringup_history_20260319.md)
