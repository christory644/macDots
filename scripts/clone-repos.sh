#!/usr/bin/env bash
#
# clone-repos.sh — clone all repos listed in repos.yml and repos-private.yml
#
# Skips repos that already exist. Does not delete unlisted repos.
#
set -euo pipefail

DOTS="$(cd "$(dirname "$0")/.." && pwd)"
REPOS_DIR="$HOME/repos"

mkdir -p "$REPOS_DIR"

cloned=0
skipped=0
failed=0

clone_from_manifest() {
  local manifest="$1"
  [ -f "$manifest" ] || return 0

  echo "==> Reading $(basename "$manifest")"
  while IFS= read -r line; do
    # Skip comments and blank lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue

    dir="$(echo "$line" | cut -d: -f1 | xargs)"
    url="$(echo "$line" | cut -d: -f2- | xargs)"

    if [ -d "$REPOS_DIR/$dir" ]; then
      skipped=$((skipped + 1))
    else
      echo "    Cloning $dir"
      if git clone "$url" "$REPOS_DIR/$dir" 2>/dev/null; then
        cloned=$((cloned + 1))
      else
        echo "    FAILED: $dir" >&2
        failed=$((failed + 1))
      fi
    fi
  done < "$manifest"
}

clone_from_manifest "$DOTS/repos.yml"
clone_from_manifest "$DOTS/repos-private.yml"

echo ""
echo "==> Done: $cloned cloned, $skipped already present, $failed failed"
