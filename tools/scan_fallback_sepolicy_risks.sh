#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TREE_DIR="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"
ROOT="${2:-$TREE_DIR/device/qcom/sepolicy_vndr/sm8750}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 2
  }
}

need_cmd python3

[[ -d "$ROOT" ]] || {
  echo "Missing fallback sepolicy root: $ROOT" >&2
  exit 2
}

python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])

patterns = {
    "vendor_dpmd_socket_connects": re.compile(
        r'unix_socket_connect\([^,]+,\s*vendor_dpmtcm,\s*vendor_dpmd\)'
    ),
    "forbidden_qdcm_prop_sets": re.compile(
        r'set_prop\([^,]+,\s*vendor_qdcmss_prop\)'
    ),
    "srvctracker_hwservice_adds": re.compile(
        r'add_hwservice\(vendor_hal_srvctracker[^)]*vendor_hal_srvctracker_hwservice\)'
    ),
    "typec_genfs_root": re.compile(
        r'genfscon\s+sysfs\s+/class/typec(?:\s|$)'
    ),
    "default_prop_reads": re.compile(
        r'get_prop\([^,]+,\s*default_prop\)'
    ),
}

results = {}
for label, pattern in patterns.items():
    hits = []
    for path in root.rglob("*"):
        if path.is_dir():
            continue
        if path.name != "genfs_contexts" and path.suffix != ".te":
            continue
        try:
            lines = path.read_text().splitlines()
        except Exception:
            continue
        for lineno, line in enumerate(lines, 1):
            if pattern.search(line):
                hits.append((str(path), lineno, line.strip()))
    results[label] = hits

for label, hits in results.items():
    print(f"=== {label} ({len(hits)}) ===")
    for path, lineno, line in hits[:40]:
        print(f"{path}:{lineno}:{line}")
PY
