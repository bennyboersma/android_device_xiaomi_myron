# Myron First Userspace Attempt Postmortem (2026-03-09)

## Outcome

The first split-image userspace flash reached `fastbootd`, flashed all intended logical partitions on slot `b`, and rebooted, but the device bootlooped before `adb` came up. The attempt is therefore classified as:

- userspace flash transport: PASS
- first custom userspace boot: FAIL
- immediate verdict: ROLLBACK

## What was flashed

Flashed successfully on slot `b`:

- `system_b`
- `system_ext_b`
- `product_b`
- `vendor_b`
- `odm_b`
- `vendor_dlkm_b`
- `system_dlkm_b`

Not flashed:

- `boot`
- `vendor_boot`
- `init_boot`
- top-level `vbmeta`

## Recovery that was required

The device did not recover from a simple reboot. Recovery required:

1. stock `super`
2. stock `vbmeta_system_b`
3. stock slot-`b` boot-chain restore
   - `boot_b`
   - `init_boot_b`
   - `vendor_boot_b`
   - `vbmeta_b`
   - `dtbo_b`
4. stock slot-`a` verification/boot-chain alignment
   - `boot_a`
   - `init_boot_a`
   - `vendor_boot_a`
   - `vbmeta_a`
   - `dtbo_a`
   - `vbmeta_system_a`
5. `fastboot set_active a`

Recovered state:

- Android boots
- `sys.boot_completed=1`
- build `OS3.0.7.0.WPMEUXM`
- active slot `_a`
- `ro.boot.bootreason=reboot,fastboot`

## Later correction to the recovery conclusion

The initial postmortem correctly identified an early boot failure before `adb`, but later recovery work changed one important conclusion:

- the staged remote "stock" recovery fragments were not a complete Xiaomi fastboot baseline
- repeated partial restores were therefore not valid proof that stock slot `b` itself was bad
- after enough partial recovery work, even slot `a` stopped booting reliably

What this means:

- the next required device action is a full official Xiaomi fastboot restore
- no further interpretation should be made from partial stock restore behavior
- no second Lineage userspace test should happen until that full stock restore is complete

Authoritative recovery artifact:

- package:
  - `myron_eea_global_images_OS3.0.7.0.WPMEUXM_20260112.0000.00_16.0_eea_cee0eaf4a6.tgz`
- MD5:
  - `cee0eaf4a66294c29ae709a22073e670`
- direct Xiaomi CDN:
  - `https://bigota.d.miui.com/OS3.0.7.0.WPMEUXM/myron_eea_global_images_OS3.0.7.0.WPMEUXM_20260112.0000.00_16.0_eea_cee0eaf4a6.tgz`

## Closure note after full official restore

This recovery work is now complete:

- the stock baseline has been restored from the complete official Xiaomi package
- the official package MD5 was verified locally and again on the remote host
- Xiaomi `flash_all_except_storage.sh` completed successfully
- stock boot was reconfirmed with:
  - `ro.boot.slot_suffix=_a`
  - `ro.build.version.incremental=OS3.0.7.0.WPMEUXM`
  - `sys.boot_completed=1`

Superseded conclusions:

- conclusions drawn from partial-stock restore behavior should no longer be treated as authoritative
- partial slot-`b` stock failures are no longer evidence of a proven stock slot-`b` defect

Remaining valid conclusion from the first userspace attempt:

- the flashed custom userspace still failed before `adb`
- the next blocker investigation remains focused on retry-prep build/runtime correctness, not baseline stock recovery

## Concrete blockers before any retry

### 1. Userspace boot blocker is real and early

- The custom userspace set does not reach `adb`.
- No first-userspace capture/verdict bundle was produced from the flashed state.
- The next iteration must produce earlier evidence, or it will remain guesswork.

Required fix before retry:

- add an early failure capture path for the next userspace attempt:
  - immediate `fastboot getvar current-slot`
  - `fastboot getvar is-userspace`
  - `adb wait-for-device` timeout handling
  - automatic branch to `fastboot`/`recovery` detection when `adb` never appears

### 2. Current generated `init_boot` remains unsafe

- Earlier on the same date, generated `out/target/product/myron/init_boot.img` caused a persistent boot regression.
- `device/xiaomi/myron/prebuilt/init_boot.img` is byte-identical to stock.
- First userspace retries must continue to use stock `init_boot`.

Required fix before retry:

- keep `MYRON_USE_PREBUILT_INIT_BOOT_IMAGE := true`
- do not reintroduce generated `init_boot` into the userspace test path

### 3. Rollback tooling had two defects

