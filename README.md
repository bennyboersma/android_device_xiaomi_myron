# Poco F8 Ultra (myron) Bring-up Status

Last updated: 2026-03-08

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

## Current Objective

Keep the phone on the proven intermediate install path while host-side userspace images finish building:

1. `boot.img` stays stock-exact.
2. `vendor_boot.img` stays stock-exact.
3. `init_boot.img` is the currently proven mutable boot-chain partition.
4. Build full custom userspace images on the host.
5. Stage stock userspace rollback assets (`super.img`, `vbmeta_system.img`) on the remote host.
6. Use a slot-safe logical-partition flash for the first custom userspace test:
   - `tools/check_userspace_flash_readiness.sh`
   - `tools/flash_userspace_images.sh`
   - `tools/runbooks/full_userspace_validation.md`

`fastboot boot` remains useful for safe experimentation, but it is no longer the primary next step. The next milestone is the first custom userspace boot on top of `stock boot + stock vendor_boot + custom init_boot`.

## Latest Progress (2026-03-08)

- Remote host preflight passed end-to-end on `2026-03-08`:
  - `m nothing` PASS
  - `m checkvintf` PASS
  - `m host_init_verifier` PASS
  - `bootimage/init_boot/vendor_boot` PASS
- Rebuilt artifacts verified at `2026-03-08 15:47` on remote host:
  - `out/target/product/myron/boot.img`
  - `out/target/product/myron/init_boot.img`
  - `out/target/product/myron/vendor_boot.img`
- Device-side milestone reached:
  - `fastboot boot out/target/product/myron/boot.img` succeeded
  - phone booted to Android with stable `adb`
  - `adb shell getprop sys.boot_completed` returned `1`
  - `adb shell uname -a` showed Android 16 GKI `6.12`
- Runtime validation artifacts collected:
  - `/home/john/android/lineage/_checkpoints/firstboot_20260308_160952`
  - `/home/john/android/lineage/_checkpoints/parity_20260308_160953`
- Runtime gate result:
  - `must_have_missing_count=0`
  - parity status `PASS`
- Temporary-boot reference tightened with dwell-based capture:
  - `/home/john/android/lineage/_checkpoints/firstboot_20260308_164555`
  - `boot_completed=1`
  - `boot_completed_after_dwell=1`
  - `crash_loop_detected=no`
  - only missing must-have marker: `android.hardware.nfc.INfc/default`
- First minimal persistent boot-chain test executed on slot `_b`:
  - flashed only `boot_b`, `init_boot_b`, `vendor_boot_b`
  - device left Android during dwell and returned to `fastboot`
  - persistent boot-chain equivalence therefore failed
  - stock `3.0.7.0.WPMEUXM` `boot_b/init_boot_b/vendor_boot_b` were restored successfully
  - HyperOS returned on slot `_b`
- Boot-chain isolation follow-up executed on slot `_b`:
  - flashed only `boot_b`
  - device returned directly to `fastboot` before reaching `adb`
  - stock `boot_b` restore returned device to `sys.boot_completed=1`
  - current regression is therefore isolated to the persistent `boot.img` path
- Boot image metadata comparison completed:
  - initial custom `boot.img` AVB footer used `Algorithm: NONE`
  - rebuilt custom `boot.img` now uses `SHA256_RSA4096`
  - stock `boot.img` and rebuilt custom `boot.img` have byte-identical kernel payloads
  - persistent `boot.img` failure is therefore not a kernel/runtime issue
- Exact stock `vbmeta.img` and `vbmeta_system.img` from `3.0.7.0.WPMEUXM` were recovered and staged for rollback.
- Built `lpunpack` on the remote host and unpacked the stock `super.img` to recover raw stock logical partitions.
- Reconstructed multiple custom top-level `vbmeta` candidates:
  - reduced descriptor set
  - chained `boot` descriptor variant
  - near-stock full-descriptor variant including `countrycode`, `dtbo`, `init_boot`, `pvmfw`, `vendor_boot`, `mi_ext`, `odm`, `system_dlkm`, `vendor`, and `vendor_dlkm`
- All tested custom `boot_b + vbmeta_b` combinations still returned directly to `fastboot`.
- Exact rollback to stock `boot_b + vbmeta_b` succeeded after every test.
- Comparison against the published Magisk package for the exact same stock build (`OS3.0.7.0.WPMEUXM`) changed the install-path model:
  - package contains only `boot.img` and `init_boot.img`
  - published `boot.img` keeps Xiaomi stock AVB identity (`8256e695...`)
  - published `init_boot.img` uses `Algorithm: NONE`, same trust model as stock `init_boot`
  - conclusion: the practical mutable partition is `init_boot`, while `boot` should remain stock-exact during this phase
