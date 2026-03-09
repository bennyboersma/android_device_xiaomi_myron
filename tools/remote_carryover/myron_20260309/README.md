# Myron Retry-Prep Remote Carryover (2026-03-09)

This bundle captures the remote-only changes that produced a passing Gate 1 and Gate 2 state on:

- host: `john@192.168.200.33`
- tree: `~/android/lineage`
- target: `lineage_myron-trunk_staging-userdebug`

## Contents

- `files/`:
  - exact file snapshots from the passing remote tree
- `hardware_qcom-caf_common_BoardConfigQcom.patch`:
  - git diff patch from the one remote git repo (`hardware/qcom-caf/common`)
- `SHA256SUMS`:
  - content hashes for all captured file snapshots
- `remote_gate1_pass.log`:
  - output from `bash tools/run_retry_prep_gate1.sh ~/android/lineage myron`
- `remote_gate2_pass.log`:
  - output from `bash tools/run_retry_prep_gate2.sh ~/android/lineage myron`
- `apply_on_remote.sh`:
  - deterministic apply script for this carryover set

## Authoritative Source Mapping

- Local repo (tracked in this repository):
  - slot-safe userspace orchestration scripts under `tools/`
  - `vendor/xiaomi/myron/Android.bp`
  - `vendor/xiaomi/sm8850-common/Android.bp`
- Remote Qualcomm tree (captured here as snapshot fallback):
  - `hardware/qcom-caf/kaanapali/display/...`
  - `hardware/qcom-caf/common/BoardConfigQcom.mk`
- Vendor prebuilt package definition:
  - `vendor/xiaomi/sm8850-common/Android.bp` (`libvmmem` prebuilt metadata)

## Apply Order (Decision-Complete)

1. Apply `files/hardware/qcom-caf/common/BoardConfigQcom.mk`
2. Apply `files/hardware/qcom-caf/kaanapali/display/hal/config/display-product.mk`
3. Apply `files/hardware/qcom-caf/kaanapali/display/hal/services/config/src/Android.bp`
4. Apply `files/hardware/qcom-caf/kaanapali/display/core/sde-drm/drm_panel_feature_mgr.cpp`
5. Apply `files/hardware/qcom-caf/kaanapali/display/hal/gralloc/Android.bp`
6. Apply `files/hardware/qcom-caf/kaanapali/display/core/snapalloc/Android.bp`
7. Apply `files/vendor/xiaomi/myron/Android.bp`
8. Apply `files/vendor/xiaomi/sm8850-common/Android.bp`

Apply and verify with:

```bash
bash tools/remote_carryover/myron_20260309/apply_on_remote.sh ~/android/lineage
bash tools/run_retry_prep_gate1.sh ~/android/lineage myron
TARGET_SLOT=b bash tools/run_retry_prep_gate2.sh ~/android/lineage myron
```

Expected:

- Gate 1 passes (`m nothing -j10`)
- Gate 2 passes and includes:
  - `vendor/bin/qseecomd`
  - `vendor/bin/hw/vendor.qti.hardware.display.composer-service`
  - `vendor/bin/hw/vendor.qti.hardware.display.allocator-service`
  - `vendor.qti.hardware.display.composer-service3_v3.xml`

