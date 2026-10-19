{
  config,
  lib,
  pkgs,
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
        curl -s -m 10 -H "X-API-Key: $key" "$api/system/connections" \
          | jq -e '[.connections[] | select(.connected)] | length > 0' >/dev/null \
          || skip "no Syncthing peer connected, so the repos folder's state is unknown"
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
    enable = true;
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
