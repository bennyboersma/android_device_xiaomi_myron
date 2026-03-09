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

The phone is back on a verified stock-safe baseline after a full official Xiaomi restore.

Verified on the restored baseline:

- restore source:
  - `myron_eea_global_images_OS3.0.7.0.WPMEUXM_20260112.0000.00_16.0_eea_cee0eaf4a6.tgz`
- verified MD5:
  - `cee0eaf4a66294c29ae709a22073e670`
- restore method:
  - Xiaomi `flash_all_except_storage.sh`
- post-restore state:
  - `ro.boot.slot_suffix=_a`
  - `ro.build.version.incremental=OS3.0.7.0.WPMEUXM`
  - `sys.boot_completed=1`

No more partial recovery flashes are needed.
The next device-side writes must be deliberate userspace-test actions, not recovery reconstruction.
Do not retry userspace flashing until retry-prep gates and dry-run readiness are revalidated from this restored baseline.

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

Additional recovery finding after that postmortem:

- flashing stock-like partial sets to slot `b` was not enough to recover a trustworthy baseline
- slot `b` still failed before `adb` even with matched stock `super + boot + init_boot + vendor_boot + dtbo + vbmeta + vbmeta_system`
- later, slot `a` also stopped booting cleanly after repeated partial restore work
- root cause is now considered recovery-image incompleteness, not just Lineage userspace contents
- this recovery uncertainty is now closed because the full official package restore succeeded and stock boot was reconfirmed

## Active Work In Progress

Current work is no longer “flash the first userspace build.” Current work is postmortem and retry preparation.

1. Freeze the recovered slot-`a` stock baseline.
2. Fix rollback-tool defects discovered during the failed first attempt.
3. Add earlier failure capture to the next userspace attempt path.
4. Compare the flashed reduced userspace set against stock for early boot-critical regressions.
5. Make Gate 1 clean and Gate 2 pass before any retry flash.
6. Reconfirm Gate 1 and Gate 2 from the reproducible retry-prep state.
7. Reconfirm slot-safe flash/rollback dry-runs with `TARGET_SLOT=b`.
8. Only then retry split-image userspace flashing on slot `b`.

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
- firmware partition flashing from incomplete bundles
- mixing stock releases
- treating partial stock image sets as a recovery-safe baseline
- new slot-`b` stock experiments unless there is a specific scoped validation reason

## Next Correct Steps

1. Freeze the restored stock baseline operationally:
   - keep stock `boot`
   - keep stock `init_boot`
   - keep stock `vendor_boot`
   - keep stock userspace on slot `a`
2. Reconfirm the restored baseline when needed:
   - `adb shell getprop sys.boot_completed`
   - `adb shell getprop ro.build.version.incremental`
   - `adb shell getprop ro.boot.slot_suffix`
3. Sync and verify the rollback helper fixes:
   - slot-specific `vbmeta_system_${slot}`
   - wrapper invocation that works in practice
4. Implement earlier failure capture for the next userspace attempt:
   - slot metadata before flash
   - timeout branch when `adb` never appears
   - immediate fastboot/recovery state capture
5. Reconfirm retry-prep build gates:
   - `tools/run_retry_prep_gate1.sh`
   - `tools/run_retry_prep_gate2.sh`
6. Compare the flashed reduced userspace set against stock for boot-critical areas:
   - init rc ownership
   - VINTF fragments
   - keymint/gatekeeper/TEE
   - vold/fscrypt/decryption path
   - display startup path
7. Reconfirm userspace flash readiness dry-runs:
   - only slot-`b` logical partitions in dry-run
   - rollback targets `vbmeta_system_b`
   - attempt wrapper records planned commands and slot metadata
8. Only after that, plan the second userspace attempt, ideally with explicit slot-state checkpoints and rollback validation.

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
- retry-prep policy is now codified in:
  - `tools/retry_prep_keep_modules.txt`
  - `tools/retry_prep_drop_modules.txt`
  - `tools/retry_prep_drop_prefixes.txt`
  - `tools/run_retry_prep_gate1.sh`
  - `tools/run_retry_prep_gate2.sh`
