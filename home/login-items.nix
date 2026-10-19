{ config, ... }:

# Apps that should start at login.
#
# NOT done by adding them to System Settings → General → Login Items. That
# list is written through System Events, which needs Automation permission —
# an activation script driving it either prompts at an unhelpful moment or
# fails silently, and a login item added that way is recorded nowhere the
# flake can see. The old Mac's four login items (Drata Agent, Raycast, Google
# Drive, Maccy) were exactly that kind of undeclared state, which is why only
# Raycast survived the move: it re-registers itself on first launch.
#
# A RunAtLoad agent calling `open -a` is what a login item does anyway, and it
# is declarative, inspectable and removable. The apps will not appear in the
# Login Items list; that is cosmetic.
#
# Raycast is deliberately absent — it registers its own login item, and a
# second launcher would race it.

let
  home = config.home.homeDirectory;

  openAtLogin = app: {
    enable = true;
    config = {
      ProgramArguments = [ "/usr/bin/open" "-a" app ];
      RunAtLoad = true;
      # One-shot: open returns immediately and launchd must not restart it.
      KeepAlive = false;
      ProcessType = "Background";
      StandardOutPath = "${home}/Library/Logs/login-items.log";
      StandardErrorPath = "${home}/Library/Logs/login-items.log";
    };
  };
in
{
  launchd.agents.login-google-drive = openAtLogin "Google Drive";
  launchd.agents.login-maccy = openAtLogin "Maccy";
}
