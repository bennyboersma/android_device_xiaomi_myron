# Poco F8 Ultra (myron) Bring-up Status

Last updated: 2026-03-09

LineageOS bring-up workspace for Poco F8 Ultra (`myron`) on Qualcomm SM8850.

This repository intentionally contains:
- device tree sources and common-tree integration
- vendor makefiles and extraction workflow glue
- bring-up tooling, flash helpers, capture scripts, and runbooks
- status and handoff documentation

This repository intentionally does not contain:
- stock firmware archives
- extracted stock image payloads
- local build outputs or checkpoints
- proprietary blob payload directories

## Getting Started

If you are continuing work from scratch, read in this order:

1. `HANDOFF.md`
2. `README.md`
3. `tools/runbooks/first_userspace_attempt_postmortem_20260309.md`
4. `tools/runbooks/full_userspace_validation.md`

Current proven safe device path:

1. stock `boot`
2. stock `vendor_boot`
3. stock `init_boot`
4. stock userspace on slot `a`

Current next milestone:

1. freeze the recovered slot-`a` stock baseline
2. analyze why the first split userspace flash bootlooped before `adb`
3. fix the userspace blocker set before any reflash
4. only then retry split-image userspace flash

## Repository Layout

- `device/xiaomi/myron`
  - device-specific tree
- `device/xiaomi/sm8850-common`
  - common tree shared by the current bring-up
- `vendor/xiaomi/*`
  - generated vendor makefiles and symlink packaging glue
- `tools/`
  - bring-up tooling, flash helpers, validation scripts, runbooks, issue templates
- `HANDOFF.md`
  - shortest current-state summary for another AI or engineer
- `README.md`
  - canonical status and phase history

## Single Source Of Truth

This file is the canonical project status and phase history.

Fastest AI handoff:
- `HANDOFF.md`

## Environment

- Build host: `john@192.168.200.33`
- Tree: `~/android/lineage`
- Target: `lineage_myron-trunk_staging-userdebug`
- Local coordination workspace: `/Users/benny/Homelab/ROM`
- Phone stock firmware baseline confirmed: `3.0.7.0.WPMEUXM` (EU)

## Phase History

### Phase 1: Tree and blob workflow stabilization (done)

- Migrated to extract-utils generated flow (`setup-makefiles.sh`).
- Made blob packaging symlink-aware.
- Pruned stale local overrides superseded by stock vendor/odm.
- Standardized blob edits to `proprietary-files.txt` + regeneration.

### Phase 2: Duplicate install conflict cleanup (done, iterative)

- Cleared broad classes of `PRODUCT_COPY_FILES` collisions against source/generated artifacts.
- Removed many collision-prone blob classes (`vendor/etc/aconfig`, large `vendor/etc/selinux`, duplicated service rc/xml ownership, legacy apex/hidl overlaps).
- Reduced repeated Kati duplicate rule blockers across multiple rounds.

### Phase 3: Platform mapping correction to SM8850 (done)

- Updated active device/common references from SM8550 naming to SM8850 where applicable.
- Updated:
  - `device/xiaomi/sm8850-common/common.mk`
  - `device/xiaomi/sm8850-common/udfps/UdfpsHandler.cpp`
  - `device/xiaomi/sm8850-common/lineage.dependencies`
  - init file rename `init.sm8550.rc -> init.sm8850.rc`

### Phase 4: Build gate progression (done)

- Passed: `m nothing -j1`
- Passed: `m checkvintf -j1`
- Passed: `m host_init_verifier -j1`
- Fixed blocker: missing `dtb.img` requirement for current GKI path by disabling `BOARD_INCLUDE_DTB_IN_BOOTIMG` in `device/xiaomi/sm8850-common/BoardConfigCommon.mk`
- Boot-critical host gates are green via `tools/preflight_myron.sh` (8/8 pass)

### Phase 5: Boot-only validation (done)

- Bootloader unlocked and remote-host fastboot path validated on `john@192.168.200.33`
- Temporary boot of `out/target/product/myron/boot.img` succeeded on device
- Device reached full Android userspace:
  - `sys.boot_completed=1`
  - stable `adb`
  - `uname -a` reported Android 16 `6.12.23-android16-5-...`
- Runtime capture completed:
  - `_checkpoints/firstboot_20260308_160952`
  - `_checkpoints/parity_20260308_160953`
- Must-have runtime gate passed:
  - `must_have_missing_count=0`
  - parity status `PASS`

### Phase 6: First split userspace image build (done)

- Split userspace images were built successfully on the remote host:
  - `system.img`
  - `system_ext.img`
  - `product.img`
  - `vendor.img`
  - `odm.img`
  - `vendor_dlkm.img`
  - `system_dlkm.img`
- Host checks passed:
  - `tools/check_userspace_flash_readiness.sh`
  - `tools/check_retry_boot_critical_vendor_stack.sh`
  - `tools/check_partition_package_sanity.sh`
  - `tools/audit_userspace_outputs.sh`

### Phase 7: First split userspace flash attempt (failed, recovered)

