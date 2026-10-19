#!/usr/bin/env bash
# Configure Time Machine on this Mac. As of 2026-10-19 it had NO backup of any
# kind — no destination, no Backblaze/Arq, iCloud Drive holding 11 MB — so every
# byte existed in one place except what Syncthing mirrored to the old Mac, which
# is being wiped.
#
# Time Machine's destination is not declarative, so this cannot live in nix.
# What nix does own is `system.defaults.TimeMachine.DoNotOfferNewDisksForBackup`.
#
# Usage:  sudo scripts/setup-timemachine.sh /Volumes/<YourDrive>
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "needs sudo: sudo $0 /Volumes/<drive>"; exit 1; }
DEST="${1:-}"
[ -n "$DEST" ] || { echo "usage: sudo $0 /Volumes/<drive>"; exit 1; }
[ -d "$DEST" ] || { echo "no such volume: $DEST"; exit 1; }

USER_HOME=$(eval echo "~${SUDO_USER:-$USER}")

echo "==> destination: $DEST"
tmutil setdestination -a "$DEST"

# Exclusions. The point is to back up what cannot be rebuilt. Everything here
# is either reproducible from a flake/lockfile or pure cache, and together it
# dwarfs the data that actually matters.
echo "==> exclusions"
for p in \
  /nix \
  "$USER_HOME/Library/Caches" \
  "$USER_HOME/.cache" \
  "$USER_HOME/Library/Developer/Xcode/DerivedData" \
  "$USER_HOME/Library/Containers/com.docker.docker" \
  "$USER_HOME/.docker/desktop" \
  "$USER_HOME/go/pkg" \
  "$USER_HOME/.npm" \
  "$USER_HOME/.ollama/models" \
  "$USER_HOME/.t3"
do
  if [ -e "$p" ]; then
    tmutil addexclusion -p "$p" 2>/dev/null && echo "    excluded: $p" || echo "    could not exclude: $p"
  fi
done

# /nix is the big one: rebuildable from flake.lock, and large enough to make
# backups slow enough that they stop happening.
echo "==> enabling automatic backups"
tmutil enable
defaults write /Library/Preferences/com.apple.TimeMachine AutoBackup -bool true

echo
tmutil destinationinfo
echo
echo "Start the first backup with:  tmutil startbackup --block"
echo "It will take a while. Verify afterwards with:  tmutil latestbackup"
