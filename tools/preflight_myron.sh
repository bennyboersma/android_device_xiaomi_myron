#!/usr/bin/env bash
set -euo pipefail

TREE_DIR="${TREE_DIR:-$HOME/android/lineage}"
JOBS="${JOBS:-$(nproc)}"
LUNCH_TARGET="${LUNCH_TARGET:-lineage_myron-trunk_staging-userdebug}"

cd "$TREE_DIR"

echo "[1/8] Host environment hardening check"
bash tools/env_hardening_check.sh "$TREE_DIR"

echo "[2/8] Surgical blob policy check"
bash tools/surgical_blob_policy_check.sh "$TREE_DIR"

export TOP="$TREE_DIR"
set +u
source build/envsetup.sh >/dev/null
lunch "$LUNCH_TARGET" >/dev/null
set -u

echo "[3/8] Soong/Make graph sanity"
m nothing -j"$JOBS"

echo "[4/8] VINTF sanity"
m checkvintf -j"$JOBS"

echo "[5/8] Host init verifier"
m host_init_verifier -j"$JOBS"

echo "[6/8] Boot artifacts only (fast feedback loop)"
m bootimage initbootimage vendorbootimage -j"$JOBS"

echo "[7/8] Artifact existence check"
for f in \
  out/target/product/myron/boot.img \
  out/target/product/myron/init_boot.img \
  out/target/product/myron/vendor_boot.img; do
  [[ -f "$f" ]] || { echo "Missing artifact: $f" >&2; exit 2; }
  ls -lh "$f"
done

if [[ -f out/target/product/myron/dtbo.img ]]; then
  ls -lh out/target/product/myron/dtbo.img
else
  echo "Note: dtbo.img not generated in current target config (treated as optional in preflight)"
fi

echo "[8/8] Preflight complete"
