#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-$PWD/_checkpoints/env_$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$OUT_DIR"

{
  echo "timestamp=$(date -Is)"
  echo "host=$(hostname)"
  echo "kernel=$(uname -a)"
  echo "cwd=$PWD"
  echo
  echo "java_version:"
  java -version 2>&1 || true
  echo
  echo "python_version:"
  python3 --version 2>&1 || true
  echo
  echo "clang_version:"
  clang --version 2>&1 | head -n 2 || true
  echo
  echo "adb_version:"
  adb version 2>&1 || true
  echo
  echo "fastboot_version:"
  fastboot --version 2>&1 || true
} > "$OUT_DIR/build_env_manifest.txt"

echo "$OUT_DIR/build_env_manifest.txt"