- Local device config and runbook were updated to support this split:
  - stock/prebuilt exact `boot`
  - custom-built `init_boot`
  - partition-selective minimal flash helper for `init_boot`-only testing
- Corrected a critical baseline error on the remote tree:
  - `device/xiaomi/myron/prebuilt/boot.img`, `init_boot.img`, `vendor_boot.img`, and `dtbo.img` were not from the phone's EU stock build
  - replaced all four with exact `3.0.7.0.WPMEUXM` images
- Narrowed rebuild result on the corrected baseline:
  - `out/target/product/myron/boot.img` is now byte-identical to stock EU `boot.img`
  - `out/target/product/myron/init_boot.img` is now genuinely rebuilt from the current tree, not copied from the wrong regional prebuilt
- Persistent `init_boot`-only validation executed successfully on slot `_b`:
  - flashed only `init_boot_b`
  - stock `boot_b` and stock `vendor_boot_b` remained in place
  - device booted normally to Android
  - `sys.boot_completed=1`
  - `sys.boot_completed` remained `1` after dwell
  - `adb` stayed stable
  - `verifiedbootstate=orange`
  - only remaining must-have miss stayed the same: `android.hardware.nfc.INfc/default`
  - boot-critical AVC set improved slightly (`78 -> 77`)
- Current remote host work in progress:
  - full userspace image build is running on `john@192.168.200.33`
  - stock `super.img` staging to the remote rollback directory is in progress
  - first userspace flash will not be attempted until `tools/check_userspace_flash_readiness.sh` passes

What this means:

1. The project is no longer pre-boot; first temporary boot succeeded.
2. The persistent install-path blocker was not "Android can't boot"; it was "we were replacing the wrong partition with the wrong baseline."
3. The correct durable intermediate path is now proven: `stock boot + stock vendor_boot + custom init_boot`.
4. NFC is still not the current gating problem for installation.
5. The next real risk is no longer boot-chain trust; it is the first custom userspace flash and whatever runtime regressions that surfaces.

## Host-Side Tooling Additions (2026-03-05)

New scripts added locally and synced to remote host:

- `tools/validate_critical_services.sh`
- `tools/first_boot_capture_and_diff.sh`
- `tools/env_hardening_check.sh`
- `tools/surgical_blob_policy_check.sh`
- `tools/check_must_have_services.sh`
- `tools/classify_avc_denials.sh`
- `tools/compare_avc_sets.sh`
- `tools/minimal_boot_chain_flash.sh`
- `tools/check_userspace_flash_readiness.sh`
- `tools/flash_userspace_images.sh`
- `tools/rollback_userspace_images.sh`

New first-userspace prep docs/templates:

- `tools/runbooks/manifest_runtime_expectations.md`
- `tools/runbooks/init_service_ownership_audit.md`
- `tools/runbooks/first_userspace_verdict_rules.md`
- `tools/runbooks/first_userspace_blocker_matrix.md`
- `tools/templates/issue_no_adb.md`
- `tools/templates/issue_bootloop.md`
- `tools/templates/issue_decryption.md`
- `tools/templates/issue_nfc.md`

Recommended usage now:

1. Structural ownership check (no dependency on full output images):
   - `bash tools/validate_critical_services.sh ~/android/lineage myron structural`
2. Keep fast host gates green:
   - `bash tools/preflight_myron.sh`
3. Before the first custom userspace flash, require readiness:
   - `CHECK_ROLLBACK=1 REQUIRE_DEVICE=0 bash tools/check_userspace_flash_readiness.sh ~/android/lineage myron`
4. Before the first custom userspace flash, also require package sanity:
   - `bash tools/check_partition_package_sanity.sh ~/android/lineage myron`
5. After any boot attempt, capture and diff in one run:
   - `bash tools/first_boot_capture_and_diff.sh ~/android/lineage ~/android/lineage/_checkpoints/phone_baseline_20260304_121337`
   - includes must-have service gate output (`must_have_gate.txt`)
   - now also emits subsystem-specific grep bundles for display, security, radio, connectivity, camera, audio, and NFC

Current state:

1. `tools/preflight_myron.sh` is now an 8-step gate:
   - environment hardening
   - surgical blob policy
   - `m nothing`
   - `m checkvintf`
   - `m host_init_verifier`
   - boot artifact build
   - artifact existence
