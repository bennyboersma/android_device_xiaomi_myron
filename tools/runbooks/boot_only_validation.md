# Myron Boot-Only Validation (No Flash)

## Goal
Validate first boot behavior with the shortest feedback loop, without flashing full ROM partitions.

## Status
This phase is complete and retained as a reference runbook.

Current conclusion:
- `fastboot boot out/target/product/myron/boot.img` is a proven safe validation tool.
- It proved early boot viability on hardware.
- It is no longer the primary next step.
- Current forward path is first custom userspace validation on top of:
  - stock `boot`
  - stock `vendor_boot`
  - custom `init_boot`

## Preconditions
- Source tree is synced and lunch target is valid.
- Phone is detected in fastboot mode.
- Firmware baseline on device is coherent (same stock release, e.g. `3.0.7.0.WPMEUXM`).

## 1) Build only boot-critical artifacts
From tree root:

```bash
source build/envsetup.sh
lunch lineage_myron-trunk_staging-userdebug
mka bootimage initbootimage vendorbootimage super_empty -j"$(nproc)"
```

Expected artifacts:
- `out/target/product/myron/boot.img`
- `out/target/product/myron/init_boot.img`
- `out/target/product/myron/vendor_boot.img`

## 2) Verify fastboot connectivity

```bash
fastboot devices
```

You should see your device serial.

## 3) Boot test (no permanent flash)
Use your established temporary boot flow for this device generation.

Minimal command:

```bash
fastboot boot out/target/product/myron/boot.img
```

If your current workflow requires fastbootd stage first:

```bash
fastboot reboot fastboot
# then run your temporary boot sequence for boot/init_boot/vendor_boot
```

Note: Prefer temporary boot over flash for initial validation.

## 4) First-boot triage capture
As soon as ADB comes up:

```bash
adb wait-for-device
adb shell getprop > firstboot.getprop.txt
adb shell service list > firstboot.services.txt
adb logcat -b all -d > firstboot.logcat.txt
```

Run parity check:

```bash
bash tools/parity_check_myron.sh
```

Preferred one-shot capture for every run:

```bash
DWELL_SECONDS=900 bash tools/first_boot_capture_and_diff.sh ~/android/lineage ~/android/lineage/_checkpoints/phone_baseline_20260304_121337
```

## 5) Pass/fail criteria
Pass (Phase-1 boot confidence):
- Device reaches Android userspace with stable `adb`.
- `adb` remains stable for 10-15 minutes.
- No fatal init crash loop in `logcat`.
- Core services present: power, wifi, bluetooth, radio/ims, gatekeeper/keymint, fingerprint service stubs.
- No new boot-critical AVC class compared to the `2026-03-08` baseline.

Fail (must fix before flash):
- Boot loop before stable `adb`.
- Repeating `init` service crashes.
- Critical HAL/service missing from runtime service list.

## 5a) Confirmed milestone (2026-03-08)
- Remote host fastboot path worked on `john@192.168.200.33`.
- `fastboot boot out/target/product/myron/boot.img` succeeded.
- Device reached `sys.boot_completed=1`.
- `adb` stayed connected.
- Runtime capture completed and parity gate passed:
  - `must_have_missing_count=0`
  - parity status `PASS`

Interpretation:
- The custom `boot.img` is bootable on real hardware.
- This does not yet prove full custom userspace, because `system` / `vendor` / `odm` remained stock during the temporary boot.
- Next escalation should stay minimal and controlled.

## 5b) AVC buckets
Treat these as boot-critical:
- `vendor_init`
- `init`
- `tee` / `qseecomd`
- `vold`
- `system_server`
- `surfaceflinger`
- `audioserver`
- `servicemanager` / `hwservicemanager`

Treat these as deferable unless they become user-visible or block boot:
- `hypsys_*`
- `linkerconfig`
- `lmkd`
- `aconfigd_*`
- `derive_*`
- non-blocking media property reads

## 6) What to do if it fails
- Use `firstboot.logcat.txt` to identify first fatal crash.
- Cross-check service ownership with:
  - `tools/runbooks/startup_ownership_map.md`
- Reintroduce only minimal blob set for failing subsystem.
- Re-run the same boot-only loop.

## 7) Why this loop
This path minimizes risk and cycle time:
- avoids full build/package wait,
- avoids irreversible flashes,
- surfaces real runtime blockers early.

Current insight:
- The residual NFC miss observed in temporary-boot captures is not the current installation blocker.
- The current gating step is userspace image readiness, not more `fastboot boot` iterations.
