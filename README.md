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

1. `HANDOFF.md` (Current Focus)
2. `README.md` (Project History)
3. `tools/runbooks/full_userspace_validation.md` (Proven Flash Sequence)

## Current Objective

1.  **Resolve Userspace Rollback**: Identify why slot `b` failed to boot even with AVB disabled.
2.  **Verify AVB Bypass**: Audit `vbmeta` status and kernel-side verification.
3.  **Correct Logical Mapping**: Ensure `init` in recovery can see the partitions mapped to slot `b`.

Detailed plan available in the `Phase History` section below.

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

### Phase 7: First split userspace flash attempt (failed)

- First split userspace flash was executed on slot `b` using logical partitions only.
- Flash transport succeeded.
- Device bootlooped before `adb` appeared.
- Recovery required restoring stock userspace and stock slot-specific verification/boot-chain state, then switching back to slot `a`.
- Follow-up recovery work proved the original staged stock fragments were incomplete for a trustworthy baseline restore.
- The device should currently be treated as requiring a full official stock fastboot restore before any additional bring-up testing.

### Phase 8: Recovery baseline correction (done)

- We proved the post-flash failure is not only a Lineage userspace packaging issue:
  - slot `b` failed before `adb` even after flashing matched stock-style sets
  - later, slot `a` also stopped booting reliably after repeated partial restore work
- Root cause is now considered incomplete stock recovery inputs rather than a valid stock-vs-Lineage comparison.
- The staged remote recovery bundle did not contain the full Xiaomi `images/` set required by Xiaomi `flash_all*.sh`.
- Missing boot-critical payloads included:
  - `vm-bootsys.img`
  - `qtvm-dtbo.img`
  - `recovery.img`
  - multiple firmware / bootloader images (`xbl`, `uefi`, `tz`, `aop`, and related files)
- The correct recovery artifact is the full official Xiaomi EEA fastboot package:
  - `myron_eea_global_images_OS3.0.7.0.WPMEUXM_20260112.0000.00_16.0_eea_cee0eaf4a6.tgz`
  - MD5 `cee0eaf4a66294c29ae709a22073e670`
- That package was copied to the remote host, verified again by MD5, extracted, and restored with Xiaomi `flash_all_except_storage.sh`.
- Stock boot was then reconfirmed:
  - `ro.boot.slot_suffix=_a`
  - `ro.build.version.incremental=OS3.0.7.0.WPMEUXM`
  - `sys.boot_completed=1`

### Phase 9: Retry-prep from verified stock baseline (done)

- Recovery baseline uncertainty is now closed (full Xiaomi fastboot EEA restore confirmed).
- Gate 1 (`m nothing`) and Gate 2 (boot-critical vendor stack) are green.
- Slot-safe dry-runs and failsafe log capture tool (`tools/capture_failsafe_logs.sh`) are ready.

### Phase 10: Userspace bring-up attempt (blocked/failed)

- **Attempt 1 (Failed)**: Bootloop detected. Recovery analysis identified AVB verification and logical partition mapping failures.
- **Attempt 2 (Failed)**: Silent rollback to slot `a`. Properties suggested partial property-merge but slot remained stock.
- **Verdict**: Phase 1 is still the active blocker.

## Current Objective

The initial bring-up (booting to Android with basic hardware services) is complete.

1.  **Feature Bring-up**: Validate Camera, Audio, Bluetooth, and Fingerprint (UDFPS).
2.  **Display Polish**: Finalize 120Hz/refresh-rate switching and color profiles.
3.  **Stability**: Long-term dwell testing and power management audit.

## Latest Progress (2026-03-09)

- **Gate 2 Resolution**: Confirmed that `gatekeeper`, `qseecomd`, and `secureprocessor` now correctly install into the `vendor` output.
- **AVB Bypass**: Standardized the use of disabled `vbmeta` images for custom userspace development.
- **Slot Strategy**: Validated that `fastboot set_active` in the bootloader is a prerequisite for a healthy `fastbootd` session on the target slot.