2. 8-step preflight pass confirmed on `john@192.168.200.33`.
3. Added operational runbooks:
   - `tools/runbooks/fastboot_myron_command_sheet.md`
   - `tools/runbooks/rollback_pack_preparation.md`
   - `tools/runbooks/minimal_boot_chain_validation.md`
   - `tools/runbooks/full_userspace_validation.md`

## Hardware Support Phases

### Phase 6: Persistent install-path root-cause and boot-critical hardware bring-up (next)

- Combined persistent `boot/init_boot/vendor_boot` flash was attempted once and failed during dwell.
- Follow-up isolation showed `boot.img` alone is sufficient to trigger the regression.
- Rebuilt custom `boot.img` with AVB footer and reconstructed multiple custom `vbmeta` variants.
- Even the near-stock full-descriptor custom `vbmeta` still returns to `fastboot`.
- Stock-boot/custom-init_boot path is now proven on-device.
- Next step is to return to broader userspace/image bring-up while keeping this boot-chain strategy.
- Validate first custom userspace boot on top of the proven path.
- Then validate boot, display, touch, USB, decryption path, keymint/gatekeeper, and ADB stability.
- Verify init services and HAL registration on-device (`lshal`, `dumpsys`, `logcat`).
- Confirm slot/boot chain behavior and recovery path.

### Phase 7: Connectivity stack enablement

- Modem/IMS/RIL verification (SIM detect, calls, data, VoLTE baseline).
- Wi-Fi and Bluetooth bring-up and stability checks.
- GNSS lock and location service validation.

### Phase 8: Multimedia and sensors

- Camera provider + preview/capture/video paths.
- Audio: speaker/mic, wired, BT audio, policy/routing checks.
- Sensors and biometrics (fingerprint/under-display flow).

### Phase 9: Device-specific quality and performance

- NFC, IR, haptics, thermal, charging controls, battery stats.
- Power/perf tuning (idle drain, thermals, sustained load behavior).
- Fix feature regressions and remove temporary compatibility hacks.

### Phase 10: Release hardening

- SELinux enforcing audit cleanup.
- VINTF and init verifier re-check after runtime fixes.
- OTA/upgrade path sanity + rollback safety verification.

## Runtime/Flash Safety Notes

- Keep phone firmware chain aligned to `3.0.7.0.WPMEUXM`.
- Do not mix modem/dsp/bluetooth/trust-chain partitions from unrelated stock releases.
- Prefer boot-first (`fastboot boot` compatible image) before permanent install.
- Stock rollback boot chain staged locally and remotely:
  - local: `/Users/benny/Homelab/ROM/_transfer/rollback_wpm_eu/stock_bootchain_20260308`
  - remote: `/home/john/android/lineage/_transfer/rollback_wpm_eu/stock_bootchain_20260308`
- Exact remote restore command:
  - `/home/john/android/lineage/_transfer/rollback_wpm_eu/restore_commands.sh b`
- Exact stock rollback `vbmeta` images are now staged remotely:
  - `/home/john/android/lineage/_transfer/rollback_wpm_eu/vbmeta.img`
  - `/home/john/android/lineage/_transfer/rollback_wpm_eu/vbmeta_system.img`

## Display Baseline (Stock Reference)

Source dump: `/home/john/android/lineage/_checkpoints/phone_dump_20260304_120716`

- Device: `myron` (`25102PCBEG`)
- Resolution: `1200 x 2608`
- Supported refresh rates: `120Hz`, `90Hz`, `60Hz`
- Stock active mode during capture: `120Hz`
- Color modes present: Native, sRGB, Display P3
- HDR capability reported by framework/surfaceflinger path
- Backlight node path present: `/sys/class/backlight/panel0-backlight` (root required for direct value reads)

Bring-up validation target:

1. Preserve 120/90/60 mode availability on custom build.
2. Confirm smooth mode switching and no flicker/freezes.
3. Confirm HDR/color mode exposure remains present.
4. Use this stock dump as parity baseline for `dumpsys display` and `dumpsys SurfaceFlinger` comparisons.

## Full Phone Baseline (Stock Reference)

Source dump: `/home/john/android/lineage/_checkpoints/phone_baseline_20260304_121337`

Identity and integrity:

- Device: `myron` (`25102PCBEG`)
- Build fingerprint: `POCO/myron_eea/myron:16/.../OS3.0.7.0.WPMEUXM:user/release-keys`
- Vendor fingerprint: `POCO/myron_eea/myron:16/.../OS3.0.7.0.WPMEUXM:user/release-keys`
- Active slot: `_b`
- Verified boot state: `green`
- SELinux: `Enforcing`

Service surface snapshot:

