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
    // Negations come FIRST: Syncthing applies the first matching pattern, not
    // the most specific one, so anything to keep must appear above the rule
    // that would otherwise drop it.
    //
    // `*.log` used to live in the exclude list below. It was too blunt — on
    // migration it silently dropped 75 real state files (orchestrator
    // events.log and briefs, the review queue, chief run records) purely
    // because they end in .log. Name the actual noise instead.
    !orchestrator
    !**/events.log
    // regenerable caches, logs, local backups
    cache
    paste-cache
    *-cache.json
    telemetry
    debug
    backups
    daemon.log
    *-debug.log
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
    # ai-coach churns hard enough here to destabilize fseventsd
    /ai-coach/.claude/worktrees
    /ai-coach/.scratch
    /ai-coach/coverage
  '';

  # Gas Town HQ (gt-personal/gt-work) and two scratch projects live in the HOME
  # ROOT, not ~/repos — the original layout on both machines. Nothing replicated
  # them: they sat outside every synced folder, and gt-personal/gt-work have no
  # git remotes and no commits, so git can restore nothing from them. The old
  # Mac was their only second copy, and it is being wiped.
  #
  # .dolt-data IS synced: it is content-addressed like git (not a mutable page
  # file), only ~300 KB, and it holds the actual beads issue data — excluding it
  # would back up the shell and drop the contents. The sqlite privileges DB next
  # to it is excluded, per the rule above about open databases. If a gt daemon
  # ever runs on two machines at once, revisit this.
  gtIgnore = ''
    // transient runtime state
    daemon
    logs
    events
    **/state.json
    **/*.lock
    **/*.flock
    **/locks
    **/*.pid
    **/heartbeat.json
    **/activity.json
    **/.runtime
    // worktrees and clones — recreate with `gt sling` / `gt rig add`
    **/polecats
    **/deacon/dogs
    **/mayor/rig
    **/refinery/rig
    **/crew
    // never sync an open sqlite DB
    **/.doltcfg/privileges.db
    node_modules
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
    # DISABLED 2026-10-19. The bulk migration is done — every folder reached
    # needFiles=0 — and from that point continuous bidirectional replication
    # between a machine being actively repaired and a machine being retired
    # caused more damage than it prevented: 327 .sync-conflict-* files (20 of
    # them inside .git/, conflict-copying live worktree index files), a blanket
    # *.log rule that silently dropped 75 real state files, a `git worktree
    # repair` on this Mac that propagated back and broke every worktree on the
    # other one, ~1,100 conflicts from the claude-work merge, and a project-slug
    # symlink scheme that exists only so two machines can share one folder —
    # which, pointing the wrong way, truncated tool-results. It also blocked the
    # second_brain autocommit, which refuses to run while an unpaused peer
    # exists. Remaining transfers are surgical and go over rsync/ssh instead.
    #
    # Everything below is kept deliberately. To revive for a genuine second
    # machine: set this true, put that machine's ID in `deviceIds`, rebuild on
    # both. Review the .stignore rules first — `*.log` was the costly one.
    enable = false;
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
        "claude-work" = folder ".claude-work";   # retire once its merge completes
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

        # ── Permanent: home-root working dirs ─────────────────────────────
        # Unlike the migration seed above, these stay: they are where the Gas
        # Town HQs and these two scratch projects actually live.
        "gt-personal" = folder "gt-personal";
        "gt-work" = folder "gt-work";
        "mindTheGap" = folder "mindTheGap";
        "claude-prompts" = folder "claude-prompts";
        "backfill-audit-logs" = folder "backfill-audit-logs";
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
    "gt-personal/.stignore".text = gtIgnore;
    "gt-work/.stignore".text = gtIgnore;
    # iCloud Photos carries the library; syncing a live .photoslibrary bundle
    # corrupts its internal DB. Loose images in ~/Pictures still sync.
    "Pictures/.stignore".text = ''
      Photos Library.photoslibrary
      .DS_Store
    '';
  };
}
