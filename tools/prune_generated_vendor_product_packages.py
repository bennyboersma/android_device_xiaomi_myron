#!/usr/bin/env python3
from pathlib import Path
import argparse


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
        description="Remove generated PRODUCT_PACKAGES entries by exact name."
    )
    parser.add_argument("makefile", help="Path to generated vendor makefile")
    parser.add_argument("packages", nargs="*", help="Exact package names to remove")
    parser.add_argument(
        "--file",
        action="append",
        default=[],
        dest="files",
        help="File containing exact package names to remove, one per line",
    )
    return parser.parse_args()


def block_items(lines: list[str]) -> list[str]:
    items: list[str] = []
    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.endswith("\\"):
            stripped = stripped[:-1].rstrip()
        items.append(stripped)
    return items


def emit_block(header: str, items: list[str]) -> list[str]:
    out = [header]
    for idx, item in enumerate(items):
        suffix = " \\\n" if idx != len(items) - 1 else "\n"
        out.append(f"    {item}{suffix}")
    return out


def main() -> int:
    args = parse_args()
    makefile = Path(args.makefile)
    drop = set(args.packages)
    for path in args.files:
        drop.update(load_names(Path(path)))

    lines = makefile.read_text().splitlines(keepends=True)
    out: list[str] = []
    removed: list[str] = []
    i = 0

    while i < len(lines):
        line = lines[i]
        if line.startswith("PRODUCT_PACKAGES +="):
            header = line
            i += 1
            block: list[str] = []
            while i < len(lines):
                candidate = lines[i]
                if candidate.startswith("    ") or candidate.startswith("\t"):
                    block.append(candidate)
                    i += 1
                    continue
                break

            items = block_items(block)
            kept = [item for item in items if item not in drop]
            removed.extend(item for item in items if item in drop)
            out.extend(emit_block(header, kept))
            continue

        out.append(line)
        i += 1

    makefile.write_text("".join(out))
    for name in removed:
        print(name)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
