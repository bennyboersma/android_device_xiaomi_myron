# Myron Full Userspace Validation

## Goal
Move from the proven fully stock boot-chain path to the first custom userspace test with the smallest reasonable flash scope.

Fastest staged entrypoint:

```bash
DRY_RUN=1 bash tools/run_first_userspace_attempt.sh ~/android/lineage myron
```

## Current status
- This runbook is temporarily blocked pending userspace bootloop root-cause fixes.
- The current safe baseline before any retry is:
  - stock `boot`
  - stock `vendor_boot`
  - stock `init_boot`
- Keep slot `a` untouched as the recovered stock-safe baseline.
- The second retry is slot `b` only and optimized for boot-to-stable-`adb`.
- Do not use this runbook until Gate 1 passes:
  - `bash tools/run_retry_prep_gate1.sh ~/android/lineage myron`
- Do not use this runbook until Gate 2 passes:
  - `bash tools/run_retry_prep_gate2.sh ~/android/lineage myron`
- `vendor_sepolicy.cil.raw` already passes on the remote host.
- The active host-side work is retry-prep graph cleanup plus boot-critical vendor-output verification.

## Preconditions
- Phone firmware stays on `3.0.7.0.WPMEUXM`.
- Phone currently boots on the stable path:
  - stock `boot`
  - stock `vendor_boot`
  - stock `init_boot`
- `bash tools/preflight_myron.sh` passes.
- Full image artifacts exist under `out/target/product/myron/`.
- Stock rollback userspace assets are staged:
  - `super.img`
  - `vbmeta_system.img`
- Current slot is recorded before every flash.

## Artifact set
Preferred first userspace test flashes only the logical partitions for the current slot:
- `system`
- `system_ext`
- `product`
- `vendor`
- `odm`
- `vendor_dlkm`
- `system_dlkm`

Do not change `boot` in this stage.
Do not change `vendor_boot` in this stage.
Do not change `init_boot` in this stage.
Do not change firmware partitions.
Do not change `vbmeta` unless the first userspace boot shows an explicit vbmeta-system verification blocker.

## 1) Confirm readiness, then dry-run the plan
First verify Gate 1 and Gate 2 are both clean:

```bash
bash tools/run_retry_prep_gate1.sh ~/android/lineage myron
bash tools/run_retry_prep_gate2.sh ~/android/lineage myron
```

Then verify the full userspace artifacts and rollback assets are present:

```bash
CHECK_ROLLBACK=1 REQUIRE_DEVICE=0 \
  bash tools/check_userspace_flash_readiness.sh ~/android/lineage myron
bash tools/check_retry_boot_critical_vendor_stack.sh ~/android/lineage myron
bash tools/check_partition_package_sanity.sh ~/android/lineage myron
bash tools/audit_userspace_outputs.sh ~/android/lineage myron
```

Then confirm the device target, verify slot `b` is the retry target, and dry-run the flash plan:

```bash
fastboot getvar product
fastboot getvar current-slot
fastboot set_active b
DRY_RUN=1 REBOOT_TO_FASTBOOTD=1 USE_SUPER=0 FLASH_VBMETA_SYSTEM=0 \
  bash tools/flash_userspace_images.sh ~/android/lineage myron
```

Why this is the right next step:
- temporary boot already proved early boot viability
- the current generated `init_boot` regressed and stock `init_boot` restore recovered the device
- the next unknown is custom userspace behavior on the recovered stock boot chain, not top-level boot trust

Equivalent one-command wrapper:

```bash
DRY_RUN=1 bash tools/run_first_userspace_attempt.sh ~/android/lineage myron
```

## 2) Enter fastbootd and flash the logical partitions for slot `b`
The helper now enters `fastbootd` from either Android (`adb reboot fastboot`) or bootloader (`fastboot reboot fastboot`) before flashing logical partitions.

```bash
fastboot set_active b
DRY_RUN=0 REBOOT_TO_FASTBOOTD=1 USE_SUPER=0 FLASH_VBMETA_SYSTEM=0 \
  bash tools/flash_userspace_images.sh ~/android/lineage myron
fastboot reboot
```

If you later decide to test a built `super.img` instead, use:
```bash
DRY_RUN=1 USE_SUPER=1 FLASH_VBMETA_SYSTEM=0 \
  bash tools/flash_userspace_images.sh ~/android/lineage myron
```

## 3) First boot capture after userspace flash
```bash
adb wait-for-device
DWELL_SECONDS=900 bash tools/first_boot_capture_and_diff.sh \
  ~/android/lineage \
  ~/android/lineage/_checkpoints/phone_baseline_20260304_121337
```

Use these immediately after capture:
- blocker matrix: `tools/runbooks/first_userspace_blocker_matrix.md`
- runtime expectations: `tools/runbooks/manifest_runtime_expectations.md`
- init ownership audit: `tools/runbooks/init_service_ownership_audit.md`
- verdict rules: `tools/runbooks/first_userspace_verdict_rules.md`
- issue templates:
  - `tools/templates/issue_no_adb.md`
  - `tools/templates/issue_bootloop.md`
  - `tools/templates/issue_decryption.md`
  - `tools/templates/issue_radio_ims.md`
  - `tools/templates/issue_audio.md`
  - `tools/templates/issue_camera.md`
  - `tools/templates/issue_power_thermal.md`
  - `tools/templates/issue_nfc.md`

## 4) Acceptance gate
Accept the first custom userspace test only if all are true:
- `sys.boot_completed=1`
- `sys.boot_completed` remains `1` after dwell
- stable `adb`
- no catastrophic crash loop in `init`, `system_server`, `vendor_init`, `vold`, `surfaceflinger`, `audioserver`, `tee`, or `qseecomd`
- no major service-surface regression versus the stable fully stock boot-chain baseline
- no unexpected slot switch

## 5) Immediate rollback trigger
Rollback immediately if any of these happen:
- device returns to `fastboot`
- device lands in recovery instead of Android
- `adb` never comes up
- decryption breaks
- repeated catastrophic crash loop appears

Rollback path:
```bash
DRY_RUN=1 bash tools/rollback_userspace_images.sh myron
```

If the stock userspace assets are not staged on the current host, set them explicitly:
```bash
STOCK_SUPER_IMG=/path/to/stock/super.img \
STOCK_VBMETA_SYSTEM_IMG=/path/to/stock/vbmeta_system.img \
DRY_RUN=1 bash tools/rollback_userspace_images.sh myron
```

Actual rollback:
```bash
STOCK_SUPER_IMG=/path/to/stock/super.img \
STOCK_VBMETA_SYSTEM_IMG=/path/to/stock/vbmeta_system.img \
DRY_RUN=0 bash tools/rollback_userspace_images.sh myron
```

## Current blocker note


Current highest-confidence retry blockers after stock-vs-built comparison:
- missing built vendor service ownership for gatekeeper, health, wifi, display (composer/allocator/color), qseecomd, and secureprocessor
- these services exist in source but are not present in the currently staged built userspace output
- keymint/weaver are present in the built output under `vendor/` and are no longer the leading blocker in this phase
- the hard pre-retry gate for this class is `tools/check_retry_boot_critical_vendor_stack.sh`

- The first split-image userspace flash on slot `b` completed successfully but the device bootlooped before `adb` ever appeared.
- Recovery required restoring stock userspace plus slot-specific stock boot-chain and verification images and finally switching back to slot `a`.
- Do not re-run this userspace flash path until the blocker list in `tools/runbooks/first_userspace_attempt_postmortem_20260309.md` is addressed.
