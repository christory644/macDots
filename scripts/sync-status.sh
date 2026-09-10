#!/usr/bin/env bash
#
# sync-status.sh — has the Syncthing migration seed actually finished?
#
# The web UI's "Up to Date" is per-folder and local-only, so it can read green
# on this machine while the peer is still sending. This checks BOTH directions
# for every folder and prints one verdict.
#
# TEARDOWN: delete along with the migration-seed folders (docs/migration.md §8).
set -uo pipefail

GUI="http://127.0.0.1:8384"
ST="$HOME/Library/Application Support/Syncthing"
API="$(grep -oE '<apikey>[^<]+' "$ST/config.xml" | cut -d'>' -f2)"
q() { curl -s -m 10 -H "X-API-Key: $API" "$GUI$1"; }

if ! q /rest/system/ping | grep -q pong; then
  echo "Syncthing isn't answering on $GUI — is the service running?" >&2
  exit 2
fi

SELF="$(scutil --get LocalHostName)"
PEER="$(q /rest/config/devices | SELF="$SELF" python3 -c '
import json, os, sys
me = os.environ["SELF"]
peers = [d["deviceID"] for d in json.load(sys.stdin) if d["name"] != me]
print(peers[0] if peers else "")')"

if [ -z "$PEER" ]; then
  echo "No peer device is configured — nothing to sync with." >&2
  exit 2
fi

CONN="$(q /rest/system/connections | PEER="$PEER" python3 -c '
import json, os, sys
print(json.load(sys.stdin)["connections"].get(os.environ["PEER"], {}).get("connected", False))')"

printf "peer connected: %s\n\n" "$CONN"
printf "%-16s %-14s %7s  %10s  %7s\n" FOLDER STATE "PEER%" "TO FETCH" "FILES"
printf -- "------------------------------------------------------------\n"

settled=1
[ "$CONN" = "True" ] || settled=0

for f in $(q /rest/config/folders | python3 -c \
    'import json,sys; print(" ".join(x["id"] for x in json.load(sys.stdin)))'); do
  line="$(q "/rest/db/status?folder=$f" | python3 -c '
import json, sys
d = json.load(sys.stdin)
need = d.get("needBytes", 0)
files = d.get("needFiles", 0) + d.get("needDeletes", 0)
print("%s %d %d" % (d.get("state", "?"), need, files))')"
  read -r state need files <<<"$line"

  # completion the PEER still owes us; 100 means it has nothing left to send
  peerpct="$(q "/rest/db/completion?folder=$f&device=$PEER" | python3 -c '
import json, sys
print("%.1f" % float(json.load(sys.stdin).get("completion", 0)))')"

  printf "%-16s %-14s %7s  %7.2f GB  %7s\n" \
    "$f" "$state" "$peerpct" "$(python3 -c "print($need/1e9)")" "$files"

  # numeric comparison — the API returns 100 as often as 100.0
  ok="$(python3 -c "print(1 if '$state'=='idle' and $need==0 and $files==0 and float('$peerpct')>=100 else 0)")"
  [ "$ok" = 1 ] || settled=0
done

echo
if [ "$settled" = 1 ]; then
  echo "==> SETTLED. Every folder is idle and neither side has anything pending."
  echo "    Safe to rely on ~/repos and to start work on the synced trees."
  exit 0   # exit code is the machine-readable answer: 0 settled, 1 still going
else
  echo "==> STILL SYNCING. Re-run this later; 'sync-preparing' on a large"
  echo "    folder means the peer is still hashing and the numbers will move."
  echo
  echo "    Note: a .claude*/.codex* folder parked just under 100% is normal"
  echo "    while an agent is running here — it writes to its own state dir"
  echo "    faster than the peer can pull. Judge those with every agent quit."
  exit 1
fi
