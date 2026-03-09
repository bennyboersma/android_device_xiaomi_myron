#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TREE_DIR="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"
ALLOW_COPYFILE_BLOB_GROWTH="${ALLOW_COPYFILE_BLOB_GROWTH:-0}"
ALLOWLIST="${ALLOWLIST:-$SCRIPT_DIR/copyfile_blob_collision_allowlist.txt}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 2
  }
}

need_cmd python3

COMMON_FILE="$TREE_DIR/device/xiaomi/sm8850-common/proprietary-files.txt"
MYRON_FILE="$TREE_DIR/device/xiaomi/myron/proprietary-files.txt"
COMMON_MK="$TREE_DIR/device/xiaomi/sm8850-common/common.mk"
MYRON_DEVICE_MK="$TREE_DIR/device/xiaomi/myron/device.mk"
MYRON_LINEAGE_MK="$TREE_DIR/device/xiaomi/myron/lineage_myron.mk"

for f in "$COMMON_FILE" "$MYRON_FILE" "$COMMON_MK" "$MYRON_DEVICE_MK" "$MYRON_LINEAGE_MK" "$ALLOWLIST"; do
  [[ -f "$f" ]] || { echo "Missing file: $f" >&2; exit 2; }
done

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$COMMON_FILE" "$MYRON_FILE" "$COMMON_MK" "$MYRON_DEVICE_MK" "$MYRON_LINEAGE_MK" "$ALLOWLIST" "$tmpdir" <<'PY'
from pathlib import Path
import sys

common_blob = Path(sys.argv[1])
myron_blob = Path(sys.argv[2])
mk_files = [Path(sys.argv[3]), Path(sys.argv[4]), Path(sys.argv[5])]
allowlist_file = Path(sys.argv[6])
tmpdir = Path(sys.argv[7])

REPLACEMENTS = {
    '$(TARGET_COPY_OUT_VENDOR)': 'vendor',
    '$(TARGET_COPY_OUT_ODM)': 'odm',
    '$(TARGET_COPY_OUT_PRODUCT)': 'product',
    '$(TARGET_COPY_OUT_RECOVERY)/root': 'recovery/root',
    '$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk': 'vendor_ramdisk/first_stage_ramdisk',
}


def normalize_dst(dst: str) -> str:
    out = dst.strip()
    for old, new in REPLACEMENTS.items():
        out = out.replace(old, new)
    return out


def active_blob_dsts(path: Path):
    out = set()
    for line in path.read_text().splitlines():
        s = line.strip()
        if not s or s.startswith('#'):
            continue
        left = s.split(';', 1)[0].strip()
        if left.startswith('-'):
            continue
        parts = left.split(':', 1)
        src = parts[0]
        dst = parts[1] if len(parts) == 2 else src
        out.add(dst)
    return out


def copyfile_dsts(path: Path):
    out = set()
    in_copy = False
    for raw in path.read_text().splitlines():
        line = raw.rstrip()
        if 'PRODUCT_COPY_FILES +=' in line:
            in_copy = True
            continue
        if not in_copy:
            continue
        stripped = line.strip()
        if not stripped:
            continue
        continued = stripped.endswith('\\')
        if continued:
            stripped = stripped[:-1].rstrip()
        if ':' in stripped:
            parts = stripped.split(':')
            if len(parts) >= 2:
                out.add(normalize_dst(parts[1]))
        if not continued:
            in_copy = False
    return out


def read_allowlist(path: Path):
    out = set()
    for line in path.read_text().splitlines():
        s = line.strip()
        if not s or s.startswith('#'):
            continue
        out.add(s)
    return out

blob_dsts = active_blob_dsts(common_blob) | active_blob_dsts(myron_blob)
copy_dsts = set()
for mk in mk_files:
    copy_dsts |= copyfile_dsts(mk)

current = copy_dsts & blob_dsts
allow = read_allowlist(allowlist_file)
(tmpdir / 'current.txt').write_text(''.join(f'{p}\n' for p in sorted(current)))
(tmpdir / 'new.txt').write_text(''.join(f'{p}\n' for p in sorted(current - allow)))
(tmpdir / 'resolved.txt').write_text(''.join(f'{p}\n' for p in sorted(allow - current)))
PY

current_count="$(wc -l < "$tmpdir/current.txt" | tr -d ' ')"
new_count="$(wc -l < "$tmpdir/new.txt" | tr -d ' ')"
resolved_count="$(wc -l < "$tmpdir/resolved.txt" | tr -d ' ')"

echo "[copyfile-blob] current_exact_collisions=$current_count"
echo "[copyfile-blob] allowlist_new=$new_count"
echo "[copyfile-blob] allowlist_resolved=$resolved_count"

if [[ "$resolved_count" != "0" ]]; then
  echo "[copyfile-blob] note: some allowlisted collisions are gone; consider refreshing tools/copyfile_blob_collision_allowlist.txt"
fi

if [[ "$new_count" != "0" ]]; then
  echo "[copyfile-blob] new exact copyfile-vs-blob collisions detected:"
  sed -n '1,120p' "$tmpdir/new.txt"
  if [[ "$ALLOW_COPYFILE_BLOB_GROWTH" != "1" ]]; then
    echo "COPYFILE_BLOB_GROWTH_BLOCKED new=$new_count"
    exit 1
  fi
fi

echo "[copyfile-blob] PASS"