- Binder services listed: `550`
- Dumpsys services listed: `535`
- Marker counts in service list:
  - `radio:42`, `ims:7`, `camera:10`, `audio:15`
  - `fingerprint:4`, `biometric:4`, `nfc:4`
  - `bluetooth:10`, `wifi:8`, `gnss:2`
  - `thermal:2`, `power:9`, `keymint:4`, `gatekeeper:2`

Notable stock AIDL/HAL service markers found:

- Radio stack: AIDL `android.hardware.radio.*` per slot + multiple `vendor.qti.hardware.radio.*` and `vendor.xiaomi.hardware.radio.*` services.
- IMS stack: `vendor.qti.ims.*` services present.
- Camera stack: `android.hardware.camera.provider.ICameraProvider/vendor_qti/0` and Xiaomi camera extension services.
- Biometric stack: `android.hardware.biometrics.fingerprint.IFingerprint/default` + Xiaomi fingerprint extension.
- Connectivity stack: `android.hardware.bluetooth.*`, `android.hardware.nfc.INfc/default`, `wifi` service family.

Bring-up use:

1. Treat this as the stock runtime contract for service/feature parity checks.
2. After custom boot, diff `service list`, `dumpsys -l`, and key `dumpsys` outputs against this baseline.
3. Any missing stock-critical marker in radio/ims/camera/audio/fingerprint should be treated as a release blocker.

## Preflash Manifest/Init Cross-check (2026-03-04)

What was checked:

- Stock runtime service list from phone baseline (`service_list.txt`).
- Device/common VINTF declarations under `device/xiaomi/*/vintf`.
- Packaged blob ownership in `vendor/xiaomi/myron/myron-vendor.mk`.

Current high-risk finding:

- Initial state was ODM-heavy and vendor-light.
- After minimal critical restore set:
  - `myron-vendor.mk` vendor init copies restored: `15`
  - critical vendor VINTF fragments restored via `PRODUCT_PACKAGES`
- Risk remains: any missing runtime-critical service must be restored surgically, not by broad re-adding all blobs.

Likely missing startup-path class (must be source-owned or restored before first flash):

Vendor init examples present in stock blobs:

- `vendor/etc/init/qcrilNrd.rc`
- `vendor/etc/init/libxiaomi_qcril.rc`
- `vendor/etc/init/imsdaemon.rc`
- `vendor/etc/init/ims-dataservice-daemon.rc`
- `vendor/etc/init/ims_rtp_daemon.rc`
- `vendor/etc/init/android.hardware.gnss-aidl-service-qti.rc`
- `vendor/etc/init/android.hardware.bluetooth@aidl-service-qti-debug.rc`
- `vendor/etc/init/vendor.qti.camera.provider-service_64.rc`
- `vendor/etc/init/android.hardware.health-service.qti.rc`
- `vendor/etc/init/android.hardware.power-service.rc`
- `vendor/etc/init/android.hardware.powerstats-service.rc`

Vendor VINTF examples present in stock blobs:

- `vendor/etc/vintf/manifest/android.hardware.radio.*.xml`
- `vendor/etc/vintf/manifest/vendor.qti.hardware.radio.*.xml`
- `vendor/etc/vintf/manifest/vendor.qti.hardware.radio.ims.xml`
- `vendor/etc/vintf/manifest/imsdcservice-saidl.xml`
- `vendor/etc/vintf/manifest/ImsRtpService-aidl.xml`
- `vendor/etc/vintf/manifest/android.hardware.gnss-aidl-service-qti.xml`
- `vendor/etc/vintf/manifest/vendor.qti.gnss-service.xml`
- `vendor/etc/vintf/manifest/bluetooth_*.xml`
- `vendor/etc/vintf/manifest/vendor.qti.camera.provider.xml`
- `vendor/etc/vintf/manifest/android.hardware.health-service.qti.xml`
- `vendor/etc/vintf/manifest/power.xml`

Preflash expectation gate:

1. For each stock-critical service family (radio, ims, gnss, bluetooth, camera, health, power), confirm startup ownership is explicit:
   - source module service + source manifest fragment, or
   - restored blob rc/xml path.
2. Do not flash until no critical family is in an "unowned startup path" state.

## Blocker Matrix (First Boot)

Must-have before calling first boot successful:

