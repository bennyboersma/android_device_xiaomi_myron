# Myron AI Handoff

Last updated: 2026-03-19

## Current Status

The device is safe on stock Android.

The booting hybrid branch remains available, but it is no longer the main effort.

Main effort now:
- lowest-risk Lineage bring-up ladder
- clean builder artifacts only
- first success target = boot to `adb`
- active bring-up target = `lineage_myron_bringup-bp4a-userdebug`
- attempt 1 = stock `boot` + stock `init_boot` + stock `vendor_boot` + custom `system` + custom `system_ext` + custom `vbmeta_system`
- attempt 2 only if needed = stock `boot` + stock `vendor_boot` + Lineage `init_boot`

## Frozen Primary Rollback Branch

Known-good rollback branch:
- `system_a`:
  - [/home/john/android/lineage/out/target/product/myron/stock_based_system_cycle/system_stockbase_printrecommendation_extshared_captiveportal_pacprocessor_btmidi_camproxy_certinstaller_avb.img](/home/john/android/lineage/out/target/product/myron/stock_based_system_cycle/system_stockbase_printrecommendation_extshared_captiveportal_pacprocessor_btmidi_camproxy_certinstaller_avb.img)
  - sha256: `09fa2bb3712dbb32e11f0b2fc5ab4026c5bf257877929d543896eaed14380492`
- `vbmeta_system_a`:
  - [/home/john/android/lineage/out/target/product/myron/stock_based_system_cycle/vbmeta_system_stockbase_printrecommendation_extshared_captiveportal_pacprocessor_btmidi_camproxy_certinstaller.img](/home/john/android/lineage/out/target/product/myron/stock_based_system_cycle/vbmeta_system_stockbase_printrecommendation_extshared_captiveportal_pacprocessor_btmidi_camproxy_certinstaller.img)
  - sha256: `d7d522f2c08d7fdd1336f7389d5ef22e1077fb40e7cbfcf3fbb5cdbc2ded4928`

Rollback branch partition composition:
- `system_a` = stock-based rebuilt SAR image
- `system_ext_a` = stock
- `product_a` = stock
- `mi_ext_a` = stock
- `vbmeta_system_a` = matching custom image
- `vbmeta_a` = stock
- lower stack = stock

## Final App-Layer Classification

Safe:
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

App-layer migration is finished. Do not continue it unless strategy changes again.

## Bring-up History Summary

What was tried and what happened:

1. Lineage-heavy `system_a`
- failed very early

2. SAR-shape correction
- required
- did not fix boot alone

3. AVB correction
- required
- did not fix boot alone

4. Generic framework/classpath micro-bridges
- did not fix boot

5. Stock-based `system_a` runtime-core pivot
- booted
- established the project’s first stable custom-path baseline

6. App-layer micro-delta pass
- 7 deltas proved safe
- 3 deltas proved unsafe
- useful for dependency mapping, but no longer main path

7. Unsafe app dependency mapping
- `HTMLViewer` tied to MIUI/Settings/OTA/cloud package role and `system_ext` package hooks
- `DocumentsUI` tied to package identity / privapp / sysconfig contract mismatches
- `KeyChain` unsafe without a narrow `system_ext/product` contract explanation

8. Lineage-heavy `system_a` + `system_ext_a` test with stock first-stage
- still failed with `POCO -> black -> POCO`
- no useful `adb` evidence collected

9. Clean builder reset
- old remote tree is not trusted for fresh bring-up images
- clean tree now builds from `/home/john/android/lineage_clean`

## Strategic Conclusions

These are the conclusions to preserve:
- stock-based hybrid proved the device can boot under a preserved stock runtime core
- AVB and SAR mattered, but they were not the primary remaining blocker
- hybrid polish is not the fastest route to Lineage now
- the most likely early blocker is still stock first-stage behavior mixed with Lineage-heavy userspace
- the next serious test should keep `init_boot` stock by default and only change it if attempt 1 fails the same way
- do not strengthen the `sm8750`/`kalama` fallback proactively; if the narrowed test still fails early, pivot to a real `kaanapali` kernel/vendor_boot bring-up

## Main Branch Under Preparation

Target branch for the next serious bring-up test:
- product target = `lineage_myron_bringup`
- `system_a` = Lineage-heavy SAR
- `system_ext_a` = Lineage-heavy
- `init_boot_a` = stock for attempt 1, Lineage-built only for attempt 2
- `vendor_boot_a` = stock
- `vbmeta_system_a` = matching custom image

Remain stock for first matched-stack test:
- `product_a`
- `mi_ext_a`
- `vbmeta_a`
- `vendor_a`
- `odm_a`
- `boot_a`
- `vendor_boot_a`
- lower stack other than `init_boot_a` on attempt 2

