{ config, pkgs, lib, hostname, ... }:

# The lock half of the power policy in hosts/macbook/power.nix: 15 minutes on
# AC, 5 on battery.
#
# This needs an agent rather than a declared value because macOS stores the
# screen-saver idle time as ONE global number. There is no per-power-source
# lock timer, so the only way to have it differ by source is to rewrite it when
# the source changes. `pmset` owns the sleep timers and can express per-source
# values; the lock timer sits outside that system entirely.
#
# It polls instead of subscribing: the proper route is an IOKit power-source
# notification, which needs a compiled helper. A 30-second poll that reads one
# value and almost always does nothing is not worth a binary.

let
  acIdle = 900;  # 15 min plugged in
  batIdle = 300; #  5 min on battery

  lockTimer = pkgs.writeShellScript "lock-timer-by-power" ''
    set -uo pipefail

    # First line of `pmset -g batt` is e.g. "Now drawing from 'AC Power'".
    src=$(/usr/bin/pmset -g batt 2>/dev/null | /usr/bin/head -1)
    case "$src" in
      *"AC Power"*) want=${toString acIdle} ;;
      *)            want=${toString batIdle} ;;
    esac

    # Read before writing. `defaults write` touches the file and notifies
    # observers even when the value is unchanged, so an unconditional write
    # every 30s would be 2,880 pointless notifications a day.
    cur=$(/usr/bin/defaults -currentHost read com.apple.screensaver idleTime 2>/dev/null || echo "")
    if [ "$cur" != "$want" ]; then
      /usr/bin/defaults -currentHost write com.apple.screensaver idleTime -int "$want"
      echo "$(date '+%F %T') $src -> idleTime ''${cur:-unset} to $want"
    fi
  '';
in
{
  launchd.agents.lock-timer-by-power = {
    enable = hostname == "christoryCertifyOSMacbook";
    config = {
      ProgramArguments = [ "${lockTimer}" ];
      StartInterval = 30;
      RunAtLoad = true;
      ProcessType = "Background";
      LowPriorityIO = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/lock-timer-by-power.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/lock-timer-by-power.log";
    };
  };
}
