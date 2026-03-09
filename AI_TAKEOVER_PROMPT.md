# Myron Retry-Prep Takeover Prompt

You are taking over Poco F8 Ultra (`myron`) bring-up from `/Users/benny/Homelab/ROM`.

Read first:

1. `/Users/benny/Homelab/ROM/HANDOFF.md`
2. `/Users/benny/Homelab/ROM/README.md`
3. `/Users/benny/Homelab/ROM/tools/runbooks/first_userspace_attempt_postmortem_20260309.md`

Environment:

- Local workspace: `/Users/benny/Homelab/ROM`
- Remote Android tree: `john@192.168.200.33:/home/john/android/lineage`
- Lunch target: `lineage_myron-trunk_staging-userdebug`
- Device baseline: full official Xiaomi stock restore completed successfully; stock slot `_a` is booting `OS3.0.7.0.WPMEUXM`

Current proven state:

- Recovery baseline uncertainty is closed.
- Do not do any new recovery reconstruction or partial stock flashing.
- Gate 1 is passing again on the remote tree:
  - `bash tools/run_retry_prep_gate1.sh ~/android/lineage myron`
- Gate 1 now has a repo-side fallback prune for dead generated `PRODUCT_PACKAGES`:
  - `/Users/benny/Homelab/ROM/tools/prune_generated_vendor_product_packages.py`
  - `/Users/benny/Homelab/ROM/tools/run_retry_prep_gate1.sh`
- Gate 2 is still failing:
  - `bash tools/run_retry_prep_gate2.sh ~/android/lineage myron`
  - current result: `missing_boot_critical_vendor_outputs=7`

Exact remaining Gate 2 misses:

1. `vendor/etc/init/android.hardware.gatekeeper-service-qti.rc`
2. `vendor/bin/hw/android.hardware.gatekeeper-rust-service-qti`
3. `vendor/etc/vintf/manifest/android.hardware.gatekeeper-service-qti.xml`
4. `vendor/etc/init/qseecomd.rc`
5. `vendor/etc/init/vendor.qti.hardware.secureprocessor.rc`
6. `vendor/bin/hw/vendor.qti.hardware.secureprocessor`
7. `vendor/etc/vintf/manifest/vendor.qti.hardware.secureprocessor.xml`

Important interpretation:

- Display composer/allocator is no longer the active missing-output blocker.
- `vendor/bin/qseecomd` is present in output, but `qseecomd.rc` still is not.
- The remaining blocker cluster is gatekeeper + `qseecomd.rc` + secureprocessor vendor ownership/install.
- The blobs exist under `vendor/xiaomi/myron/proprietary`, but they are still not landing in final output.

Local repo changes already made:

- `tools/boot_critical_vendor_outputs.txt` now includes gatekeeper, `qseecomd.rc`, and secureprocessor checks.
- `tools/check_stock_critical_alignment.sh` exists to compare stock device presence vs built output.
- `vendor/xiaomi/myron/Android.bp` includes explicit prebuilt service modules for:
  - `android.hardware.gatekeeper-rust-service-qti`
  - `qseecomd` with `init_rc`
  - `vendor.qti.hardware.secureprocessor`
- `vendor/xiaomi/myron/myron-vendor.mk` includes:
  - `android.hardware.gatekeeper-rust-service-qti`
  - `qseecomd`
  - `vendor.qti.hardware.secureprocessor`

What to do next:

1. Verify the remote tree still matches the local repo changes.
2. Inspect why the explicit vendor prebuilt modules are still not installing:
   - module visibility / namespace
   - module pruning side effects
   - whether `myron-vendor.mk` package inclusion survives the Gate 1 prune pass
   - whether `init_rc` / `vintf_fragments` on these prebuilts are being ignored or overridden
3. Check:
   - `out/soong/installs-lineage_myron.mk`
   - `out/soong/.intermediates/vendor/xiaomi/myron/...`
   - `out/target/product/myron/vendor/...`
4. Do not run another userspace flash attempt until Gate 2 is fully green.

Useful commands:

```bash
ssh john@192.168.200.33
cd ~/android/lineage
bash tools/run_retry_prep_gate1.sh ~/android/lineage myron
bash tools/run_retry_prep_gate2.sh ~/android/lineage myron
bash tools/check_stock_critical_alignment.sh ~/android/lineage myron
rg -n "gatekeeper|qseecomd|secureprocessor" vendor/xiaomi/myron/Android.bp vendor/xiaomi/myron/myron-vendor.mk device/xiaomi/myron/proprietary-files.txt
rg -n "gatekeeper|qseecomd|secureprocessor" out/soong/installs-lineage_myron.mk
find out/target/product/myron/vendor -path '*gatekeeper*' -o -path '*qseecomd*' -o -path '*secureprocessor*'
```

Constraint:

- Keep slot `a` on stock.
- No new device-side writes unless Gate 2 goes green first.