- `tools/run_userspace_rollback.sh` was invoked incorrectly in practice and could not recover the phone as-is.
- `tools/rollback_userspace_images.sh` assumed `vbmeta_system_ab`, but the device actually exposes:
  - `vbmeta_system_a`
  - `vbmeta_system_b`

Required fix before retry:

- rollback helper must use `vbmeta_system_${slot}`
- rollback wrapper must be verified in a full dry-run against the current device

### 4. Slot health became inconsistent during recovery

Observed metadata before final recovery:

- slot `b`: `slot-unbootable:yes`, `slot-successful:no`
- slot `a`: `slot-successful:yes`

Required fix before retry:

- record slot metadata before flash and after failure
- if testing on slot `b`, make the rollback plan explicitly restore and, if needed, reactivate the known-good slot

### 5. The current userspace set is not yet safe to reflash unchanged

The build artifacts passed host-side readiness and partition sanity, but runtime boot still failed. That means the next blocker is inside the flashed userspace content, not image transport.

High-probability next investigation areas:

1. `vendor`/`odm` bring-up regressions on the reduced first-boot graph
2. critical service ownership or init sequencing after deferring Xiaomi-private stacks
3. trust/storage path regressions that occur before `adb`
4. missing must-have vendor runtime pieces that were over-pruned for first boot

### 6. Partial stock bundles are not recovery-safe

Later inventory against Xiaomi `flash_all*.sh` proved the staged remote recovery set was missing boot-critical payloads, including:

- `vm-bootsys.img`
- `qtvm-dtbo.img`
- `recovery.img`
- multiple firmware / bootloader images such as `xbl`, `uefi`, `tz`, `aop`, and related files

Required fix before retry:

- restore from the complete official Xiaomi fastboot package, not from hand-assembled fragments
- keep the phone in bootloader fastboot until that full package is extracted and verified


## First concrete boot-critical findings after recovery

Stock-vs-built comparison on the recovered device and remote output tree narrows the next likely blocker set.

Confirmed present in the built output:
- NXP keymint strongbox service and manifest are present in `vendor/`, not `odm/`
- NXP weaver service and manifest are present in `vendor/`, not `odm/`
- NFC NXP service and manifest remain present
- camera provider init rc remains present
- power-service init rc remains present

Confirmed missing from the built output as currently staged:
- `vendor/etc/init/android.hardware.gatekeeper-service-qti.rc`
- `vendor/etc/init/android.hardware.health-service.qti.rc`
- `vendor/etc/init/android.hardware.wifi-service.rc`
- `vendor/etc/init/vendor.qti.hardware.display.composer-service.rc`
- `vendor/etc/init/vendor.qti.hardware.display.allocator-service.rc`
- `vendor/etc/init/vendor.qti.hardware.display.color-service.rc`
- `vendor/etc/init/qseecomd.rc`
- `vendor/etc/init/vendor.qti.hardware.secureprocessor.rc`
- matching VINTF fragments for those same families are also missing from the built output

Interpretation:
- keymint/weaver were a path-ownership mismatch in the comparison and are not the leading retry blocker
- the next likely retry blocker is the missing vendor service-ownership cluster around gatekeeper, health, wifi, display, qseecomd, and secureprocessor
- that cluster is more likely to explain an early userspace boot failure before `adb` than the already-deferred Xiaomi extension services

Hard retry gate added:
- `tools/check_retry_boot_critical_vendor_stack.sh` must pass before any second userspace attempt
- current measured result on the staged output: `FAIL missing_boot_critical_vendor_outputs=13`

Follow-up progress after this postmortem:
- Gate 1 on the remote retry-prep tree is now clean.
- The boot-critical failure set was reduced substantially from the original 13-path miss list.
- `qseecomd` ownership has been restored as a source-backed prebuilt.
- The display stack is no longer missing because of Android 16 config misdetection; the remaining blockers are later Qualcomm display source/build issues.

## Recommended next debugging path

1. Do not reflash immediately.
2. Perform a full official Xiaomi stock restore first.
3. Reconfirm Android boot on stock after that full restore.
4. Add early-failure automation to the userspace attempt wrapper.
5. Compare the flashed userspace set against stock partition contents for boot-critical services:
   - init rc ownership
   - VINTF fragments
   - keymint/gatekeeper/TEE stack
   - decryption/vold/fscrypt path
   - display startup path
6. Only after that, attempt a second userspace flash, ideally on the non-current slot with explicit slot-state checkpoints.


## Naming correction from narrow module checks

- `android.hardware.gatekeeper-service-qti` is not a valid build target name in this tree.
- Stock ships the vendor init rc `android.hardware.gatekeeper-service-qti.rc`, but that rc launches `android.hardware.gatekeeper-rust-service-qti`.
- Future retry analysis must distinguish stock rc filenames from actual source module names before treating a service as missing from source.
