# Known Bad / Regression Guardrail List

Purpose: prevent reintroducing already-fixed blockers.

## Packaging Duplicates Already Seen

- `vendor/etc/vintf/manifest/android.hardware.health-service.qti.xml`
- `vendor/etc/vintf/manifest/bluetooth_audio.xml`
- `vendor/etc/vintf/manifest/power.xml`

Rule:
- If duplicate install appears for source-generated/service-owned path, keep source provider and remove blob entry.

## Drift Risks

- Reintroducing broad `vendor/etc/vintf/manifest/*` blob restores without ownership validation.
- Reintroducing broad `vendor/etc/init/*` restores without boot-critical need.
- Reintroducing SM8550 assumptions in active myron/sm8850 configs.
- Reintroducing custom persistent `boot.img` flashing as the default install path.
- Replacing `vendor_boot` during the first userspace phase without a concrete blocker.

## Mandatory Check Before Merge

1. Run `tools/preflight_myron.sh`.
2. Confirm no duplicate install errors in Kati.
3. Confirm boot-critical marker file remains current: `tools/boot_critical_markers.txt`.
4. For first userspace attempts, require `tools/check_userspace_flash_readiness.sh` to pass.
