{ ... }:

# Power and lock policy.
#
# THE POLICY
#   AC                                   display never off, never sleeps, lock at 15 min
#   Battery, lid open                    display off at 30 min, never sleeps, lock at 5 min
#   Battery, clamshell + external display  same as lid open (macOS clamshell mode)
#   Battery, lid closed, nothing attached  sleeps — the only case that does
#
# Deliberately NOT nix-darwin's `power.sleep.*`: those options map to
# `pmset -a`, one value across every power source, and this policy differs by
# source. `pmset -c` / `-b` is the only way to express it.
#
# Locking is driven by the SCREEN SAVER, not by display sleep. That separation
# is what lets the AC case keep the panel lit while still being locked: the
# saver starts at 15 min and demands a password, and `displaysleep 0` means the
# display behind it never powers down. Tying the lock to display sleep instead
# would make "never turn the screen off" and "lock after 15 minutes" mutually
# exclusive.
#
# The screen-saver idle time itself is a single global value — macOS has no
# per-power-source lock timer — so the 15-vs-5 split cannot live here. See
# home/lock-policy.nix for the agent that rewrites it when the power source
# changes.
#
# LID CLOSE IS NOT CONFIGURABLE. There is no pmset key for it and no power
# assertion that prevents it — `caffeinate` of any flavour will not keep a
# closed, unattached laptop awake. So "battery + closed + nothing connected
# sleeps" is not something set here; it is simply what macOS does, and it
# happens to be the desired behaviour.
#
# MDM: every value below is an ordinary preference, not a configuration
# profile. Once this machine is enrolled, a profile can override all of it and
# will win silently. Re-check with `pmset -g custom` after enrolment rather
# than assuming these still hold.

{
  system.defaults.screensaver = {
    askForPassword = true;
    askForPasswordDelay = 0; # lock the instant the saver starts
  };

  system.activationScripts.postActivation.text = ''
    # 0 means never. Applied per power source, which `power.sleep.*` cannot do.
    #
    # `sleep 0` on BATTERY is deliberate and is the costly half of this policy:
    # an open laptop left on battery will run until flat rather than sleeping.
    # The lid is the backstop — closing it still sleeps, because lid close is
    # not governed by these timers.
    echo "power: applying per-source sleep policy" >&2
    /usr/bin/pmset -c displaysleep 0  sleep 0 disksleep 0
    /usr/bin/pmset -b displaysleep 30 sleep 0 disksleep 10
  '';
}
