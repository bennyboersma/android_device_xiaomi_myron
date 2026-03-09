# Myron Full Userspace Validation

## Goal
Move from the proven fully stock boot-chain path to the first custom userspace test with the smallest reasonable flash scope.

## Current status
- **SUCCESS (2026-03-09)**: Userspace bring-up is confirmed.
- The system boots LineageOS on slot `b` using the stock boot chain + disabled `vbmeta`.
- Gate 1 and Gate 2 are passing.

## Preconditions
- Phone firmware stays on `3.0.7.0.WPMEUXM`.
- `bash tools/preflight_myron.sh` passes.
- Full image artifacts exist under `out/target/product/myron/`.
- **Disabled VBMeta Images**: Manual `vbmeta_disabled.img` and `vbmeta_system_disabled.img` must be present.

## Artifact set
Preferred userspace test flashes only the logical partitions for the current slot:
- `system`
- `system_ext`
- `product`
- `vendor`
- `odm`
- `vendor_dlkm`
- `system_dlkm`

**Security Fix**: You MUST flash disabled `vbmeta` to bypass AVB:
- `vbmeta_b` (using `vbmeta_disabled.img`)
- `vbmeta_system_b` (using `vbmeta_system_disabled.img`)

## 1) Prepare Security & Slot Context (Bootloader)
**CRITICAL**: You must switch the active slot *before* entering `fastbootd` to ensure correct logical partition mapping.

```bash
# 1. Flash security bypass
fastboot flash vbmeta_b vbmeta_disabled.img
fastboot flash vbmeta_system_b vbmeta_system_disabled.img

# 2. Set context
fastboot set_active b

# 3. Enter userspace fastboot
fastboot reboot fastboot
```

## 2) Flash Logical Partitions (Fastbootd)
Once in `fastbootd` on the target slot:

```bash
DRY_RUN=0 TARGET_SLOT=b SET_ACTIVE=1 bash tools/flash_userspace_images.sh . myron
fastboot reboot
```

## 3) First boot capture after userspace flash
```bash
adb wait-for-device
DWELL_SECONDS=900 bash tools/first_boot_capture_and_diff.sh \
  ~/android/lineage \
  ~/android/lineage/_checkpoints/phone_baseline_20260304_121337
```

## 4) Acceptance gate
- `sys.boot_completed=1`
- `gatekeeper` and `qseecomd` are running in `ps`.
- `ro.build.display.id` matches the custom build (`BP2A...`).

## 5) Rollback path
If the device fails to boot to ADB, rollback to the stock slot `a`:
```bash
fastboot set_active a
fastboot reboot
```
