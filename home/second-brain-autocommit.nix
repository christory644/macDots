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
    # 2. The Syncthing gate that used to live here is GONE, because Syncthing
    #    is gone (2026-10-19). It existed to stop `git add -A` committing
    #    in-flight files as deletions while a peer was still delivering the
    #    repos folder — a real hazard while two machines shared it.
    #
    #    Leaving it in place after the service stopped would have been worse
    #    than useless: the config.xml still exists, so the gate passed its first
    #    check, then got HTTP 000 from the dead API and took the fail-closed
    #    branch. Every run would have skipped forever while the log looked
    #    perfectly healthy — the exact failure the comment below the old gate
    #    warned about, reintroduced by a different route.
    #
    #    This machine is now the only writer of second_brain, so there is
    #    nothing to race. If Syncthing is ever revived for a genuine second
    #    machine, restore the gate from git history (commit d597e5e) before
    #    re-enabling this agent.

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
