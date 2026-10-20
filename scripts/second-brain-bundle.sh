#!/usr/bin/env bash
# Encrypted offsite backup of second_brain.
#
# second_brain has NO git remote, deliberately — it is highly personal and
# Christopher does not want it visible to GitHub even privately. A bundle is the
# shape that fits: one file, encrypted, that can live in iCloud Drive without
# the host being able to read it.
#
# It goes to iCloud Drive -> Documents -> backups because that is a place he
# already looks, in Finder, with a name he already recognises. A backup in a
# clever location he will not remember is worse than none: it buys confidence
# without cover.
#
# ENCRYPTION: age, to a PUBLIC recipient. No secret appears in this script or
# in the launchd plist. The private identity lives at
# ~/.config/age/second-brain-backup.txt — and that file is on the disk being
# backed up, so it MUST also be in LastPass or Passwords.app. Without it every
# bundle here is an unopenable blob.
#
# ORDERING: old bundles are removed only AFTER the new one is confirmed in
# iCloud. "Confirmed" means `brctl evict` succeeded — eviction only works once
# the content is safely in the cloud. Do NOT trust `brctl status`: it reported
# `client:idle` while a 20 MB test upload was still in flight (measured
# 2026-10-19). Deleting on the strength of that would leave zero offsite copies.
set -uo pipefail

REPO="$HOME/repos/second_brain"
DEST="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents/backups"
RECIPIENT="age1l6ke0fsvpdmqx97nk638mze5rs0u7g67njfhaqxl6th9zxwejp4su8ae59"
KEEP=2
log() { echo "$(date '+%F %T') $*"; }

[ -d "$REPO/.git" ] || { log "no repo at $REPO"; exit 1; }
mkdir -p "$DEST" || exit 1

# A bundle of a repo whose HEAD does not resolve is worthless. second_brain took
# `bad object HEAD` corruption during a Syncthing sync on 2026-10-18, so check.
git -C "$REPO" rev-parse -q --verify 'HEAD^{commit}' >/dev/null 2>&1 \
  || { log "HEAD does not resolve — refusing to bundle a broken repo"; exit 1; }

stamp=$(date +%Y-%m-%d)
out="$DEST/second_brain-$stamp.bundle.age"
tmp="$DEST/.second_brain-$stamp.partial"   # same volume, so the rename is atomic
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work" "$tmp"' EXIT

log "bundling $REPO"
git -C "$REPO" bundle create "$work/b.bundle" --all 2>/dev/null \
  || { log "bundle create failed"; exit 1; }
git -C "$REPO" bundle verify "$work/b.bundle" >/dev/null 2>&1 \
  || { log "bundle failed verification — not uploading"; exit 1; }
log "bundled $(du -h "$work/b.bundle" | cut -f1)"

log "encrypting to $RECIPIENT"
age -r "$RECIPIENT" -o "$tmp" "$work/b.bundle" || { log "encrypt failed"; exit 1; }
rm -rf "$work"
mv -f "$tmp" "$out" || { log "could not place $out"; exit 1; }
log "placed $(du -h "$out" | cut -f1) at ${out/#$HOME/\~}"

# Wait for iCloud to actually hold it. Up to ~2h: this can be several GB.
log "waiting for iCloud (evict succeeds only once uploaded)"
synced=0
for _ in $(seq 1 240); do
  if brctl evict "$out" >/dev/null 2>&1; then synced=1; break; fi
  sleep 30
done
if [ "$synced" -ne 1 ]; then
  log "NOT confirmed in iCloud after 2h — keeping every existing bundle"
  exit 1
fi
log "confirmed in iCloud; local copy evicted, so it costs no disk here"

# Only now is it safe to remove older copies — including the unencrypted ones
# that predate this script.
removed=0
for f in "$DEST"/second_brain-*.bundle; do
  [ -e "$f" ] || continue
  rm -f "$f" && { log "removed unencrypted $(basename "$f")"; removed=$((removed+1)); }
done
ls -1t "$DEST"/second_brain-*.bundle.age 2>/dev/null | tail -n +$((KEEP+1)) | while IFS= read -r f; do
  rm -f "$f" && log "pruned $(basename "$f")"
done
log "done (kept newest $KEEP encrypted, removed $removed unencrypted)"