- last measured retry gate result on the staged output before current retry-prep changes: `missing_boot_critical_vendor_outputs=13`

1. Early userspace boot blocker before `adb`
2. rollback wrapper/path defects discovered under real failure
3. slot-state handling must be made explicit before retry
4. reduced first-boot userspace set may still be missing or mis-owning boot-critical vendor runtime pieces


Current state:
1. Phone has been successfully restored from the complete official Xiaomi EEA fastboot package and is booting stock on slot `a`.
2. Host-side retry prep Gate 1 (`m nothing -j10`) passes successfully using an aggressive keep/drop list.
3. Gate 2 no longer fails for the original 13-path cluster; it is now narrowed to display plus `qseecomd`.
4. The display stack was silently excluded because the Qualcomm display config did not recognize Android 16 (`Baklava`) and defaulted to the stub/headless path.
5. The remote `kaanapali` display tree is now patched for:
   - Android 16 (`Baklava`) `composer_version := v3_3`
   - `neo` Soong export into the display HAL
   - commonsys display header namespace selection
   - kaanapali gralloc handle flags (`reserved_size`, `custom_content_md_reserved_size`, `ubwcp_format`)
6. `qseecomd` is restored as a source-owned prebuilt and can now be installed into `vendor/bin/qseecomd` on the remote output tree.
7. Current remaining retry-prep work is inside the Qualcomm display stack:
   - `drm_panel_feature_mgr.cpp` needed a `neo` compatibility shim for missing DRM blob types
   - display-side `libvmmem` had to be rebound from an empty CAF placeholder to the restored proprietary prebuilt
   - the local Gate 2 checker now accepts versioned composer VINTF filenames such as `vendor.qti.hardware.display.composer-service3_v3.xml`

## Latest Retry-Prep Status

As of the latest remote session on `john@192.168.200.33`:

- Gate 1: PASS
- Gate 2: improved substantially, but not fully green yet
- `qseecomd` path:
  - prebuilt ownership is fixed
  - direct final install to `vendor/bin/qseecomd` works when the build is invoked with an absolute `OUT_DIR`
- display path:
  - namespace and gralloc-shape blockers are fixed
  - current failures are later Qualcomm display link/build issues, not the original missing-module problem

## Recovery Baseline Correction

New high-confidence conclusion from the latest recovery work:

- the previously staged remote stock fragments were incomplete for a true baseline restore
- Xiaomi fastboot `flash_all*.sh` expects additional boot-critical payloads that were not present in the partial bundles we used
- confirmed missing from the staged remote recovery set were items such as:
  - `vm-bootsys.img`
  - `qtvm-dtbo.img`
  - `recovery.img`
  - multiple `xbl`, `uefi`, `tz`, `aop`, and related firmware images
- because of that, repeated partial restores were able to leave both slots non-booting even though fastboot remained healthy

Current recovery source of truth:

- official package filename:
  - `myron_eea_global_images_OS3.0.7.0.WPMEUXM_20260112.0000.00_16.0_eea_cee0eaf4a6.tgz`
- official MD5:
  - `cee0eaf4a66294c29ae709a22073e670`
- direct Xiaomi CDN URL:
  - `https://bigota.d.miui.com/OS3.0.7.0.WPMEUXM/myron_eea_global_images_OS3.0.7.0.WPMEUXM_20260112.0000.00_16.0_eea_cee0eaf4a6.tgz`

Recovery closure:

- the full official package has now been extracted and used successfully
- Xiaomi `flash_all_except_storage.sh` completed cleanly
- stock boot on slot `a` is reconfirmed
- the remaining active blockers are again build/runtime retry-prep issues, not baseline recovery uncertainty

Next remote step:
- finish the `libvmmem`-backed display link path
- rebuild `vendor.qti.hardware.display.composer-service`
- rebuild `vendor.qti.hardware.display.allocator-service`
- rerun `tools/run_retry_prep_gate2.sh`
