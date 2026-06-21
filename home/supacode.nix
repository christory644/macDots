{
  lib,
  pkgs,
  ...
}:

# Supacode — native macOS coding-agent command center (git worktrees + zmx
# session persistence + libghostty terminals). Installed as a brew cask in
# hosts/macbook/homebrew.nix.
#
# Supacode's config lives in ~/.supacode/:
#   settings.json  — global prefs + per-repo overrides + repositoryRoots
#   layouts.json   — terminal pane/tab layout per repo   (volatile UI state)
#   sidebar.json   — sidebar order / nesting / pins       (volatile UI state)
# and a few items in the `app.supabit.supacode` macOS defaults domain
# (window frames, Sparkle updater) that are pure UI state.
#
# Only settings.json holds anything worth tracking, and even it is a MIX of
# declarative config (`global`) and app-owned state (`repositories`,
# `repositoryRoots`, `pinnedWorktreeIDs`) that Supacode rewrites whenever you
# add a repo or change a per-repo script in the UI. A read-only home.file
# symlink (the pattern used for Cursor in home/vscode.nix) would stop Supacode
# from persisting that state. So instead we DEEP-MERGE the `global` block we
# care about into the live file on each `rebuild`, leaving everything else for
# the app to manage. Declared keys win; app-managed keys are preserved.
#
# Terminal appearance/keybinds are NOT here — Supacode embeds libghostty and
# reads ~/.config/ghostty/config, which is already managed by
# home/terminal/ghostty.nix. So the terminal half is declarative already.
#
# NOTE: quit Supacode before `rebuild` (or relaunch after) — it caches settings
# in memory and may rewrite the file on quit, masking a merge until next launch.

let
  # ── Declarative global settings ──────────────────────────────────────────
  # These override whatever is in the live file. Everything here is a
  # considered default for a "many agents across many repos" workflow; edit
  # freely. The genuinely opinionated ones are flagged.
  global = {
    # Privacy — off, matching the local/sovereign posture of this setup.
    analyticsEnabled = false; # opinionated: disables PostHog telemetry
    crashReportsEnabled = false; # opinionated

    # Notifications — ON, because with many concurrent agents you need to know
    # when one finishes a turn or is waiting on input without babysitting tabs.
    systemNotificationsEnabled = true; # opinionated: was false by default
    inAppNotificationsEnabled = true;
    richAgentNotificationsEnabled = true;
    notificationSoundEnabled = true;
    agentPresenceBadgesEnabled = true;
    moveNotifiedWorktreeToTop = true; # surfaces the agent that just pinged you

    # Worktree creation — copy untracked files (.env, .envrc, local configs)
    # into each new worktree so direnv/nix-direnv and agents have a working
    # environment immediately. Ignored files (build caches, node_modules) are
    # left out to keep creation fast.
    copyUntrackedOnWorktreeCreate = true; # opinionated: was false
    copyIgnoredOnWorktreeCreate = false;
    fetchOriginBeforeWorktreeCreation = true;
    deleteBranchOnDeleteWorktree = true; # tidy branches at scale
    promptForWorktreeCreation = true;

    # Auto-cleanup: archived worktrees (and ones Supacode merely discovered) are
    # swept after this many days — directory + branch removed. Only ARCHIVED
    # worktrees are touched, never active ones. Set to keep stale agent
    # leftovers from piling up; bump/lower to taste, 0 would delete immediately.
    autoDeleteArchivedWorktreesAfterDays = 14; # opinionated: was unset (off)

    # Sessions — keep agent shells alive across app restarts (zmx persistence).
    terminateSessionsOnQuit = false;

    # Agents / editor / GitHub
    autoUpdateAgentIntegrationsEnabled = true;
    automatedActionPolicy = "cliOnly"; # only let CLI agents take automated actions
    defaultEditorID = "auto";
    githubIntegrationEnabled = true;
    pullRequestMergeStrategy = "merge"; # or "squash" / "rebase"

    # Appearance — let Supacode sync the ghostty theme to the app theme.
    appearanceMode = "dark";
    terminalThemeSyncEnabled = true;

    # Updates — check, but don't silently download (you rebuild via nix/brew).
    updateChannel = "stable";
    updatesAutomaticallyCheckForUpdates = true;
    updatesAutomaticallyDownloadUpdates = false;

    # To make new worktrees self-setup, prefer a repo-local `.envrc` (direnv is
    # already enabled) carried in by copyUntrackedOnWorktreeCreate above, rather
    # than per-repo setup scripts. If you do want per-repo lifecycle hooks
    # (setupScript/runScript/archiveScript), they can be merged the same way —
    # see the commented `repositories` example at the bottom of this file.
  };

  desired = pkgs.writeText "supacode-settings.json" (builtins.toJSON {
    inherit global;
    # Example: also pin a reproducible repo list and per-repo setup hook.
    # repositoryRoots = [ "/Users/christopherstory/repos/macDots/" ];
    # repositories."/Users/christopherstory/repos/macDots/".setupScript = "direnv allow";
  });
in
{
  home.activation.supacodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SETTINGS="$HOME/.supacode/settings.json"
    run mkdir -p "$HOME/.supacode"
    if [ -f "$SETTINGS" ]; then
      # Deep-merge (recursive `*`): declared keys win, app-managed keys kept.
      if ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$SETTINGS" ${desired} > "$SETTINGS.hm-tmp" 2>/dev/null; then
        run mv "$SETTINGS.hm-tmp" "$SETTINGS"
      else
        verboseEcho "supacode: settings.json unparseable, leaving it untouched"
        run rm -f "$SETTINGS.hm-tmp"
      fi
    else
      run cp ${desired} "$SETTINGS"
    fi
  '';
}
