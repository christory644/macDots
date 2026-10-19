#!/usr/bin/env bash
# Run this ON THE OLD MAC (user `christopherstory`), where the login keychain
# unlocks automatically at login — so no password puzzle.
#
# Why this exists: nine Vesperance credentials and a handful of service tokens
# were written into the old Mac's login keychain by agents using
# `security add-generic-password`. Those items are local, not synchronizable,
# so iCloud Keychain never carried them and the new Mac has none of them. The
# copied `old-mac-login.keychain-db` is useless without the old account's
# password, which no longer works. This copies the items into a FRESH keychain
# whose password you choose now, dropped in a synced folder.
#
# Note: `security add-generic-password -w` puts the secret in argv, briefly
# visible to `ps` on this machine. That is the only interface the tool offers
# short of 20 interactive prompts; it is local and momentary.
#
# Expect GUI password dialogs partway through: items created by an APP (rather
# than by /usr/bin/security) do not trust /usr/bin/security, so each one raises
# "security wants to use the login keychain" and blocks until answered. Items
# the agents stashed — the ones we actually came for — copy silently. Denying a
# dialog is safe; that item is just skipped.
#
# Usage: carry-keychain-items.sh [/path/to/output.keychain-db]
set -euo pipefail

OUT="${1:-$HOME/repos/.migration-carry/vesperance-carry.keychain-db}"
mkdir -p "$(dirname "$OUT")"

[ -e "$OUT" ] && { echo "refusing to overwrite $OUT"; exit 1; }

printf 'Password for the NEW carry keychain (you will type this on the new Mac): '
read -rs NEWPW; echo
[ -n "$NEWPW" ] || { echo "empty password, aborting"; exit 1; }

security create-keychain -p "$NEWPW" "$OUT"
security unlock-keychain -p "$NEWPW" "$OUT"
# don't let it relock mid-run
security set-keychain-settings "$OUT"

# Everything the new Mac is missing, minus items that are worthless to move:
# per-app "Safe Storage" encryption keys regenerate, and the com.apple.*
# entries are machine-local system state.
copied=0; failed=0
while IFS=$'\t' read -r svc acct; do
  [ -n "$svc" ] || continue
  case "$svc" in
    *"Safe Storage"*|com.apple.*|AirPlay*|FMFDStoreController) continue ;;
  esac
  # Print BEFORE reading. Items an app created (rather than /usr/bin/security)
  # raise a GUI "security wants to use the login keychain" dialog, and the read
  # blocks until it is answered — so without this line the script looks hung on
  # an unnamed item. Deny is fine for anything you don't need; it just lands in
  # the failed count. stderr is deliberately NOT suppressed here.
  printf '  reading: %s (%s) ... ' "$svc" "$acct"
  if pw=$(security find-generic-password -s "$svc" -a "$acct" -w); then
    if security add-generic-password -s "$svc" -a "$acct" -w "$pw" -U "$OUT" 2>/dev/null; then
      copied=$((copied+1)); echo "copied"
    else
      failed=$((failed+1)); echo "FAILED to write"
    fi
    unset pw
  else
    failed=$((failed+1)); echo "skipped (denied or unreadable)"
  fi
done < <(
  security dump-keychain "$HOME/Library/Keychains/login.keychain-db" 2>/dev/null \
  | python3 -c '
import sys, re, binascii
cur = {}
def flush():
    if cur.get("class") == "genp":
        def dec(s):
            m = re.match(r"^0x([0-9A-F]+)", s or "")
            if not m: return s
            try: return binascii.unhexlify(m.group(1)).decode("utf-8")
            except Exception: return s
        svc, acct = dec(cur.get("svce", "")), cur.get("acct", "")
        if svc: print(f"{svc}\t{acct}")
for line in sys.stdin:
    if line.startswith("class:"):
        flush(); cur = {"class": line.split(chr(34))[1] if chr(34) in line else ""}
    else:
        m = re.match(r"\s+(?:\"(\w{4})\"|(0x[0-9A-F]{8}))\s*<blob>=(.*)", line)
        if m:
            k = m.group(1) or m.group(2); v = m.group(3).strip()
            if v.startswith(chr(34)) and v.endswith(chr(34)): v = v[1:-1]
            cur[k] = v
flush()
'
)

security lock-keychain "$OUT"
echo
echo "copied: $copied   failed: $failed"
echo "wrote: $OUT"
echo
echo "It is in a Syncthing-synced folder, so it will appear on the new Mac."
echo "There, add it with:  security list-keychains -d user -s \\"
echo "    ~/Library/Keychains/login.keychain-db \"\$HOME/repos/.migration-carry/$(basename "$OUT")\""
echo "and unlock it with the password you just set."
