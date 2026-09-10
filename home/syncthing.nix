{ config, hostname, ... }:

# Syncthing — peer-to-peer continuity for coding-agent state across machines.
#
# Goal: don't "start over" with the agents on a new Mac. The high-value data is
# the agent MEMORIES (<1 MB total across all configs) — what the agents learned
# about you and your projects; conversations come along as a bonus. Syncthing
# syncs these folders directly between your Macs: peer-to-peer, encrypted in
# transit, NO cloud / NO third party (FileVault covers data at rest).
#
# Pairing the new MacBook: bring it up with this same config, open each
# machine's Syncthing UI (http://127.0.0.1:8384), exchange device IDs, set the
# other machine's ID under `devices` below and add its name to `peers`, rebuild
# on both. Then everything flows over once.
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

  # Device IDs for both machines (Actions → Show ID in each Syncthing UI).
  # TEARDOWN: drop the `macbook` entry once that Mac is wiped.
  deviceIds = {
    macbook = "2YSVEFS-BSHUPQU-J2HVVUL-O6FZ3U7-ASXFOZ4-O467HKR-LRBLHST-VD4FUAH";
    christoryCertifyOSMacbook = "R5FO54I-QKZI3UE-VT2PRYV-KHFESHA-EP2DNCI-LJW2VGO-QWEVXHA-EYLDHQY";
  };

  # One flake builds both machines, so the peer must be derived, never hardcoded:
  # each host pairs with the OTHER one. A literal would point the old Mac at itself.
  peers = builtins.filter (n: n != hostname) (builtins.attrNames deviceIds);

  folder = sub: {
    path = "${home}/${sub}";
    devices = peers;
  };
in
{
  services.syncthing = {
    enable = true;
    settings = {
      options.urAccepted = -1; # decline anonymous usage reporting
      # Only the peer is declared — a machine never lists itself as a device.
      devices = builtins.listToAttrs (
        map (n: { name = n; value = { id = deviceIds.${n}; }; }) peers
      );
      folders = {
        # ── Permanent: coding-agent continuity (memories + conversations) ──
        "claude" = folder ".claude";
        "claude-personal" = folder ".claude-personal";
        "claude-work" = folder ".claude-work";
        "claude-work-sub" = folder ".claude-work-sub";
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
    ".claude-work-sub/.stignore".text = claudeIgnore;
    ".codex/.stignore".text = codexIgnore;
    ".codex-personal/.stignore".text = codexIgnore;
    ".codex-work/.stignore".text = codexIgnore;
    "repos/.stignore".text = reposIgnore;
    # iCloud Photos carries the library; syncing a live .photoslibrary bundle
    # corrupts its internal DB. Loose images in ~/Pictures still sync.
    "Pictures/.stignore".text = ''
      Photos Library.photoslibrary
      .DS_Store
    '';
  };
}
