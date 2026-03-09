# Myron AI Handoff

Last updated: 2026-03-09

## Read This First

This file is the shortest correct handoff for another AI agent.

Canonical status remains:
- `README.md`

Operational runbooks:
- `tools/runbooks/minimal_boot_chain_validation.md`
- `tools/runbooks/full_userspace_validation.md`
- `tools/runbooks/boot_only_validation.md`

## Goal

Continue bring-up toward a functional ROM for Poco F8 Ultra (`myron`) without regressing the currently proven install path.

## Environment

- Local coordination workspace: `/Users/benny/Homelab/ROM`
- Remote Android tree: `john@192.168.200.33:/home/john/android/lineage`
- Target: `lineage_myron-trunk_staging-userdebug`
- Stock firmware baseline on phone: `3.0.7.0.WPMEUXM` (EU)

## Current Proven Device State

The phone is currently safe on this path:

- stock `boot`
- stock `vendor_boot`
- custom `init_boot`

This path has already been proven on-device:

- `sys.boot_completed=1`
- stable `adb`
- no catastrophic crash loop
- `verifiedbootstate=orange`

Do not replace `boot` by default.
Do not replace `vendor_boot` by default.

## Key Conclusions Already Proven

1. `fastboot boot out/target/product/myron/boot.img` works and is useful for safe validation.
2. Persistent custom `boot.img` is not the right next install path on this device in the current phase.
3. The persistent regression was not “Android cannot boot”; it was “wrong partition strategy / trust path”.
4. The correct intermediate install model is:
   - stock `boot`
   - stock `vendor_boot`
   - custom `init_boot`
5. The next meaningful milestone is the first custom userspace boot on top of that proven path.
6. NFC is not the current gating installation blocker.

## Active Work In Progress

Current active work is the resumed full userspace image build after the vendor sepolicy blocker class was cleared.

1. Remote narrowed vendor sepolicy rebuild
   - status:
     - complete
   - result:
     - `mka vendor_sepolicy.cil.raw -j6` now passes cleanly
   - important resolved classes:
     - stale local references to nonexistent `vendor_sysfs_*` labels
     - missing Qualcomm fallback policy inclusion in `BOARD_VENDOR_SEPOLICY_DIRS`
     - missing raw imported Qualcomm vendor attribute/domain/property/service families
     - WFD/test-property fallback gaps

2. Remote full userspace image build
   - host: `john@192.168.200.33`
   - current command:
     - `mka systemimage productimage systemextimage vendorimage odmimage vendor_dlkmimage system_dlkmimage -j10`
   - current status:
     - running
     - already past the old vendor sepolicy choke point
     - no new blocker at last update

3. Local-to-remote stock userspace rollback staging
   - payload:
     - stock `super.img`
     - stock `vbmeta_system.img`
   - destination:
     - `/home/john/android/lineage/_transfer/rollback_wpm_eu/stock_userspace_20260308/`
   - status at handoff:
     - complete
     - rollback assets confirmed present on remote host

Current note:
- any session ids are transient; poll the remote host first instead of trusting a stale session number
- the next expected blocker class is no longer vendor sepolicy; it is likely packaging, module-resolution, or image-generation

## Safe Boundaries

Allowed:
- host-side build/debug work
- script/runbook edits
- `fastboot boot` validation
- persistent `init_boot`-only testing
- userspace image build and slot-safe userspace flash once readiness passes

Not allowed by default:
- persistent custom `boot` flashing
- persistent custom `vendor_boot` flashing
- broad boot-chain experimentation
- firmware partition flashing
- mixing stock releases

## Next Correct Steps

1. Poll the running remote build.
2. If `vendor_sepolicy.cil.raw` fails:
   - this would be unexpected regression; fix the first real build error only
3. Poll the running full userspace image build.
4. If the userspace image build succeeds:
   - run:
     - `CHECK_ROLLBACK=1 REQUIRE_DEVICE=0 bash tools/check_userspace_flash_readiness.sh ~/android/lineage myron`
     - `bash tools/check_partition_package_sanity.sh ~/android/lineage myron`
5. Only if readiness passes:
   - follow `tools/runbooks/full_userspace_validation.md`
   - or use:
     - `DRY_RUN=1 bash tools/run_first_userspace_attempt.sh ~/android/lineage myron`
   - flash logical userspace partitions only
   - keep:
     - stock `boot`
     - stock `vendor_boot`
     - custom `init_boot`
6. After the first custom userspace boot:
   - run `tools/first_boot_capture_and_diff.sh`
   - inspect must-have gate, service parity, crash loops, AVC deltas

