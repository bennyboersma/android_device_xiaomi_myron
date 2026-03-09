# Myron Platform Naming Debt Audit

Last updated: 2026-03-09

## Goal

Separate harmless legacy path naming from real platform-target debt while the device target remains `SM8850` / `kaanapali`.

## Confirmed target

- device target: `SM8850`
- active platform namespace: `hardware/qcom-caf/kaanapali`
- this audit does not change the target platform identity

## Still-present naming debt

Confirmed remaining references under `device/xiaomi/sm8850-common`:

- `TARGET_KERNEL_SOURCE := kernel/xiaomi/sm8550`
- `TARGET_KERNEL_EXT_MODULE_ROOT := kernel/xiaomi/sm8550-modules`
- `vendor/kalama_GKI.config`
- `configs/vintf/manifest_kalama.xml`
- audio package names:
  - `audio.primary.kalama`
  - `sound_trigger.primary.kalama`
- audio config paths under:
  - `configs/audio/sku_kalama/`
  - `hardware/qcom-caf/kaanapali/audio/*/configs/kalama/`
- power config path:
  - `vendor/qcom/opensource/power/config/kalama/powerhint.xml`
- sensor permission install paths under:
  - `vendor/etc/permissions/sku_kalama/`
- one carrier overlay entry still uses:
  - `device=\"kalama\"`

## Risk classification

### Higher-risk debt

These can still reflect real wrong-platform assumptions and should be treated as actual migration debt:

- kernel source path:
  - `kernel/xiaomi/sm8550`
- kernel module root:
  - `kernel/xiaomi/sm8550-modules`
- `manifest_kalama.xml` if its contents encode the wrong HAL surface rather than just carrying a legacy filename

### Likely path-only / lower-risk debt

These are often just legacy SKU or path names and are not by themselves proof of a wrong target:

- `vendor/kalama_GKI.config`
- `audio.primary.kalama`
- `sound_trigger.primary.kalama`
- `configs/audio/sku_kalama/*`
- `configs/.../kalama/*`
- `sku_kalama` permission install directories
- carrier overlay `device=\"kalama\"`

These should not be mass-renamed blindly during active bring-up unless a concrete build or runtime issue points at them.

## Recommended order

1. Do not churn low-risk path names while the first userspace build is still maturing.
2. Keep tracking the high-risk kernel/common naming debt.
3. Only change lower-risk `kalama` names when:
   - a build failure proves the path is wrong, or
   - a real `SM8850` upstream source tree becomes available and gives a concrete replacement.

## Related packaging-risk audit

The more immediate host-side structural risk is not the naming debt. It is the active overlap between:

- `device/xiaomi/sm8850-common/proprietary-files.txt`
- `device/xiaomi/myron/proprietary-files.txt`

Current overlap framing:

- current exact common-vs-myron destination overlap baseline:
  - `622` destination paths
  - enforced by:
    - `tools/check_blob_overlap.sh`
    - `tools/blob_overlap_allowlist.txt`
- earlier manual bucketing of the highest-risk overlap classes identified:
  - `init`: `46`
  - `display`: `25`
  - `vintf`: `24`
  - `seccomp`: `19`
  - `power-perf`: `17`
  - `radio-ims`: `11`

That overlap remains the next likely packaging-collision class once the full userspace build reaches image assembly, but the live regression gate is now the `622`-path exact overlap baseline.
