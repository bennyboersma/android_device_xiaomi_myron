# Myron Minimal Boot-Chain Validation

## Goal
Prove that persistent flashing of the smallest possible boot chain behaves like the successful temporary-boot baseline.

## Outcome
This stage produced the key install-path insight:

- custom persistent `boot.img` is not the preferred path for this device in the current phase
- stock `boot` plus mutable `init_boot` is the correct intermediate strategy
- `vendor_boot` remains stock during the first userspace phase unless a later blocker proves otherwise

## Current status (2026-03-08)
- One combined flash of `boot/init_boot/vendor_boot` on slot `_b` was attempted.
- Result: device left Android during dwell and returned to `fastboot`.
- Rollback with stock `3.0.7.0.WPMEUXM` `boot_b/init_boot_b/vendor_boot_b` succeeded.
- Follow-up isolation showed `boot_b` alone is sufficient to trigger the regression.
- Metadata comparison showed the current built `boot.img` is being re-signed with the Lineage test key during the prebuilt copy path.
- Comparison against the published Magisk package for `OS3.0.7.0.WPMEUXM` showed the practical install model is `stock boot` plus mutable `init_boot`, not a custom top-level `boot.img`.
- Remote prebuilt images were corrected to the exact EU stock baseline.
- `boot.img` now rebuilds byte-identical to stock EU.
- `init_boot`-only flash on slot `_b` succeeded:
  - `sys.boot_completed=1`
  - `adb` stable through dwell
  - no crash loop
  - only remaining must-have miss: `android.hardware.nfc.INfc/default`

## Preconditions
- `tools/preflight_myron.sh` passes 8/8.
- Temporary boot baseline remains valid:
  - `sys.boot_completed=1`
  - stable `adb`
  - `must_have_missing_count=0`
- Firmware on phone remains `3.0.7.0.WPMEUXM`.

## Flash scope
Flash only the current slot for the partition set being tested.

Current preferred and already-proven test:
- `init_boot` only

Keep `boot` stock-exact unless you are explicitly testing a new AVB hypothesis.

Do not flash `system`, `vendor`, `odm`, `super`, or firmware partitions in this stage.

## 1) Confirm slot and dry-run the flash plan
```bash
fastboot getvar product
fastboot getvar current-slot
FLASH_BOOT=0 FLASH_INIT_BOOT=1 FLASH_VENDOR_BOOT=0 DRY_RUN=1 bash tools/minimal_boot_chain_flash.sh ~/android/lineage myron
```

## 2) Flash only the selected partition set
```bash
FLASH_BOOT=0 FLASH_INIT_BOOT=1 FLASH_VENDOR_BOOT=0 DRY_RUN=0 bash tools/minimal_boot_chain_flash.sh ~/android/lineage myron
fastboot reboot
```

## 3) First persistent-boot capture
```bash
adb wait-for-device
DWELL_SECONDS=900 bash tools/first_boot_capture_and_diff.sh ~/android/lineage ~/android/lineage/_checkpoints/phone_baseline_20260304_121337
```

## 4) Persistent boot-chain equivalence gate
Accept only if all are true:
- `sys.boot_completed=1`
- stable `adb` through the dwell window
- `must_have_missing_count=0`
- no repeating crash loop in `init`, `vendor_init`, `vold`, `tee`, `qseecomd`, `system_server`, `surfaceflinger`, or `audioserver`
- no major service parity regression versus the successful temporary-boot milestone
- no new boot-critical AVC class

Current result for the first `init_boot`-only test:
- PASS for persistent boot-chain equivalence on `stock boot + custom init_boot`
- known residual miss unchanged: `android.hardware.nfc.INfc/default`

Do not escalate this runbook back to `boot + init_boot + vendor_boot` by default.
The next active runbook after this stage is `tools/runbooks/full_userspace_validation.md`.

Compare the boot-critical AVC set against the temporary-boot baseline:
```bash
bash tools/compare_avc_sets.sh \
  ~/android/lineage/_checkpoints/firstboot_20260308_162630 \
  <new_capture_dir>
```

## 5) Reboot-cycle confirmation
```bash
adb reboot
adb wait-for-device
DWELL_SECONDS=300 bash tools/first_boot_capture_and_diff.sh ~/android/lineage ~/android/lineage/_checkpoints/phone_baseline_20260304_121337
```

Require one clean reboot cycle before declaring the minimal flash path stable.

## Rollback trigger
Rollback immediately if the device drops back to `fastboot`, loses `adb` during dwell, or fails to hold `sys.boot_completed=1`.

```bash
cd ~/android/lineage/_transfer/rollback_wpm_eu
./restore_commands.sh b
```
