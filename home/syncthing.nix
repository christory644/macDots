{ config, ... }:

# Syncthing — peer-to-peer continuity for coding-agent state across machines.
#
# Goal: don't "start over" with the agents on a new Mac. The high-value data is
# the agent MEMORIES (<1 MB total across all configs) — what the agents learned
# about you and your projects; conversations come along as a bonus. Syncthing
# syncs these folders directly between your Macs: peer-to-peer, encrypted in
# transit, NO cloud / NO third party (FileVault covers data at rest).
#
# Pairing the Mac Studio (later): bring it up with this same config, open each
# machine's Syncthing UI (http://127.0.0.1:8384), exchange device IDs, add the
# Studio under `devices` below + to each folder's `devices` list, rebuild. Then
# everything flows over once.
#
# .stignore (below) drops regenerable caches/logs/live sqlite DBs and per-machine
# auth (re-auth per machine) while KEEPING projects/ (memories + conversations),
# settings, and skills. It's a sensible first cut — tighten/loosen after watching
# what actually syncs.

let
  home = config.home.homeDirectory;

  claudeIgnore = ''
    // regenerable caches, logs, local backups
    cache
    paste-cache
    *-cache.json
    telemetry
    debug
    backups
    *.log
    // live databases — never sync an open DB
    *.sqlite
    *.sqlite-*
    // per-machine daemon + auth (re-auth on each machine)
    daemon
    .credentials.json
  '';

  codexIgnore = ''
    *.log
    *.sqlite
    *.sqlite-*
    computer-use
    vendor_imports
    cache
    .credentials.json
  '';

  # repos/ carries ~150 git working trees. Keep .git + source; drop everything
  # rebuildable so Syncthing isn't indexing/transferring hundreds of thousands of
  # node_modules files. (~46G on disk drops to a fraction with these excluded.)
  reposIgnore = ''
    node_modules
    target
    dist
    build
    .next
    .venv
    __pycache__
    .pytest_cache
    result
    *.log
    .DS_Store
  '';

  folder = sub: {
    path = "${home}/${sub}";
    devices = [ ]; # add "studio" here once the Mac Studio is paired
  };
in
{
  services.syncthing = {
    enable = true;
    settings = {
      options.urAccepted = -1; # decline anonymous usage reporting
      devices = {
        # studio.id = "XXXXXXX-XXXXXXX-...";  # from the Studio's Syncthing UI
      };
      folders = {
        # ── Permanent: coding-agent continuity (memories + conversations) ──
        "claude" = folder ".claude";
        "claude-personal" = folder ".claude-personal";
        "claude-work" = folder ".claude-work";
        "codex" = folder ".codex";
        "codex-personal" = folder ".codex-personal";
        "codex-work" = folder ".codex-work";

        # ── Migration seed: one-time transfer to the new MacBook ───────────
        # This machine is being retired, so these carry non-reproducible user
        # data over Syncthing once, then can be removed in a single commit.
        # (Everything ephemeral/rebuildable is deliberately NOT here — it comes
        # fresh from bootstrap: toolchains, caches, node_modules, model downloads.)
        "downloads" = folder "Downloads";
        "documents" = folder "Documents";
        "pictures" = folder "Pictures";
        "movies" = folder "Movies";
        "music" = folder "Music";
        "screenshots" = folder "Screenshots"; # macOS screencapture location
        "repos" = folder "repos";
      };
    };
  };

  home.file = {
    ".claude/.stignore".text = claudeIgnore;
    ".claude-personal/.stignore".text = claudeIgnore;
    ".claude-work/.stignore".text = claudeIgnore;
    ".codex/.stignore".text = codexIgnore;
    ".codex-personal/.stignore".text = codexIgnore;
    ".codex-work/.stignore".text = codexIgnore;
    "repos/.stignore".text = reposIgnore;
  };
}
