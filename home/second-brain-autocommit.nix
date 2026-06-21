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
    export PATH="${lib.makeBinPath [ pkgs.git pkgs.coreutils ]}"
    cd "${repo}" 2>/dev/null || exit 0
    [ -d .git ] || exit 0
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
