# Myron Init / Service Ownership Audit

Purpose: map the critical first-userspace services to the init rc paths and binaries currently expected in the tree or blobs.

## Radio / IMS

Observed init ownership candidates:

- `vendor/etc/init/imsdaemon.rc`
  - service: `vendor.imsdaemon`
  - binary: `/vendor/bin/imsdaemon`
- `vendor/etc/init/ims-dataservice-daemon.rc`
  - service: `vendor.ims-dataservice-daemon`
  - binary: `/vendor/bin/ims-dataservice-daemon`
- `vendor/etc/init/ims_rtp_daemon.rc`
  - service: `vendor.ims_rtp_daemon`
  - binary: `/vendor/bin/ims_rtp_daemon`

Runtime expectation tie-in:
- `vendor.qti.hardware.radio.ims.IImsRadio/imsradio0`
- `vendor.qti.ims.factoryaidlservice.IImsFactory/default`

## Camera

Observed init ownership:

- `vendor/etc/init/vendor.qti.camera.provider-service_64.rc`
  - service: `vendor.camera-provider`
  - binary: `/vendor/bin/hw/vendor.qti.camera.provider-service_64`
  - interfaces:
    - `android.hardware.camera.provider.ICameraProvider/vendor_qti/0`
    - `vendor.qti.hardware.camera.offlinecamera.IOfflineCameraService/default`
    - `vendor.qti.hardware.camera.aon.IAONService/default`
    - `vendor.xiaomi.hardware.quickcamera.IQuickCameraService/default`

## Wi-Fi / Bluetooth

Observed init ownership:

- `vendor/etc/init/android.hardware.wifi-service.rc`
  - service: `vendor.wifi_hal_legacy`
  - binary: `/vendor/bin/hw/android.hardware.wifi-service`
- `vendor/etc/init/android.hardware.wifi.supplicant-service.rc`
  - interface:
    - `android.hardware.wifi.supplicant.ISupplicant/default`
    - `vendor.qti.hardware.wifi.supplicant.ISupplicantVendor/default`
- `vendor/etc/init/hostapd.android.rc`
  - service: `hostapd`
  - interface:
    - `android.hardware.wifi.hostapd.IHostapd/default`
- `vendor/etc/init/android.hardware.bluetooth@aidl-service-qti-debug.rc`
  - service: `vendor.bluetooth-aidl-qti`
  - binary: `/vendor/bin/hw/android.hardware.bluetooth@aidl-service-qti`

## Keymint / Gatekeeper

Observed init ownership:

- `vendor/etc/init/android.hardware.gatekeeper-service-qti.rc`
  - service: `vendor.gatekeeper_default`
  - binary: `/vendor/bin/hw/android.hardware.gatekeeper-rust-service-qti`
- `vendor/etc/init/android.hardware.security.onekeymint-service-qti.rc`
  - service: `vendor.keymint`
  - binary: `/vendor/bin/hw/android.hardware.security.onekeymint-service-qti`
- `odm/etc/init/android.hardware.security.keymint3-service.strongbox.nxp.rc`
  - service: `vendor.keymint-strongbox`
  - binary: `/odm/bin/hw/android.hardware.security.keymint3-service.strongbox.nxp`

## Known risk

The first custom userspace boot may fail in one of two ownership patterns:

1. service declared in manifest, but init service never starts
2. service starts, but HAL never registers due to SELinux / dependency / binary path issues

Use this audit with:
- `firstboot.service_list.txt`
- `firstboot.key_props.txt`
- `firstboot.critical_log_grep.txt`
- subsystem grep outputs from `tools/first_boot_capture_and_diff.sh`
