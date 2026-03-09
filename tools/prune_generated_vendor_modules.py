#!/usr/bin/env python3
from pathlib import Path
import argparse
import re
import sys


MODULE_START_RE = re.compile(r"^[A-Za-z0-9_]+ \{$")
MODULE_NAME_RE = re.compile(r'^\s*name:\s*"([^"]+)"')


def load_names(path: Path) -> list[str]:
    names: list[str] = []
    for line in path.read_text().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        names.append(stripped)
    return names


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Remove generated vendor prebuilt modules by exact name or prefix."
    )
    parser.add_argument("android_bp", help="Path to generated Android.bp")
    parser.add_argument("modules", nargs="*", help="Exact module names to remove")
    parser.add_argument(
        "--file",
        action="append",
        default=[],
        dest="files",
        help="File containing exact module names to remove, one per line",
    )
    parser.add_argument(
        "--prefix",
        action="append",
        default=[],
        help="Remove modules whose names start with this prefix",
    )
    parser.add_argument(
        "--keep-file",
        action="append",
        default=[],
        dest="keep_files",
        help="File containing exact module names to preserve",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    bp = Path(args.android_bp)
    lines = bp.read_text().splitlines(keepends=True)

    exact = set(args.modules)
    for path in args.files:
        exact.update(load_names(Path(path)))

    prefixes = [p for p in args.prefix if p]
    keep = set()
    for path in args.keep_files:
        keep.update(load_names(Path(path)))

    if not exact and not prefixes:
        print("nothing to prune: provide modules, --file, or --prefix", file=sys.stderr)
        return 2

    removed: list[str] = []
    out: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i].rstrip("\n")
        if not MODULE_START_RE.match(line):
            out.append(lines[i])
            i += 1
            continue

        start = i
        depth = 1
        i += 1
        name = None
        while i < len(lines):
            raw = lines[i]
            stripped = raw.rstrip("\n")
            match = MODULE_NAME_RE.match(stripped)
            if match and name is None:
                name = match.group(1)
            depth += stripped.count("{") - stripped.count("}")
            i += 1
            if depth == 0:
                break

        block = lines[start:i]
        remove = False
        if name and name not in keep:
            if name in exact:
                remove = True
            elif any(name.startswith(prefix) for prefix in prefixes):
                remove = True

        if remove:
            removed.append(name)
        else:
            out.extend(block)

    bp.write_text("".join(out))
    for name in removed:
        print(name)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
