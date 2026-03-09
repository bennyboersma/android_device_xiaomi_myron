#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TREE_DIR="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"
ALLOW_BLOB_OVERLAP_GROWTH="${ALLOW_BLOB_OVERLAP_GROWTH:-0}"
ALLOWLIST="${ALLOWLIST:-$SCRIPT_DIR/blob_overlap_allowlist.txt}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 2
  }
}

need_cmd python3

COMMON_FILE="$TREE_DIR/device/xiaomi/sm8850-common/proprietary-files.txt"
MYRON_FILE="$TREE_DIR/device/xiaomi/myron/proprietary-files.txt"

[[ -f "$COMMON_FILE" ]] || { echo "Missing file: $COMMON_FILE" >&2; exit 2; }
[[ -f "$MYRON_FILE" ]] || { echo "Missing file: $MYRON_FILE" >&2; exit 2; }
[[ -f "$ALLOWLIST" ]] || { echo "Missing allowlist: $ALLOWLIST" >&2; exit 2; }

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$COMMON_FILE" "$MYRON_FILE" "$ALLOWLIST" "$tmpdir" <<'PY'
from pathlib import Path
import sys

common_file = Path(sys.argv[1])
myron_file = Path(sys.argv[2])
allowlist_file = Path(sys.argv[3])
tmpdir = Path(sys.argv[4])

def active_dsts(path: Path):
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

def read_allowlist(path: Path):
    out = set()
    for line in path.read_text().splitlines():
        s = line.strip()
        if not s or s.startswith('#'):
            continue
        out.add(s)
    return out

current = active_dsts(common_file) & active_dsts(myron_file)
allow = read_allowlist(allowlist_file)

(tmpdir / "current.txt").write_text("".join(f"{p}\n" for p in sorted(current)))
(tmpdir / "new.txt").write_text("".join(f"{p}\n" for p in sorted(current - allow)))
(tmpdir / "resolved.txt").write_text("".join(f"{p}\n" for p in sorted(allow - current)))
PY

current_count="$(wc -l < "$tmpdir/current.txt" | tr -d ' ')"
new_count="$(wc -l < "$tmpdir/new.txt" | tr -d ' ')"
resolved_count="$(wc -l < "$tmpdir/resolved.txt" | tr -d ' ')"

echo "[overlap] current_exact_destination_overlaps=$current_count"
echo "[overlap] allowlist_new=$new_count"
echo "[overlap] allowlist_resolved=$resolved_count"

if [[ "$resolved_count" != "0" ]]; then
  echo "[overlap] note: some allowlisted overlaps are gone; consider refreshing tools/blob_overlap_allowlist.txt"
fi

if [[ "$new_count" != "0" ]]; then
  echo "[overlap] new exact destination overlaps detected:"
  sed -n '1,120p' "$tmpdir/new.txt"
  if [[ "$ALLOW_BLOB_OVERLAP_GROWTH" != "1" ]]; then
    echo "BLOB_OVERLAP_GROWTH_BLOCKED new=$new_count"
    exit 1
  fi
fi

echo "[overlap] PASS"
