# Myron First Userspace Blocker Matrix

Purpose: classify the first custom-userspace boot result into concrete blocker buckets fast, using the current device manifests and proven install path.

## Current baseline

Do not use this matrix until the device is on:
- stock `boot`
- stock `vendor_boot`
- stock `init_boot`

The next unknown is custom userspace, not top-level boot trust.

Current real blocker after the first attempt:
- the first split-image userspace flash bootlooped before `adb`
- see `tools/runbooks/first_userspace_attempt_postmortem_20260309.md`

## Fast gate order

1. `sys.boot_completed`
2. stable `adb`
3. decryption / userdata mount state
4. keymint / gatekeeper / tee path
5. display / touch / USB
6. radio / IMS / data
7. Wi-Fi / Bluetooth
8. camera
9. audio
10. NFC

## Matrix

| Subsystem | Must-have markers / evidence | Manifest / source of expectation | First commands / files to inspect | Immediate interpretation |
|---|---|---|---|---|
| Boot core | `sys.boot_completed=1`, stable `adb`, no crash loop | N/A | `verdict.txt`, `firstboot.critical_log_grep.txt`, `firstboot.key_props.txt` | If this fails, stop and debug boot/runtime before subsystem work |
| Display / touch | `SurfaceFlinger:` marker, visible UI, working touch | framework + display stack | `firstboot.display_log_grep.txt`, `firstboot.dumpsys_l.txt`, `getevent` | If missing, treat as early userspace blocker |
| Decryption / userdata | `/data` mounted correctly, no credential-encrypted regression | vold/init path | `firstboot.mount.txt`, `firstboot.critical_log_grep.txt`, `logcat grep vold fscrypt` | If broken, rollback before broader subsystem triage |
| Keymint / Gatekeeper / TEE | `android.hardware.security.keymint.IKeyMintDevice/default`, `android.hardware.gatekeeper.IGatekeeper/default` | `device/xiaomi/myron/vintf/manifest.xml`, `manifest_kalama.xml` | `firstboot.security_log_grep.txt`, `firstboot.service_list.txt`, `firstboot.lshal.txt` | Missing here usually points to TEE/service init/SELinux |
| Radio / IMS | `android.hardware.radio.*`, `vendor.qti.hardware.radio.ims.IImsRadio/imsradio0`, `vendor.qti.ims.factoryaidlservice.IImsFactory/default` | `manifest_xiaomi.xml`, `manifest_kalama.xml`, `framework_matrix.xml` | `firstboot.radio_log_grep.txt`, `firstboot.key_props.txt`, `dumpsys telephony.registry`, `dumpsys ims` | Missing here blocks telephony/data bring-up |
| Wi-Fi / Bluetooth | `android.hardware.bluetooth.IBluetoothHci/default`, Wi-Fi stack present | `manifest_kalama.xml`, Wi-Fi overlays | `firstboot.connectivity_log_grep.txt`, `firstboot.service_list.txt`, `dumpsys wifi`, `dumpsys bluetooth_manager` | If BT service is absent, check vendor HAL ownership; if Wi-Fi fails, inspect supplicant/hostapd path |
| Camera | `android.hardware.camera.provider.ICameraProvider/vendor_qti/0` | `device/xiaomi/myron/vintf/manifest.xml` | `firstboot.camera_log_grep.txt`, `firstboot.service_list.txt`, `dumpsys media.camera` | Missing provider is a direct camera blocker |
| Audio | Audio services up, routing sane | `manifest_kalama.xml`, audio HAL/service ownership | `firstboot.audio_log_grep.txt`, `dumpsys media.audio_policy`, `dumpsys media.audio_flinger` | If audioserver loops, treat as boot-critical |
| NFC | `android.hardware.nfc.INfc/default` | `manifest_xiaomi.xml`, `framework_matrix.xml` | `firstboot.nfc_log_grep.txt`, `firstboot.dumpsys_nfc.txt`, `firstboot.nfc_props.txt` | Known residual miss on stock-userspace path; do not prioritize before first custom userspace result |

## Minimum verdict to continue

Continue past the first custom userspace boot only if:

- `boot_completed=1`
- `adb` stable after dwell
- no catastrophic crash loop
- no decryption regression
- no slot confusion

If any of those fail, stop subsystem triage and debug the base boot/userspace path first.

## Files produced by the capture pack that matter most

- `verdict.txt`
- `must_have_gate.txt`
- `firstboot.critical_log_grep.txt`
- `firstboot.key_props.txt`
- `firstboot.mount.txt`
- `firstboot.lshal.txt`
- `firstboot.service_list.txt`
- `firstboot.display_log_grep.txt`
- `firstboot.security_log_grep.txt`
- `firstboot.radio_log_grep.txt`
- `firstboot.connectivity_log_grep.txt`
- `firstboot.camera_log_grep.txt`
- `firstboot.audio_log_grep.txt`
- `firstboot.nfc_log_grep.txt`


## First retry blocker refinement (2026-03-09 postmortem)

Highest-confidence blockers before a second userspace flash:

1. Missing vendor init/VINTF ownership for:
   - gatekeeper
   - health
   - wifi
   - display composer / allocator / color
   - qseecomd
   - secureprocessor
2. Rollback path correctness under real failure:
   - slot-specific `vbmeta_system_${slot}`
   - wrapper argument handling
3. Early-failure evidence gap:
   - next attempt must capture slot metadata and failure state when `adb` never appears

Explicitly deprioritized after comparison:
- NXP keymint/weaver packaging, because those services are present in the built output under `vendor/`
- NFC, because its service remains present and it is not the earliest boot blocker
