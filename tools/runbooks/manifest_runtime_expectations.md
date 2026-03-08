# Myron Manifest-To-Runtime Expectations

Purpose: define the first custom-userspace runtime surface that should exist, based on the current device manifests and the must-have marker set.

## Source files

- `device/xiaomi/myron/vintf/manifest.xml`
- `device/xiaomi/sm8850-common/configs/vintf/manifest_kalama.xml`
- `device/xiaomi/sm8850-common/configs/vintf/manifest_xiaomi.xml`
- `tools/boot_critical_markers.txt`

## First-userspace must-have runtime set

These are the hard expectations for the first custom-userspace boot:

- `android.hardware.radio.config.IRadioConfig/default`
- `android.hardware.radio.data.IRadioData/slot1`
- `android.hardware.radio.modem.IRadioModem/slot1`
- `android.hardware.radio.network.IRadioNetwork/slot1`
- `vendor.qti.hardware.radio.ims.IImsRadio/imsradio0`
- `vendor.qti.ims.factoryaidlservice.IImsFactory/default`
- `android.hardware.camera.provider.ICameraProvider/vendor_qti/0`
- `android.hardware.biometrics.fingerprint.IFingerprint/default`
- `android.hardware.bluetooth.IBluetoothHci/default`
- `android.hardware.nfc.INfc/default`
- `android.hardware.gnss.IGnss/default`
- `android.hardware.security.keymint.IKeyMintDevice/default`
- `android.hardware.gatekeeper.IGatekeeper/default`
- `android.hardware.power.IPower/default`
- `android.hardware.health.IHealth/default`
- `wifi:`
- `SurfaceFlinger:`
- `adb:`

## Important nuance

Not every declared HAL must be treated as a day-one blocker.

Day-one blockers:
- boot core
- display / touch
- decryption
- keymint / gatekeeper / tee
- radio / IMS
- Wi-Fi / Bluetooth
- camera provider
- power / health

Do not over-prioritize yet:
- NFC
- CIT/test services
- optional Xiaomi feature services
- non-user-visible vendor adjunct HALs

## Current insight

- On the proven `stock boot + stock vendor_boot + custom init_boot` path, NFC remained missing.
- That did not block successful persistent boot.
- Therefore NFC remains a tracked delta, but not the gating installation blocker before the first custom userspace boot.

## How to use this file

1. Run the first custom userspace boot.
2. Capture with `tools/first_boot_capture_and_diff.sh`.
3. Compare `must_have_gate.txt`, `firstboot.service_list.txt`, and `firstboot.lshal.txt` to this expected surface.
4. Use `tools/runbooks/first_userspace_blocker_matrix.md` to classify failures.