- Boot path: `adbd`, `SurfaceFlinger`, `system_server`
- Display/input: internal display active, touch input active
- Security core: `android.hardware.security.keymint.*`, `android.hardware.gatekeeper.*`
- Biometrics baseline: `android.hardware.biometrics.fingerprint.*`
- Connectivity core: `android.hardware.bluetooth.*`, Wi-Fi service family
- Telephony core: `android.hardware.radio.*` (slot1/slot2) + `android.hardware.radio.config.*`
- IMS core: `vendor.qti.hardware.radio.ims.*`, `vendor.qti.ims.*`
- Location core: `android.hardware.gnss.*`
- Camera core: `android.hardware.camera.provider.*`
- Power/health: `android.hardware.power.*`, `android.hardware.health.*`

Nice-to-have for later phases:

- Xiaomi extension services (`vendor.xiaomi.*`) not required for initial boot viability
- Secondary enhancements (CIT helpers, tuning daemons, optional feature services)

Blocker policy:

1. Missing any must-have family is a release blocker.
2. Nice-to-have gaps are tracked but do not block Phase 5 exit.

## Phase Exit Criteria (Hard Pass/Fail)

Phase 5 exit (First Boot Foundation):

- PASS:
  - device boots to UI and stable ADB
  - display + touch functional
  - no continuous init crash loop
  - must-have service families from Blocker Matrix present
- FAIL:
  - bootloop, UI crash loop, no ADB, or any must-have family missing

Phase 6 exit (Radio/Data/Audio Parity):

- PASS:
  - SIM detected
  - mobile data works
  - call path works (at least one successful outgoing/incoming call)
  - VoLTE baseline present (if carrier supports)
  - Wi-Fi + Bluetooth functional
- FAIL:
  - no service registration for radio/ims stack, no data, or call path non-functional

## First-Boot Triage Map

Boot/init:

- `adb shell logcat -b all -d | grep -Ei "init|servicemanager|vintf|avc|fatal"`
- `adb shell dmesg | grep -Ei "init|avc|panic|watchdog"`

Services/HAL:

- `adb shell service list`
- `adb shell dumpsys -l`
- `adb shell lshal`

Telephony/IMS:

- `adb shell dumpsys telephony.registry`
- `adb shell dumpsys ims`
- `adb shell getprop | grep -Ei "ril|radio|ims|qcril"`

Wi-Fi/Bluetooth:

- `adb shell dumpsys wifi`
- `adb shell dumpsys bluetooth_manager`

Camera/Media/Audio:

- `adb shell dumpsys media.camera`
- `adb shell dumpsys media.audio_policy`
- `adb shell dumpsys media.audio_flinger`

Display/Input/Fingerprint:

- `adb shell dumpsys display`
- `adb shell dumpsys SurfaceFlinger`
- `adb shell dumpsys fingerprint`
- `adb shell getevent -lp | head -n 200`

Power/Thermal:

- `adb shell dumpsys power`
- `adb shell dumpsys thermalservice`
- `adb shell dumpsys battery`

Fast parity command:

- Run `/Users/benny/Homelab/ROM/tools/parity_check_myron.sh` after first custom boot.

## Rollback Runbook (3.0.7.0.WPMEUXM)

Goal: immediate recovery path if first custom boot fails.

Pre-stage required files:

- Stock fastboot package matching phone baseline: `3.0.7.0.WPMEUXM` (EU)
- Known-good images from same release family for:
  - `boot`, `init_boot`, `vendor_boot`, `dtbo`
  - firmware chain remains stock-coherent on device

Minimal recovery flow:

1. Reboot bootloader:
   - `adb reboot bootloader`
2. Verify connectivity:
   - `fastboot devices`
3. Flash critical boot path images from stock baseline:
   - `fastboot flash boot boot.img`
   - `fastboot flash init_boot init_boot.img`
   - `fastboot flash vendor_boot vendor_boot.img`
   - `fastboot flash dtbo dtbo.img`
4. Reboot:
   - `fastboot reboot`

If using A/B recovery strategy:

1. Check active slot:
   - `fastboot getvar current-slot`
2. Optionally switch back to known-good slot:
   - `fastboot --set-active=a` (or `b`)
3. Reboot and confirm boot.

Safety rules:

- Do not mix firmware partitions across unrelated stock versions.
- Keep rollback artifacts and commands ready before first flash attempt.

## Fast Resume Commands

```bash
ssh john@192.168.200.33
cd ~/android/lineage
source build/envsetup.sh
lunch lineage_myron-trunk_staging-userdebug
m target-files-package -j$(nproc)
```

## If A New Duplicate Install Error Appears

1. Capture exact destination path from the error.
2. Remove/adjust conflicting blob entry in the appropriate `proprietary-files.txt`.
3. Regenerate:

```bash
cd device/xiaomi/myron
./setup-makefiles.sh
```

4. Re-run the failed gate.