- First split userspace flash was executed on slot `b` using logical partitions only.
- Flash transport succeeded.
- Device bootlooped before `adb` appeared.
- Recovery required restoring stock userspace and stock slot-specific verification/boot-chain state, then switching back to slot `a`.
- Final recovered state:
  - Android boots
  - `sys.boot_completed=1`
  - build `OS3.0.7.0.WPMEUXM`
  - active slot `_a`

## Current Objective

Do not reflash userspace yet.

The project has moved from “get the first userspace images built” to “understand why the first split userspace flash bootlooped before `adb` and eliminate that blocker class before retrying.”

Current safe baseline:

1. stock `boot`
2. stock `vendor_boot`
3. stock `init_boot`
4. stock userspace
5. active slot `_a`

Current work focus:

1. freeze and document the recovered slot-`a` stock baseline
2. fix rollback tooling defects discovered during recovery
3. compare the flashed userspace set against stock for early boot-critical regressions
4. only then retry split-image userspace flashing

## Latest Progress (2026-03-09)

- Vendor fallback sepolicy gate is clean on the remote host:
  - `mka vendor_sepolicy.cil.raw -j6` PASS
  - `mka precompiled_sepolicy -j6` PASS
- The current retry-prep tree does not have a clean `m nothing -j10` yet.
- The active blocker is now narrower and mechanical:
  - generated vendor prebuilts in `vendor/xiaomi/myron/Android.bp` still shadow real `system` / `system_ext` modules
  - an automated cleanup loop on the remote host is pruning exact `partition is different` offenders and rerunning `m nothing`
- Split userspace images are built and host-side ready.
- Generated `init_boot` is explicitly not part of the safe first-userspace path:
  - `device/xiaomi/myron/prebuilt/init_boot.img` is byte-identical to stock
  - generated `out/target/product/myron/init_boot.img` is not
  - generated `init_boot` previously caused a persistent boot regression
- The first split userspace flash attempt established a new hard blocker:
  - flash transport: PASS
  - runtime boot to `adb`: FAIL
  - immediate classification: userspace boot blocker before `adb`
- Recovery findings:
  - `super` restore alone was not sufficient
  - `vbmeta_system` rollback had to be corrected from `vbmeta_system_ab` to slot-specific `vbmeta_system_a` / `vbmeta_system_b`
  - full slot-specific stock verification and boot-chain restore was required
  - final recovery succeeded only after slot `a` was made fully consistent and reactivated
- The current retry blockers are documented in:
  - `tools/runbooks/first_userspace_attempt_postmortem_20260309.md`
- Active exact common-vs-myron overlap baseline remains minimal:
  - `2` destination paths
  - enforced by:
    - `tools/check_blob_overlap.sh`
    - `tools/blob_overlap_allowlist.txt`
- Exact `PRODUCT_COPY_FILES` vs active blob destination collisions remain:
  - `0`
- Raw ELF blob packaging cleanup for `myron` is complete enough to pass Android 16 non-ELF enforcement:
  - `vendor/xiaomi/myron/myron-vendor.mk` now has `0` remaining raw ELF `PRODUCT_COPY_FILES`
- The active stale-prebuilt tail is now concentrated in Qualcomm display / perf / servicetracker / bluetooth-audio interface modules plus a remaining long tail of system library shadow copies.

## Immediate blocker list before any second userspace attempt


Current highest-confidence retry blockers after stock-vs-built comparison:
- missing built vendor service ownership for gatekeeper, health, wifi, display (composer/allocator/color), qseecomd, and secureprocessor
- these services exist in source but are not present in the currently staged built userspace output
- keymint/weaver are present in the built output under `vendor/` and are no longer the leading blocker in this phase
- second userspace attempt is blocked until both:
  - `m nothing -j10` is clean on the retry-prep tree
  - `tools/check_retry_boot_critical_vendor_stack.sh` passes on rebuilt outputs
- last measured retry gate result on the staged output before current retry-prep changes: `missing_boot_critical_vendor_outputs=13`

1. The flashed userspace set bootloops before `adb`, so early failure evidence is still missing.
2. The userspace rollback path needs to be slot-correct and wrapper-safe in practice.
3. Current retry flow must preserve stock `boot`, stock `vendor_boot`, and stock `init_boot`.
4. The next attempt needs earlier slot-state and failure-state capture so recovery is not guesswork.
5. The reduced first-boot userspace set may still be missing or mis-owning boot-critical vendor runtime pieces.

Use this postmortem as the starting point before any retry:
- `tools/runbooks/first_userspace_attempt_postmortem_20260309.md`


Current state:
1. Phone remains on the recovered stock-safe baseline and is not being touched.
2. Host-side retry prep is still blocked on generated vendor prebuilt collisions in `vendor/xiaomi/myron/Android.bp`.
3. An automated `m nothing` cleanup loop is active on the remote host, removing exact stale prebuilt collisions and re-running until the blocker class changes or `m nothing` passes.
4. The remote full display tree is patched so `qtidisplay_neo` is enabled for `kaanapali`, which is the queued display-side fix once the Soong graph is clean.
