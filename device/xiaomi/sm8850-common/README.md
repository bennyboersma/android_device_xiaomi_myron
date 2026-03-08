# Xiaomi SM8850 Common (Bring-up Base)

This common tree is transitional but now aligned to SM8850 naming for `myron`.

## Effective mapping in this tree

- Board identity from stock blobs: `canoe`
- Platform path used by build system: `kaanapali`

Current key config:
- `TARGET_BOARD_PLATFORM := kaanapali`
- `TARGET_BOOTLOADER_BOARD_NAME := canoe`

Integration note:
- `hardware/qcom-caf/kaanapali` is currently a compatibility integration path while upstream/public SM8850 assets are still being consolidated in-tree.
- Current myron device strategy keeps `boot` stock-exact and treats `init_boot` as the mutable partition during the first install phase.

## Dependency baseline in use

Dependencies currently available/imported:
- `hardware/xiaomi`
- `kernel/xiaomi/sm8850` (currently fallback-backed in this tree)
- `kernel/xiaomi/sm8850-devicetrees` (fallback-backed where needed)
- `kernel/xiaomi/sm8850-modules` (fallback-backed where needed)
- `vendor/xiaomi/sm8850-common`

Until full public SM8850 kernel/vendor trees are integrated end-to-end, fallback linkage remains temporary and should be treated as bring-up scaffolding.

## Integration mode

`device/xiaomi/myron` enables this common tree when:
- `TARGET_SM8850_COMMON_FLAVOR := full`

Without that flag, `myron` builds with its local device config only.

## Placeholders

Vendor common placeholders still expected:
- `vendor/xiaomi/sm8850-common/BoardConfigVendor.mk`
- `vendor/xiaomi/sm8850-common/sm8850-common-vendor.mk`
- `vendor/xiaomi/sm8850-common/common.mk`
