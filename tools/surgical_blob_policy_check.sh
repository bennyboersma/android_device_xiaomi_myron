#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TREE_DIR="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"
ALLOW_BROAD_BLOB_EDITS="${ALLOW_BROAD_BLOB_EDITS:-0}"
MAX_BLOB_LINE_CHURN="${MAX_BLOB_LINE_CHURN:-80}"
REFRESH_BLOB_POLICY_BASELINE="${REFRESH_BLOB_POLICY_BASELINE:-0}"

check_file_churn() {
  local repo_dir="$1"
  local rel_file="$2"
  local abs_file="$repo_dir/$rel_file"
  local baseline_root="$TREE_DIR/_checkpoints/policy_baselines"
  local key
  key="$(echo "${repo_dir}_${rel_file}" | sed 's#[/ ]#_#g')"
  local baseline_file="$baseline_root/${key}.baseline"

  if [[ ! -f "$abs_file" ]]; then
    echo "[policy] skip (missing file): $abs_file"
    return 0
  fi

  if git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local ns
    ns=$(git -C "$repo_dir" diff --numstat -- "$rel_file" | awk '{a+=$1; d+=$2} END {print (a+0)" "(d+0)}')
    local add del
    add=$(echo "$ns" | awk '{print $1}')
    del=$(echo "$ns" | awk '{print $2}')
    local churn=$((add + del))

    echo "[policy] git $repo_dir/$rel_file add=${add} del=${del} churn=${churn}"

    if (( churn > MAX_BLOB_LINE_CHURN )) && [[ "$ALLOW_BROAD_BLOB_EDITS" != "1" ]]; then
      echo "BROAD_BLOB_EDIT_BLOCKED repo=$repo_dir file=$rel_file churn=$churn threshold=$MAX_BLOB_LINE_CHURN"
      return 1
    fi
    return 0
  fi

  mkdir -p "$baseline_root"
  if [[ "$REFRESH_BLOB_POLICY_BASELINE" == "1" ]]; then
    cp "$abs_file" "$baseline_file"
    echo "[policy] baseline refreshed: $baseline_file"
    return 0
  fi
  if [[ ! -f "$baseline_file" ]]; then
    cp "$abs_file" "$baseline_file"
    echo "[policy] baseline initialized: $baseline_file"
    return 0
  fi

  local add del churn
  add=$( (diff -U0 "$baseline_file" "$abs_file" || true) | grep -E '^\+[^+]' | wc -l | tr -d ' ' )
  del=$( (diff -U0 "$baseline_file" "$abs_file" || true) | grep -E '^-[^-]' | wc -l | tr -d ' ' )
  churn=$((add + del))
  echo "[policy] baseline $repo_dir/$rel_file add=${add} del=${del} churn=${churn}"

  if (( churn > MAX_BLOB_LINE_CHURN )) && [[ "$ALLOW_BROAD_BLOB_EDITS" != "1" ]]; then
    echo "BROAD_BLOB_EDIT_BLOCKED repo=$repo_dir file=$rel_file churn=$churn threshold=$MAX_BLOB_LINE_CHURN (baseline mode)"
    return 1
  fi
  return 0
}

status=0
check_file_churn "$TREE_DIR/device/xiaomi/myron" "proprietary-files.txt" || status=1
check_file_churn "$TREE_DIR/device/xiaomi/sm8850-common" "proprietary-files.txt" || status=1
bash "$SCRIPT_DIR/check_blob_overlap.sh" "$TREE_DIR" || status=1

if (( status != 0 )); then
  echo "[policy] FAIL (set ALLOW_BROAD_BLOB_EDITS=1 only for intentional wide edits)"
  exit 1
fi

echo "[policy] PASS"
