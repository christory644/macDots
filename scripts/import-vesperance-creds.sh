#!/usr/bin/env bash
# Copy ONLY the nine Vesperance logins out of the carried old-Mac keychain into
# this Mac's login keychain, then re-lock the archive.
#
# Deliberately NOT copied, per Christopher's rule that anything re-authable or
# device-specific stays behind:
#   - re-authable: @coderabbitai/cli, Codex MCP Credentials, gh:github.com x2,
#     GitHub - api.github.com, and the five Claude Code-* entries (old tokens
#     keyed to the old username and config dirs — log in fresh instead)
#   - device-specific: jumpcloud.com deviceKey (the OLD machine's JumpCloud
#     identity — if IT ever installs JumpCloud here it could find it and present
#     as the old machine), Raycast database_key/urlcache_key (keys to the old
#     Raycast DB), CommCenter, TelephonyUtilities, Google DriveFS, iCloud,
#     Apple Persistent State Encryption, Zoom Safe Meeting Storage
#
# The archive stays OFF the keychain search list for exactly that reason: while
# it is on the list, any app lacking its own item falls through to the old one.
#
# Usage:  scripts/import-vesperance-creds.sh
set -uo pipefail

SRC="$HOME/Library/Keychains/old-mac-carry.keychain"
[ -f "$SRC" ] || { echo "not found: $SRC"; exit 1; }

# en-dash (U+2013), not a hyphen — these names must match exactly
ITEMS=(
  "Vesperance – Bandcamp|vesperanceband@gmail.com"
  "Vesperance – Bluesky|vesperanceband@gmail.com"
  "Vesperance – Bluesky app password (promo scheduler)|vesperanceband.com"
  "Vesperance – Buffer|vesperanceband@gmail.com"
  "Vesperance – Buffer API|vesperanceband@gmail.com"
  "Vesperance – Instagram|vesperanceband@gmail.com"
  "Vesperance – PayPal|vesperanceband@gmail.com"
  "Vesperance – TikTok|vesperanceband@gmail.com"
  "Vesperance – X|vesperanceband@gmail.com"
)

echo "Unlocking the archive — enter the password you chose when you ran"
echo "carry-keychain-items.sh on the old Mac."
security unlock-keychain "$SRC" || { echo "unlock failed"; exit 1; }

copied=0 failed=0
for entry in "${ITEMS[@]}"; do
  svc="${entry%%|*}"; acct="${entry#*|}"
  printf '  %-52s ' "$svc"
  if pw=$(security find-generic-password -s "$svc" -a "$acct" -w "$SRC" 2>/dev/null); then
    if security add-generic-password -s "$svc" -a "$acct" -w "$pw" -U \
         -j "Carried from the old Mac $(date +%F)" \
         "$HOME/Library/Keychains/login.keychain-db" 2>/dev/null; then
      copied=$((copied+1)); echo "copied"
    else
      failed=$((failed+1)); echo "FAILED to write"
    fi
    unset pw
  else
    failed=$((failed+1)); echo "not found in archive"
  fi
done

security lock-keychain "$SRC"
echo
echo "copied: $copied   failed: $failed   (archive re-locked)"
echo
echo "Verifying against the login keychain only:"
for entry in "${ITEMS[@]}"; do
  svc="${entry%%|*}"
  printf '  %-52s ' "$svc"
  security find-generic-password -s "$svc" "$HOME/Library/Keychains/login.keychain-db" >/dev/null 2>&1 \
    && echo "present" || echo "MISSING"
done
