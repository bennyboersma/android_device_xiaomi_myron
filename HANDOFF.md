# Myron AI Handoff

Last updated: 2026-03-09

## Read This First

This file is the shortest correct handoff for another AI agent.

Canonical status remains:
- `README.md`

Operational runbooks:
- `tools/runbooks/first_userspace_attempt_postmortem_20260309.md`
- `tools/runbooks/full_userspace_validation.md`
- `tools/runbooks/minimal_boot_chain_validation.md`
- `tools/runbooks/boot_only_validation.md`

## Goal

Continue bring-up toward a functional ROM for Poco F8 Ultra (`myron`) without regressing the now-recovered safe stock baseline.

## Environment

- Local coordination workspace: `/Users/benny/Homelab/ROM`
- Remote Android tree: `john@192.168.200.33:/home/john/android/lineage`
- Target: `lineage_myron-trunk_staging-userdebug`
- Stock firmware baseline on phone: `3.0.7.0.WPMEUXM` (EU)

## Current Safe Device State

The phone is currently safe on this path:

- stock `boot`
- stock `vendor_boot`
- stock `init_boot`
- stock userspace
- active slot `_a`

Verified after recovery:

- `sys.boot_completed=1`
- build `OS3.0.7.0.WPMEUXM`
- `ro.boot.slot_suffix=_a`
- `ro.boot.bootreason=reboot,fastboot`

Do not replace `boot` by default.
Do not replace `vendor_boot` by default.
Do not replace `init_boot` by default.
Do not retry userspace flashing until the postmortem blockers are addressed.

## Key Conclusions Already Proven

1. `fastboot boot out/target/product/myron/boot.img` works and is useful for safe validation.
2. Persistent custom `boot.img` is not the right next install path on this device in the current phase.
3. Generated `init_boot` is not currently safe; stock `init_boot` recovered the device.
4. Split userspace images build successfully and pass host-side readiness.
5. The first split userspace flash failed before `adb`, so the current blocker is inside flashed userspace runtime, not image transport.
6. NFC is not the current gating installation blocker.

## Most Recent Failed Attempt

First split userspace flash attempt on slot `b`:

- flash transport: PASS
- logical partitions flashed:
  - `system_b`
  - `system_ext_b`
  - `product_b`
  - `vendor_b`
  - `odm_b`
  - `vendor_dlkm_b`
  - `system_dlkm_b`
- runtime result:
  - bootloop before `adb`
- required recovery:
  - stock `super`
  - stock `vbmeta_system_b`
  - stock slot-`b` boot-chain + verification restore
  - stock slot-`a` boot-chain + verification restore
  - `fastboot set_active a`

Read first:
- `tools/runbooks/first_userspace_attempt_postmortem_20260309.md`

## Active Work In Progress

Current work is no longer “flash the first userspace build.” Current work is postmortem and retry preparation.

1. Freeze the recovered slot-`a` stock baseline.
2. Fix rollback-tool defects discovered during the failed first attempt.
3. Add earlier failure capture to the next userspace attempt path.
4. Compare the flashed reduced userspace set against stock for early boot-critical regressions.
5. Only then retry split-image userspace flashing.

## Safe Boundaries

Allowed:
- host-side build/debug work
- script/runbook edits
- `fastboot boot` validation
- stock-bounded recovery testing
- userspace image comparison against stock

Not allowed by default:
- retrying split userspace flash immediately
- persistent custom `boot` flashing
- persistent custom `vendor_boot` flashing
- generated `init_boot` testing in the retry path
- firmware partition flashing
- mixing stock releases

## Next Correct Steps

1. Verify and freeze the recovered baseline:
   - `adb shell getprop sys.boot_completed`
   - `adb shell getprop ro.build.version.incremental`
   - `adb shell getprop ro.boot.slot_suffix`
2. Sync and verify the rollback helper fixes:
   - slot-specific `vbmeta_system_${slot}`
   - wrapper invocation that works in practice
3. Implement earlier failure capture for the next userspace attempt:
   - slot metadata before flash
   - timeout branch when `adb` never appears
   - immediate fastboot/recovery state capture
4. Compare the flashed reduced userspace set against stock for boot-critical areas:
   - init rc ownership
   - VINTF fragments
   - keymint/gatekeeper/TEE
   - vold/fscrypt/decryption path
   - display startup path
5. Only after that, plan the second userspace attempt, ideally with explicit slot-state checkpoints and rollback validation.

## Important Files

Status:
- `README.md`
- `tools/runbooks/first_userspace_attempt_postmortem_20260309.md`

Flash/readiness:
- `tools/check_userspace_flash_readiness.sh`
- `tools/check_retry_boot_critical_vendor_stack.sh`
- `tools/flash_userspace_images.sh`
- `tools/rollback_userspace_images.sh`
- `tools/run_first_userspace_attempt.sh`
- `tools/run_userspace_rollback.sh`
- `tools/audit_userspace_outputs.sh`
- `tools/evaluate_latest_firstboot.sh`

Capture/triage:
- `tools/first_boot_capture_and_diff.sh`
- `tools/check_must_have_services.sh`
- `tools/classify_avc_denials.sh`
- `tools/compare_avc_sets.sh`
- `tools/runbooks/first_userspace_triage_checklist.md`
- `tools/runbooks/first_userspace_blocker_matrix.md`
- `tools/runbooks/first_userspace_verdict_rules.md`

## What To Avoid Re-Learning

Do not re-run these paths without a new concrete reason:

- custom `boot` persistent flashing
- custom `vendor_boot` persistent flashing
- generated `init_boot` in the userspace retry path
- immediate second split userspace flash without postmortem fixes
- treating NFC as the next installation blocker before the flashed userspace reaches `adb`

## Current high-confidence blocker list


Current highest-confidence retry blockers after stock-vs-built comparison:
- missing built vendor service ownership for gatekeeper, health, wifi, display (composer/allocator/color), qseecomd, and secureprocessor
- these services exist in source but are not present in the currently staged built userspace output
- keymint/weaver are present in the built output under `vendor/` and are no longer the leading blocker in this phase
- second userspace attempt is blocked until both:
  - `m nothing -j10` is clean on the retry-prep tree
  - `tools/check_retry_boot_critical_vendor_stack.sh` passes on rebuilt outputs
- last measured retry gate result on the staged output before current retry-prep changes: `missing_boot_critical_vendor_outputs=13`

1. Early userspace boot blocker before `adb`
2. rollback wrapper/path defects discovered under real failure
3. slot-state handling must be made explicit before retry
4. reduced first-boot userspace set may still be missing or mis-owning boot-critical vendor runtime pieces


Current state:
1. Phone remains on the recovered stock-safe baseline and is not being touched.
2. Host-side retry prep is still blocked on generated vendor prebuilt collisions in `vendor/xiaomi/myron/Android.bp`.
3. An automated `m nothing` cleanup loop is active on the remote host, removing exact stale prebuilt collisions and re-running until the blocker class changes or `m nothing` passes.
4. The remote full display tree is patched so `qtidisplay_neo` is enabled for `kaanapali`, which is the queued display-side fix once the Soong graph is clean.
