{ config, ... }:

# open-design daemon — his local app in ~/repos/open-design, started at login.
#
# On the old Mac this was a hand-written ~/Library/LaunchAgents plist, created
# once and recorded nowhere: not in the flake, not in any synced folder, and
# invisible to `defaults export`. A clean bootstrap therefore recreated the
# repo (git carries it) but nothing that ran it, and the failure is silent —
# the app simply never starts and there is no error to notice.
#
# Declared here so it survives this machine. The script itself lives in the
# repo, so there is nothing to vendor; the agent only needs to point at it.

let
  home = config.home.homeDirectory;
  script = "${home}/repos/open-design/scripts/od-daemon-7456.sh";
in
{
  launchd.agents.open-design-daemon = {
    enable = true;
    config = {
      ProgramArguments = [ script ];
      RunAtLoad = true;
      ProcessType = "Background";
      # The old Mac logged to /tmp, which macOS prunes. Keep it with the
      # other agent logs so a daemon that dies at login leaves evidence.
      StandardOutPath = "${home}/Library/Logs/open-design-daemon.log";
      StandardErrorPath = "${home}/Library/Logs/open-design-daemon.log";
    };
  };
}
