#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) < 3:
    print("usage: prune_generated_vendor_modules.py <Android.bp> <module> [<module> ...]", file=sys.stderr)
    sys.exit(2)

bp = Path(sys.argv[1])
text = bp.read_text()
removed = []

for name in sys.argv[2:]:
    while True:
        idx = text.find(f'name: "{name}"')
        if idx == -1:
            break
        start = max(
            text.rfind('\ncc_prebuilt_library_shared {', 0, idx),
            text.rfind('\ncc_prebuilt_binary {', 0, idx),
        )
        if start == -1:
            break
        end = text.find('\n}\n', idx)
        if end == -1:
            break
        text = text[:start] + text[end + 3 :]
        removed.append(name)

bp.write_text(text)
for name in removed:
    print(name)
