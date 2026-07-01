{ lib, ... }:

# Disable Universal Control so the pointer/keyboard don't cross to a nearby Mac
# signed into the same Apple ID. This is a per-user ByHost preference (verified
# 2026-07-01), so it CANNOT go through nix-darwin's system.defaults, which writes
# the (nonexistent) global domain. home-manager activation runs as the user, so
# `defaults -currentHost write` lands in the right ByHost plist
# (~/Library/Preferences/ByHost/com.apple.universalcontrol.<UUID>.plist).
# The `Disable` key is undocumented but confirmed honored on macOS 26 (Tahoe):
# after the write the cursor stopped crossing between machines, no re-login needed.
{
  home.activation.disableUniversalControl =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run /usr/bin/defaults -currentHost write com.apple.universalcontrol Disable -bool true
    '';
}