## Builder State

Old node:
- `/home/john/android/lineage`
- forensic/reference only

Active clean node:
- `/home/john/android/lineage_clean`

Clean-node state:
- `m nothing`: passes
- `m checkvintf`: passes
- `m host_init_verifier`: passes
- image build running for:
  - `systemimage`
  - `systemextimage`
  - `vbmetasystemimage`

Bring-up reductions already implemented:
- no inherited `manifest_kalama.xml`
- no `mi_ext`
- no overlay mounts in bring-up `fstab`
- minimal bring-up manifest only
- stock `init_boot` by default
- reduced common feature surface for first `adb`:
  - NFC removed
  - sensors removed
  - thermal removed
  - GNSS permission surface removed
  - secure-element permission surface removed

Attempt 1 is not flash-ready until `system.img`, `system_ext.img`, and `vbmeta_system.img` exist and pass acceptance, and stock `init_boot`/`vendor_boot` paths are confirmed.

## Current Tooling To Use

For logging/capture:
- [prepare_myron_log_capture.sh](/Users/benny/Homelab/ROM/tools/prepare_myron_log_capture.sh)
- [first_boot_capture_and_diff.sh](/Users/benny/Homelab/ROM/tools/first_boot_capture_and_diff.sh)
- [capture_myron_postfailure_bundle.sh](/Users/benny/Homelab/ROM/tools/capture_myron_postfailure_bundle.sh)

For matched-stack readiness:
- [check_myron_clean_matched_stack_artifacts.sh](/Users/benny/Homelab/ROM/tools/check_myron_clean_matched_stack_artifacts.sh)
- [check_myron_clean_boot_critical_vendor_stack.sh](/Users/benny/Homelab/ROM/tools/check_myron_clean_boot_critical_vendor_stack.sh)
- [flash_myron_clean_matched_stack.sh](/Users/benny/Homelab/ROM/tools/flash_myron_clean_matched_stack.sh)
- [recover_myron_hybrid_rollback_slot_a.sh](/Users/benny/Homelab/ROM/tools/recover_myron_hybrid_rollback_slot_a.sh)
- [recover_myron_stock_slot_a.sh](/Users/benny/Homelab/ROM/tools/recover_myron_stock_slot_a.sh)

Core runbooks:
- [matched_lineage_first_stack_checklist.md](/Users/benny/Homelab/ROM/tools/runbooks/matched_lineage_first_stack_checklist.md)
- [myron_builder_reset_20260319.md](/Users/benny/Homelab/ROM/tools/runbooks/myron_builder_reset_20260319.md)
- [myron_bringup_history_20260319.md](/Users/benny/Homelab/ROM/tools/runbooks/myron_bringup_history_20260319.md)

## Known Current Gates

Matched-stack artifact gate requires:
- `system.img`
- `system_ext.img`
- `vbmeta_system.img`
Attempt 2 additionally requires:
- `init_boot.img`

Bring-up contract gate currently checks for:
- bring-up product exists
- bring-up `fstab` removes `mi_ext` and overlay remounts into Lineage partitions
- bring-up manifest trims nonessential HAL declarations from the first-`adb` target
- bring-up target does not inherit `manifest_kalama.xml`
- bring-up target keeps stock `init_boot` by default

Legacy later-phase source-vendor output list:
- [boot_critical_vendor_outputs.txt](/Users/benny/Homelab/ROM/tools/boot_critical_vendor_outputs.txt)

Recent clean-build blockers already fixed:
- missing `vendor_hal_soter_client` in Lineage QCOM sepolicy path
- duplicate local `vendor_hal_soter*` declarations
- broad inherited common manifest/package surface for bring-up

## Working Rules

1. Do not use old AI-produced Lineage images for future tests.
2. Do not reopen app-layer migration.
3. Do not spend cycles on hybrid polish.
4. Do not flash a matched-stack Lineage test until:
   - the attempt-specific required artifacts exist and are fresh
   - the bring-up contract gate passes
5. Keep the hybrid rollback branch ready at all times.

## Immediate Next Step

Wait for the clean build to finish, then rerun:

```bash
bash /Users/benny/Homelab/ROM/tools/check_myron_clean_matched_stack_artifacts.sh /Users/benny/Homelab/ROM myron
bash /Users/benny/Homelab/ROM/tools/check_myron_clean_boot_critical_vendor_stack.sh /Users/benny/Homelab/ROM myron
```

Only after that decide whether to:
- flash attempt 1 with stock `init_boot`
- or fix the next build/output blocker first
