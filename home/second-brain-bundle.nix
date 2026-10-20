{ config, pkgs, lib, hostname, ... }:

# Monthly encrypted offsite backup of second_brain.
#
# Why a bundle and not a remote: second_brain has no git remote on purpose. It
# is highly personal and should not be visible to GitHub even in a private repo.
# A single encrypted file can live in iCloud Drive without the host being able
# to read it, which is the only shape that satisfies both halves.
#
# Why iCloud Drive -> Documents -> backups: a backup somewhere clever is a
# backup he will not find. That folder is already in Finder, already named
# "backups", and already held an (unencrypted) bundle from the old Mac — which
# got there by accident, via Desktop & Documents sync, rather than by decision.
# This makes the same location deliberate and encrypted.
#
# The KEY is the weak point, not the cipher. ~/.config/age/second-brain-backup.txt
# sits on the disk being backed up; if that disk dies the key dies with it and
# every bundle is unopenable. It has to be in LastPass or Passwords.app too.
# Only the PUBLIC recipient appears in the script, so nothing secret is in the
# nix store or the plist.

let
  bundle = pkgs.writeShellScript "second-brain-bundle"
    (builtins.readFile ../scripts/second-brain-bundle.sh);
in
{
  launchd.agents.second-brain-bundle = {
    # One machine should hold this job, for the same reason only one should run
    # the autocommit: two writers producing same-named bundles into one synced
    # folder is how the August mess started.
    enable = hostname == "christoryCertifyOSMacbook";
    config = {
      ProgramArguments = [ "${bundle}" ];
      # 03:10 on the 1st. Monthly, not nightly: the repo changes slowly and each
      # run is a multi-GB upload against a metered personal iCloud quota.
      StartCalendarInterval = [{ Day = 1; Hour = 3; Minute = 10; }];
      # NOT RunAtLoad — a rebuild would otherwise fire a multi-GB upload every
      # time, which is a surprising thing for `darwin-rebuild switch` to do.
      RunAtLoad = false;
      ProcessType = "Background";
      LowPriorityIO = true;
      EnvironmentVariables = {
        # launchd gives a minimal PATH; the script needs git, age and brctl.
        PATH = "/etc/profiles/per-user/${config.home.username}/bin:"
             + "/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/second-brain-bundle.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/second-brain-bundle.log";
    };
  };
}
