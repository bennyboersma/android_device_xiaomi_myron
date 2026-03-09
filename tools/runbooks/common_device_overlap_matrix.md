# Common vs Myron Overlap Matrix

Last updated: 2026-03-09

## Scope

Exact duplicate destination paths between:

- `device/xiaomi/sm8850-common/proprietary-files.txt`
- `device/xiaomi/myron/proprietary-files.txt`

This matrix covers the proactively-pruned exact-duplicate high-risk classes:

- `init`
- `vintf`
- `seccomp_policy`
- `permissions/default-permissions`

## Decision rule

- keep the myron-specific entry
- comment the exact duplicate from `sm8850-common`
- only apply when the destination path matches exactly

## Pruned overlaps

| Group | Path | Kept in myron |
|---|---|---|
| init | `vendor/etc/init/vendor.qti.adsprpc-guestos-service.rc` | yes |
| init | `odm/etc/init/init.cirrus.rc` | yes |
| vintf | `vendor/etc/vintf/manifest/bttpi-saidl.xml` | yes |
| init | `vendor/etc/init/vendor.qti.cdsprpc-service.rc` | yes |
| init | `vendor/etc/init/cnd.rc` | yes |
| init | `vendor/etc/init/qwesd.rc` | yes |
| init | `vendor/etc/init/vendor.dpmd.rc` | yes |
| init | `vendor/etc/init/dataadpl.rc` | yes |
| init | `vendor/etc/init/dataqti.rc` | yes |
| init | `vendor/etc/init/port-bridge.rc` | yes |
| init | `vendor/etc/init/shsusrd.rc` | yes |
| vintf | `vendor/etc/vintf/manifest/dataconnection-saidl.xml` | yes |
| vintf | `vendor/etc/vintf/manifest/vendor.qti.diag.hal.service.xml` | yes |
| init | `vendor/etc/init/qdcmss.rc` | yes |
| init | `vendor/etc/init/dumpstate-xiaomi.rc` | yes |
| init | `vendor/etc/init/init.vendor.ins.rc` | yes |
| init | `vendor/etc/init/loc-launcher.rc` | yes |
| init | `vendor/etc/init/vendor.qsap.qapeservice.rc` | yes |
| init | `vendor/etc/init/ims-dataservice-daemon.rc` | yes |
| init | `vendor/etc/init/ims_rtp_daemon.rc` | yes |
| init | `vendor/etc/init/imsdaemon.rc` | yes |
| vintf | `vendor/etc/vintf/manifest/imsdcservice-saidl.xml` | yes |
| vintf | `vendor/etc/vintf/manifest/vendor.qti.hardware.radio.ims.xml` | yes |
| init | `vendor/etc/init/vendor.qti.diag_userdebug.rc` | yes |
| vintf | `odm/etc/vintf/manifest/manifest_vendor.xiaomi.hardware.mfidoca.xml` | yes |
| vintf | `odm/etc/vintf/manifest/manifest_vendor.xiaomi.hardware.mlipay.xml` | yes |
| init | `vendor/etc/init/init.qti.media.rc` | yes |
| init | `vendor/etc/init/qconfig.rc` | yes |
| init | `vendor/etc/init/vendor.qti.media.c2@1.0-service.rc` | yes |
| init | `vendor/etc/init/vendor.qti.media.c2audio@1.0-service.rc` | yes |
| init | `odm/etc/init/vendor.xiaomi.hardware.otrpagent@2.0-service.rc` | yes |
| vintf | `odm/etc/vintf/manifest/manifest_vendor.xiaomi.hardware.otrpagent@2.0.xml` | yes |
| init | `vendor/etc/init/poweropt-service.rc` | yes |
| vintf | `vendor/etc/vintf/manifest/vendor.qti.hardware.power.powermodule.xml` | yes |
| init | `vendor/etc/init/init.qccvendor.rc` | yes |
| init | `vendor/etc/init/init.qti.qcv.rc` | yes |
| init | `vendor/etc/init/qmipriod.debug.rc` | yes |
| init | `vendor/etc/init/qmipriod.rc` | yes |
| init | `vendor/etc/init/vendor.xiaomi.modem.qms@1.0-service.rc` | yes |
| vintf | `vendor/etc/vintf/manifest/vendor.xiaomi.modem.qms.xml` | yes |
| init | `vendor/etc/init/qseecomd.rc` | yes |
| init | `vendor/etc/init/libxiaomi_qcril.rc` | yes |
| init | `vendor/etc/init/qcrilNrd.rc` | yes |
| init | `vendor/etc/init/qms.rc` | yes |
| vintf | `vendor/etc/vintf/manifest/android.hardware.radio.config.xml` | yes |
| vintf | `vendor/etc/vintf/manifest/android.hardware.radio.data.xml` | yes |
| vintf | `vendor/etc/vintf/manifest/android.hardware.radio.messaging.xml` | yes |
| vintf | `vendor/etc/vintf/manifest/android.hardware.radio.modem.xml` | yes |
| vintf | `vendor/etc/vintf/manifest/android.hardware.radio.network.xml` | yes |
| vintf | `vendor/etc/vintf/manifest/android.hardware.radio.sim.xml` | yes |
| vintf | `vendor/etc/vintf/manifest/android.hardware.radio.voice.xml` | yes |
| vintf | `vendor/etc/vintf/manifest/deviceinfo-saidl.xml` | yes |
| vintf | `vendor/etc/vintf/manifest/qcrilhook-saidl.xml` | yes |
| vintf | `vendor/etc/vintf/manifest/qms-saidl.xml` | yes |
| vintf | `vendor/etc/vintf/manifest/qtiradio-saidl.xml` | yes |
| vintf | `vendor/etc/vintf/manifest/vendor.qti.hardware.radio.am.xml` | yes |
| vintf | `vendor/etc/vintf/manifest/vendor.qti.hardware.radio.qtiradioconfig.xml` | yes |
| init | `vendor/etc/init/vendor.qti.rmt_storage.rc` | yes |
| init | `vendor/etc/init/init.vendor.sensors.rc` | yes |
| init | `vendor/etc/init/vendor.sensors.sscrpcd.rc` | yes |
| init | `vendor/etc/init/vendor.qti.tftp.rc` | yes |
| init | `vendor/etc/init/init_thermal-engine-v2.rc` | yes |
| init | `vendor/etc/init/init.time_daemon.rc` | yes |
| init | `vendor/etc/init/trusteduilistener.rc` | yes |
| init | `vendor/etc/init/vppservice.rc` | yes |
| init | `vendor/etc/init/init.vendor.wlan.rc` | yes |
| init | `vendor/etc/init/android.hardware.drm@1.1-service.wfdhdcp.rc` | yes |
| init | `vendor/etc/init/com.qualcomm.qti.wifidisplayhal@1.0-service.rc` | yes |
| init | `vendor/etc/init/wfdvndservice.rc` | yes |
| vintf | `vendor/etc/vintf/manifest/vendor.qti.hardware.wifidisplaysession-service.xml` | yes |

