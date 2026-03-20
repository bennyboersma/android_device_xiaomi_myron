# Myron AI Handoff

Last updated: 2026-03-20

## Current Status

The device is not on a trusted booting state right now.

The last trustworthy conclusions are:
- the kept booting branch is still the stock-based hybrid branch below
- the fastest safe recovery path is the full hybrid rollback script, not a partial `system`/`vbmeta_system` flash
- Lineage convergence stalled on the `systemserverclasspath` transition inside `system`

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

Important:
- restoring only `system_a` and `vbmeta_system_a` is not sufficient from arbitrary mixed test states
- use [recover_myron_hybrid_rollback_slot_a.sh](/Users/benny/Homelab/ROM/tools/recover_myron_hybrid_rollback_slot_a.sh) for the known-good recovery path

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

10. Stock-shaped carrier pivot
- patched stock `vendor_boot` plus stock `init_boot` got past `fastbootd`
- this proved the primary blocker was no longer the first-stage carrier

11. System-only Lineage userspace tests
- patched stock `vendor_boot` + stock `init_boot` + custom `system` still bootlooped
- stock `system_ext` was not enough to make a full Lineage `system` bootable

12. Family 2 protobuf isolation
- `bootclasspath.pb` and `systemserverclasspath.pb` together broke the kept booting branch

13. Family 2b isolation
- changing only `systemserverclasspath.pb` was enough to break the kept booting branch
- `systemserverclasspath.pb` is a confirmed blocker surface

14. Family 2d widening
- adding `org.lineageos.platform.jar` plus the matching Lineage `systemserverclasspath.pb` still bootlooped
- the blocker is not explained by the missing jar alone

## Strategic Conclusions

These are the conclusions to preserve:
- the stock-based hybrid branch is the only confirmed booting custom path
- a stock-shaped first-stage carrier can pass `fastbootd`, so the critical blocker moved into `system`
- `system_ext` is not the first blocker
- `systemserverclasspath.pb` is a confirmed blocker surface
- `org.lineageos.platform.jar` missing from the Family 0 filesystem was a real invalidity in the first Lineage-side classpath step
- adding that jar alone was not sufficient; the broader Lineage `systemserverclasspath` contract remains incompatible with the booting Family 0 `system`
- do not continue widening beyond this classpath surface until the device is restored and the next plan is explicit

## Confirmed Blocker Surface

Confirmed blocker surface:
- `system/etc/classpaths/systemserverclasspath.pb`

What is proven:
- Family 0 `systemserverclasspath.pb` is bootable
- replacing it with the Lineage-side variant breaks the booting Family 0 branch
- adding `/system/framework/org.lineageos.platform.jar` alongside that Lineage-side `systemserverclasspath.pb` still breaks boot

What is not yet proven:
- whether the remaining blocker is ordering, removal of the two stock `system_ext` jars, or a broader system-server contract mismatch

## Builder State

Old node:
- `/home/john/android/lineage`
- forensic/reference only

Active clean node:
- `/home/john/android/lineage_clean`

Clean-node state:
- clean node successfully produced the later Family 2 / 2B / 2D artifacts
- those artifacts are forensic/reference only now; they are not trusted as a booting branch

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

Recover the device with the full hybrid rollback:

```bash
cd /home/john/android/lineage_clean
DRY_RUN=0 bash tools/recover_myron_hybrid_rollback_slot_a.sh /home/john/android/lineage_clean myron
```

After recovery, stop. The next attempt should be planned from the confirmed `systemserverclasspath` dead end, not from the older matched-stack plan.
