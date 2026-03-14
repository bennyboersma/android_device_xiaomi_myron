#!/usr/bin/env bash
set -euo pipefail

BUNDLE_DIR="${1:?usage: analyze_myron_partition_provenance.sh <bundle_dir>}"
SUMMARY_FILE="${2:-${BUNDLE_DIR}/partition_provenance_summary.txt}"

need_file() {
  [[ -f "$1" ]] || {
    echo "Missing file: $1" >&2
    exit 2
  }
}

need_file "${BUNDLE_DIR}/proc_self_mountinfo.txt"
need_file "${BUNDLE_DIR}/path_provenance.txt"
need_file "${BUNDLE_DIR}/provenance_targets.txt"

python3 - "${BUNDLE_DIR}" "${SUMMARY_FILE}" <<'PY'
import re
import sys
from pathlib import Path

bundle = Path(sys.argv[1])
summary = Path(sys.argv[2])

mountinfo = (bundle / "proc_self_mountinfo.txt").read_text(errors="ignore").splitlines()
mountinfo_pid1 = (bundle / "proc_1_mountinfo.txt").read_text(errors="ignore").splitlines() \
    if (bundle / "proc_1_mountinfo.txt").exists() else []
path_prov = (bundle / "path_provenance.txt").read_text(errors="ignore").splitlines()
targets = (bundle / "provenance_targets.txt").read_text(errors="ignore").splitlines()
slot_facts = (bundle / "slot_facts.txt").read_text(errors="ignore").splitlines() \
    if (bundle / "slot_facts.txt").exists() else []
fastboot_vars = (bundle / "fastboot_vars.txt").read_text(errors="ignore").splitlines() \
    if (bundle / "fastboot_vars.txt").exists() else []

def mount_line(lines, target):
    for line in lines:
        parts = line.split()
        if len(parts) > 4 and parts[4] == target:
            return line
    return ""

paths = {}
current = None
for line in path_prov:
    if line.startswith("== PATH:"):
        current = line.split(":", 1)[1]
        paths[current] = []
        continue
    if current is not None:
        paths[current].append(line)

def path_exists(path):
    lines = paths.get(path, [])
    return any(line.strip() == "exists=yes" for line in lines)

def first_matching(path, pattern):
    regex = re.compile(pattern)
    for line in paths.get(path, []):
        if regex.search(line):
            return line
    return ""

product_marker = ""
system_ext_marker = ""
target_paths = []
for line in targets:
    if line.startswith("product_marker="):
        product_marker = line.split("=", 1)[1]
    elif line.startswith("system_ext_marker="):
        system_ext_marker = line.split("=", 1)[1]
    elif line.startswith("/"):
        target_paths.append(line)

product_mount = mount_line(mountinfo, "/product")
system_ext_mount = mount_line(mountinfo, "/system_ext")
product_mount_pid1 = mount_line(mountinfo_pid1, "/product")
system_ext_mount_pid1 = mount_line(mountinfo_pid1, "/system_ext")

removed_paths = [
    "/product/app/MIUICloudServiceGlobal",
    "/product/app/MIUIMiCloudSync",
    "/product/priv-app/MIUISecurityCenterGlobal",
    "/product/app/MIUISecurityAdd",
    "/product/app/MIUIFileExplorerGlobal",
    "/system_ext/priv-app/FindDevice",
]

removed_present = [path for path in removed_paths if path_exists(path)]
marker_product_present = path_exists(product_marker) if product_marker else False
marker_system_ext_present = path_exists(system_ext_marker) if system_ext_marker else False

branch = "package_manager_reconstruction"
if not marker_product_present or not marker_system_ext_present:
    branch = "wrong_partition_source"
elif removed_present:
    branch = "runtime_rebind_overlay"

lines = []
lines.append(f"bundle_dir={bundle}")
lines.append(f"product_mountinfo={product_mount}")
lines.append(f"system_ext_mountinfo={system_ext_mount}")
if product_mount_pid1:
    lines.append(f"product_mountinfo_pid1={product_mount_pid1}")
if system_ext_mount_pid1:
    lines.append(f"system_ext_mountinfo_pid1={system_ext_mount_pid1}")
lines.append(f"product_marker_path={product_marker}")
lines.append(f"product_marker_present={'yes' if marker_product_present else 'no'}")
lines.append(f"system_ext_marker_path={system_ext_marker}")
lines.append(f"system_ext_marker_present={'yes' if marker_system_ext_present else 'no'}")
for path in removed_paths:
    lines.append(f"path_present[{path}]={'yes' if path_exists(path) else 'no'}")
    stat_line = first_matching(path, r"Device:|File: ")
    if stat_line:
        lines.append(f"path_stat[{path}]={stat_line}")
for line in slot_facts:
    lines.append(f"slot_fact={line}")
for line in fastboot_vars:
    if "current-slot" in line or "slot" in line.lower():
        lines.append(f"fastboot_var={line}")
lines.append(f"recommended_branch={branch}")

summary.write_text("\n".join(lines) + "\n")
print(summary)
PY