Total pruned exact-duplicate paths: `70`

## Additional pruned overlaps

| Group | Path | Kept in myron |
|---|---|---|
| seccomp | `vendor/etc/seccomp_policy/atfwd@2.0.policy` | yes |
| seccomp | `vendor/etc/seccomp_policy/c2audio.vendor.base-arm64.policy` | yes |
| seccomp | `vendor/etc/seccomp_policy/c2audio.vendor.ext-arm64.policy` | yes |
| permissions | `vendor/etc/default-permissions/com.qualcomm.qti.cne.xml` | yes |
| permissions | `vendor/etc/permissions/camera_extensions.xml` | yes |
| seccomp | `vendor/etc/seccomp_policy/qwesd@2.0.policy` | yes |
| seccomp | `vendor/etc/seccomp_policy/vendor.qti.hardware.dsp.policy` | yes |
| permissions | `vendor/etc/permissions/qti_fingerprint_interface.xml` | yes |
| seccomp | `vendor/etc/seccomp_policy/gnss@2.0-base.policy` | yes |
| seccomp | `vendor/etc/seccomp_policy/gnss@2.0-edgnss-daemon.policy` | yes |
| seccomp | `vendor/etc/seccomp_policy/gnss@2.0-xtwifi-client.policy` | yes |
| seccomp | `vendor/etc/seccomp_policy/qsap_qapeservice.policy` | yes |
| seccomp | `vendor/etc/seccomp_policy/imsrtp.policy` | yes |
| seccomp | `vendor/etc/seccomp_policy/codec2.vendor.base-arm64.policy` | yes |
| seccomp | `vendor/etc/seccomp_policy/codec2.vendor.ext-arm64.policy` | yes |
| seccomp | `vendor/etc/seccomp_policy/qti-systemd.policy` | yes |
| seccomp | `vendor/etc/seccomp_policy/qms.policy` | yes |
| seccomp | `vendor/etc/seccomp_policy/qspm.policy` | yes |
| permissions | `vendor/etc/permissions/noRil/apq_excluded_telephony_features.xml` | yes |
| seccomp | `vendor/etc/seccomp_policy/qcrilnr@2.0.policy` | yes |
| seccomp | `vendor/etc/seccomp_policy/wfdhdcphalservice.policy` | yes |
| seccomp | `vendor/etc/seccomp_policy/wfdvndservice.policy` | yes |
| seccomp | `vendor/etc/seccomp_policy/wifidisplayhalservice.policy` | yes |

Updated total pruned exact-duplicate paths: `94`