## Important Files

Status:
- `README.md`

Flash/readiness:
- `tools/check_userspace_flash_readiness.sh`
- `tools/flash_userspace_images.sh`
- `tools/rollback_userspace_images.sh`
- `tools/run_first_userspace_attempt.sh`
- `tools/summarize_first_userspace_result.sh`
- `tools/evaluate_latest_firstboot.sh`
- `tools/run_userspace_rollback.sh`
- `tools/audit_userspace_outputs.sh`
- `tools/userspace_image_manifest.txt`

Capture/triage:
- `tools/first_boot_capture_and_diff.sh`
- `tools/check_must_have_services.sh`
- `tools/classify_avc_denials.sh`
- `tools/compare_avc_sets.sh`

Runbooks:
- `tools/runbooks/common_device_overlap_matrix.md`
- `tools/runbooks/full_userspace_validation.md`
- `tools/runbooks/first_userspace_triage_checklist.md`
- `tools/runbooks/minimal_boot_chain_validation.md`
- `tools/runbooks/fastboot_myron_command_sheet.md`
- `tools/runbooks/platform_naming_debt.md`
- `tools/runbooks/firmware_lock_wpm_eu.md`
- `tools/runbooks/rollback_pack_preparation.md`
- `tools/runbooks/manifest_runtime_expectations.md`
- `tools/runbooks/init_service_ownership_audit.md`
- `tools/runbooks/first_userspace_verdict_rules.md`
- `tools/runbooks/first_userspace_blocker_matrix.md`

Issue templates:
- `tools/templates/issue_no_adb.md`
- `tools/templates/issue_bootloop.md`
- `tools/templates/issue_decryption.md`
- `tools/templates/issue_radio_ims.md`
- `tools/templates/issue_audio.md`
- `tools/templates/issue_camera.md`
- `tools/templates/issue_power_thermal.md`
- `tools/templates/issue_nfc.md`

## Known Good Evidence

Important captures already collected:

- temporary boot success:
  - `/home/john/android/lineage/_checkpoints/firstboot_20260308_160952`
  - `/home/john/android/lineage/_checkpoints/parity_20260308_160953`
- dwell-based temporary boot reference:
  - `/home/john/android/lineage/_checkpoints/firstboot_20260308_164555`

Key result from the proven persistent path:
- `init_boot`-only flash on slot `_b` succeeded
- boot-critical AVC set improved slightly (`78 -> 77`)
- only residual must-have miss remained `android.hardware.nfc.INfc/default`

## What To Avoid Re-Learning

Do not re-run the old wrong path unless there is a new concrete reason:

- flashing custom `boot` alone
- flashing custom `boot + vbmeta`
- treating NFC as the next install blocker before first custom userspace boot
- confusing the Qualcomm fallback source layer with the actual device target:
  - device target remains `SM8850` / `kaanapali`
  - only the currently available Qualcomm vendor sepolicy fallback layer is under `sm8750`

Those paths were already explored and are not the current fastest route.

## Additional host-side progress

- remote `ccache` limit increased from `5G` to `50G`
- remote rollback dry-run for userspace restore is already verified
- imported Qualcomm fallback vendor sepolicy is now explicitly included from `device/xiaomi/sm8850-common/BoardConfigCommon.mk`
- local vendor policy was cleaned up to stop referencing stale nonexistent `vendor_sysfs_*` labels
- active exact common-vs-device blob overlap is now minimal after syncing the canonical remote `myron` blob list
- the current exact overlap regression baseline is:
  - `2` destination paths
  - enforced by:
    - `tools/check_blob_overlap.sh`
    - `tools/blob_overlap_allowlist.txt`
- exact high-risk overlap pruning then expanded that set:
  - `205` exact duplicate destination paths have now been commented out of `device/xiaomi/sm8850-common/proprietary-files.txt`
  - keep-policy is documented in:
    - `tools/runbooks/common_device_overlap_matrix.md`
- overlap growth is now gated:
  - `tools/check_blob_overlap.sh`
  - baseline allowlist:
    - `tools/blob_overlap_allowlist.txt`
  - current known exact common-vs-myron overlap baseline:
    - `2` destination paths
  - `tools/surgical_blob_policy_check.sh` now fails if new exact overlap destinations are introduced
- three high-confidence common-tree overlap entries were already pruned locally and synced remotely:
  - `vendor/etc/init/hw/init.qcom.rc`
  - `vendor/etc/vintf/manifest/c2_manifest_vendor.xml`
  - `vendor/etc/vintf/manifest/dumpstate-xiaomi.xml`
