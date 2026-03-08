# Startup Ownership Map (myron)

Updated: 2026-03-04

## Must-Have Service Families

| Family | Expected runtime marker | Current ownership path | Status |
|---|---|---|---|
| Radio AIDL | `android.hardware.radio.*` | Blob VINTF restore candidates in `device/xiaomi/myron/proprietary-files.txt` + source framework matrix | Mixed |
| QTI Radio | `vendor.qti.hardware.radio.*` | Blob VINTF restore candidates + source matrix | Mixed |
| IMS | `vendor.qti.ims.*` + `vendor.qti.hardware.radio.ims.*` | Blob VINTF restore candidates, blob init (`ims*.rc`) restored | Mixed |
| GNSS | `android.hardware.gnss.*` | Blob VINTF candidate + source matrix, init path currently source-leaning | Mixed |
| Camera Provider | `android.hardware.camera.provider.ICameraProvider/vendor_qti/0` | Blob init `vendor.qti.camera.provider-service_64.rc` restored; VINTF currently candidate | Mixed |
| Fingerprint | `android.hardware.biometrics.fingerprint.IFingerprint/default` | Primarily source + ODM Xiaomi fragments | OK (verify at boot) |
| Bluetooth | `android.hardware.bluetooth.*` | Source-owned VINTF preferred; blob init debug rc restored | Mixed |
| NFC | `android.hardware.nfc.INfc/default` | Device/common manifests + ODM fragments | Known residual miss on stock-userspace path; not current install blocker |
| Power | `android.hardware.power.*` | Source-owned VINTF preferred; blob init `android.hardware.power-service.rc` restored | Mixed |
| Health | `android.hardware.health.*` | Source-owned VINTF preferred | OK (verify at boot) |
| Keymint/Gatekeeper | `android.hardware.security.keymint.*`, `android.hardware.gatekeeper.*` | Source + ODM strongbox fragments | OK (verify at boot) |

## Current Rule

- If Kati reports duplicate install for a service fragment path, keep source/generated provider and drop the blob line.
- Keep blob init/VINTF only where source ownership is missing at runtime (confirmed by parity check after boot).
- Do not prioritize NFC ownership cleanup ahead of the first custom userspace boot unless it becomes the direct blocker on that path.
