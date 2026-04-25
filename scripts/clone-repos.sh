#!/usr/bin/env bash
#
# clone-repos.sh — clone all repos listed in repos.yml
#
# Skips repos that already exist. Does not delete unlisted repos.
#
set -euo pipefail

DOTS="$(cd "$(dirname "$0")/.." && pwd)"
REPOS_DIR="$HOME/repos"
MANIFEST="$DOTS/repos.yml"

if [ ! -f "$MANIFEST" ]; then
  echo "Error: $MANIFEST not found" >&2
  exit 1
fi

mkdir -p "$REPOS_DIR"

cloned=0
skipped=0
failed=0

while IFS= read -r line; do
  # Skip comments and blank lines
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line// }" ]] && continue

  dir="$(echo "$line" | cut -d: -f1 | xargs)"
  url="$(echo "$line" | cut -d: -f2- | xargs)"

  if [ -d "$REPOS_DIR/$dir" ]; then
    skipped=$((skipped + 1))
  else
    echo "==> Cloning $dir"
    if git clone "$url" "$REPOS_DIR/$dir" 2>/dev/null; then
      cloned=$((cloned + 1))
    else
      echo "    FAILED: $dir ($url)" >&2
      failed=$((failed + 1))
    fi
  fi
done < "$MANIFEST"

echo ""
echo "==> Done: $cloned cloned, $skipped already present, $failed failed"
