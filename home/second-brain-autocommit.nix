{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:

# Auto-commit the second_brain knowledge vault so thinking is captured without
# any git workflow. second_brain is a frictionless thinking/capture space, not
# a codebase — staging, commit messages, and branches are friction that defeats
# the point. This launchd agent snapshots the repo on a timer (and at login),
# so the user never has to think about git there.
#
# History stays noisy-but-complete (many "auto:" commits) on purpose: capture
# beats clean history for a thinking log. If an `origin` remote is ever added,
# it also pushes (off-site backup) — currently the repo is local-only.

let
  repo = "${config.home.homeDirectory}/repos/second_brain";

  autocommit = pkgs.writeShellScript "second-brain-autocommit" ''
    export PATH="${lib.makeBinPath [ pkgs.git pkgs.coreutils pkgs.gnugrep pkgs.curl pkgs.jq ]}"
    cd "${repo}" 2>/dev/null || exit 0
    [ -d .git ] || exit 0
    # Never commit into a repo Syncthing is still delivering. Every rebuild
    # reloads this agent (RunAtLoad), so it has to refuse on its own rather
    # than rely on a manual bootout mid-seed (new Mac, 2026-10-18).
    # Every skip says why in the log, so a long gap between commits is a
    # one-line diagnosis rather than a mystery.
    skip() { echo "$(date '+%F %T') skipped: $*"; exit 0; }
    # 1. HEAD must resolve: its objects may not have arrived yet.
    git rev-parse -q --verify 'HEAD^{commit}' >/dev/null || skip "HEAD does not resolve"
    # 2. The Syncthing folder holding ~/repos (`repos` in syncthing.nix) must
    #    owe this machine nothing. .git routinely finishes before the working
    #    tree, and `git add -A` would then commit every file still in flight as
    #    a deletion; no on-disk artefact reliably shows that, the folder status
    #    does. Its need counts only mean something once a peer is connected,
    #    and RunAtLoad fires at login, when Syncthing may not have reconnected
    #    yet, so a connected peer is required too. Fails closed: no config or
    #    no API answer means no commit. Folder not configured (404, e.g. after
    #    the migration seed is torn down): proceed with no peer needed.
    st="$HOME/Library/Application Support/Syncthing/config.xml"
    [ -f "$st" ] || skip "no Syncthing config at $st"
    key=$(grep -oE '<apikey>[^<]+' "$st" | cut -d'>' -f2)
    api="http://127.0.0.1:8384/rest"
    code=$(curl -s -m 10 -o /dev/null -w '%{http_code}' -H "X-API-Key: $key" "$api/config/folders/repos")
    case "$code" in
      200)
          # A peer only has to be connected if one is actually EXPECTED: the
          # folder's device list, minus ourselves, minus any device that is
          # paused or no longer configured. Empty set means nothing to wait for.
          #
          # Requiring a live peer unconditionally — as the first version did —
          # fails exactly when it matters. Once the old Mac is paused or gone,
          # no peer ever connects again, so every run skips forever while the
          # log looks perfectly healthy.
          #
          # NOTE the jq: `has("paused") and .paused == false`, never
          # `.paused // x`. jq's // treats FALSE as empty, so the shorthand
          # reports every unpaused device as absent — failing open on precisely
          # the peers this is meant to wait for.
          me=$(curl -s -m 10 -H "X-API-Key: $key" "$api/system/status" | jq -r '.myID // empty')
          folderdevs=$(curl -s -m 10 -H "X-API-Key: $key" "$api/config/folders/repos" \
                       | jq -r --arg me "$me" '[.devices[].deviceID | select(. != $me)]')
          expected=$(curl -s -m 10 -H "X-API-Key: $key" "$api/config/devices" | jq --argjson fd "$folderdevs" '
            [ .[] | select(.deviceID as $d | $fd | index($d))
                  | select(has("paused") and .paused == false) ] | length')
          if [ "''${expected:-1}" -gt 0 ]; then
            curl -s -m 10 -H "X-API-Key: $key" "$api/system/connections" \
              | jq -e '[.connections[] | select(.connected)] | length > 0' >/dev/null \
              || skip "$expected unpaused peer(s) share this folder and none is connected"
          fi
        curl -s -m 30 -H "X-API-Key: $key" "$api/db/status?folder=repos" | jq -e '
          (.needBytes + .needFiles + .needDeletes) == 0
          and (.state | IN("syncing", "sync-preparing", "sync-waiting", "error") | not)
        ' >/dev/null || skip "Syncthing is still delivering the repos folder" ;;
      404) ;;
      *) skip "Syncthing API not answering (HTTP $code)" ;;
    esac
    # nothing changed -> nothing to do
    [ -n "$(git status --porcelain)" ] || exit 0
    git add -A
    git commit -q -m "auto: $(date '+%Y-%m-%d %H:%M:%S')" || exit 0
    # push only if an off-site backup remote exists; never fail the agent on it
    if git remote get-url origin >/dev/null 2>&1; then
      git push -q origin HEAD 2>/dev/null || true
    fi
  '';
in
{
  launchd.agents.second-brain-autocommit = {
    # ON here. This machine is the leader now; the old Mac is a dormant
    # escape hatch, so if this agent does not commit second_brain, nothing
    # does.
    #
    # Measured before deciding, because the assumption was that agents commit
    # their own work and this was only a safety net: over 90 days second_brain
    # took 35 commits, 29 of them from this agent. It writes 82% of the
    # vault's history. Dropping it would have stopped 4 commits in 5.
    #
    # The guard above decides whether it is safe to run; see the note on the
    # expected-peer set. Exactly one machine should have this enabled.
    enable = hostname == "christoryCertifyOSMacbook";
    config = {
      ProgramArguments = [ "${autocommit}" ];
      StartInterval = 900; # every 15 minutes
      RunAtLoad = true; # and once at login
      ProcessType = "Background";
      LowPriorityIO = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/second-brain-autocommit.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/second-brain-autocommit.log";
    };
  };
}
