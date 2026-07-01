# New-MacBook migration readiness — design

**Date:** 2026-06-30
**Goal:** (1) Fix the broken `rebuild`, and (2) make this repo ready to stand up a
brand-new MacBook as the daily driver, retiring this one.

## Context / decisions

- **Old Mac fate:** retired / wiped. Syncthing is therefore a *one-time seed*, not
  long-term continuity — pair, let folders flow once, then unpair before wipe.
- **Migration strategy:** clean bootstrap. Everything reproducible comes from the
  repo via `scripts/bootstrap.sh`. Personal data + repo working state are carried
  over Syncthing (the mechanism already in the repo), not rsync.
- **Guiding rule (user):** *"if it's ephemeral or rebuildable, I don't care about
  it."* Only non-reproducible user data is carried; all regenerable caches,
  `node_modules`, toolchain dirs, model downloads, etc. are skipped.
- **Hostname:** hardcoded `macbook` throughout the flake. nix-darwin will *rename*
  the new machine to `macbook` on first switch — no per-machine config needed.

## Root cause of the broken rebuild (fixed)

`home/default.nix` imports `./headroom.nix`, but `home/headroom.nix` was untracked
by git. Nix flakes only evaluate git-tracked files, so eval failed with
*"Path 'home/headroom.nix' … is not tracked by Git."* Fix: `git add` the file
(also staged `scripts/verify-secrets.sh`). Build now green (`exit 0`).

## Part 1 — Fixes to land on this Mac

1. **Rebuild fix** (done): stage `home/headroom.nix` + `scripts/verify-secrets.sh`.
2. **Gate the headroom proxy in `home/shell/zsh.nix`.** The `claude-personal` alias
   currently hard-routes through `http://localhost:8787`, but the headroom venv is
   not installed and nothing listens on that port — so personal Claude is broken.
   Comment out `ANTHROPIC_BASE_URL` + `ANTHROPIC_MODEL` in the alias so personal
   Claude runs direct (like `claude-work`). Keep the vars in a comment as a
   ready-to-flip draft; `home/headroom.nix` stays as-is (documented, `enable = true`
   but harmless — the launchd script sleeps/retries when the venv is absent).

## Part 2 — Extend `home/syncthing.nix`

Committed to the repo, so the new Mac inherits the folder definitions on bootstrap;
pairing is then just a device-ID exchange.

Add a clearly-marked **"migration seed"** block of folders (all `devices = []`
until paired):

| Folder | Path | Notes |
|--------|------|-------|
| `downloads`  | `~/Downloads`   | |
| `documents`  | `~/Documents`   | |
| `pictures`   | `~/Pictures`    | media — larger initial transfer |
| `movies`     | `~/Movies`      | media |
| `music`      | `~/Music`       | media |
| `screenshots`| `~/Screenshots` | confirmed capture location |
| `repos`      | `~/repos`       | heavy `.stignore` (below) |

`repos` `.stignore` (keep `.git` + source, drop rebuildable churn):

```
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
```

**Explicitly not synced:** `Desktop` (not selected); `.config`, `.ssh` (nix-managed
/ bootstrap-regenerated); all regenerable dotdirs (`.cargo`, `.rustup`, `.npm`,
`.m2`, `.gradle`, `.ollama` models, `.cache`). Agent-state folders (`.claude*`,
`.codex*`) stay in their existing permanent block.

Post-migration, the "migration seed" block can be deleted in one commit (old Mac
is retired), leaving only agent-state continuity for the future Mac Studio.

## Part 3 — Migration runbook (`docs/migration.md`)

A durable checklist committed to the repo.

**Old Mac — pre-flight (before touching the new Mac):**
1. Commit + push every repo you can (`macDots` first).
2. **`scripts/verify-secrets.sh`** — *blocking gate.* Confirms you still know the
   age passphrase and the encrypted keys match `~/.ssh`. If it fails, fix before
   wiping — otherwise the new Mac can't decrypt SSH keys.
3. Confirm `.zshenv_secrets`: currently absent, so no API-key file to carry. If you
   later add one, it is gitignored *and* not in age secrets — carry it manually.
4. `rebuild` to activate Syncthing with the new folder set. Note this Mac's
   Syncthing device ID (`127.0.0.1:8384`).

**New Mac:**
5. `curl -fsSL https://raw.githubusercontent.com/christory644/macDots/main/scripts/bootstrap.sh | bash`
   → Nix/Lix, apps, dotfiles, SSH keys decrypted, remote switched to SSH, repos
   re-cloned fresh from manifests.
6. Pair Syncthing: open both UIs, exchange device IDs, add each machine under
   `devices` and to each folder, `rebuild` both. Folders flow over (agent state,
   personal data, repo source). Media takes longest.
7. Re-auth (rebuildable, intentionally not synced): `gcloud auth login` +
   `gcloud auth application-default login`, `gh auth login`, `mise use -g node@24`,
   `rustup default stable`. Optional: install the headroom venv and flip the proxy
   vars back on if you want to trial it.
8. Verify: `rebuild` clean; `claude-work` / `claude-personal` connect; Claude/Codex
   memories present under `~/.claude*` / `~/.codex*`.
9. Once satisfied → unpair Syncthing on both → wipe old Mac.

## Out of scope

- macOS Migration Assistant (rejected — would fight nix-darwin with a non-nix
  Homebrew / stale dotfiles).
- Long-term continuous sync of personal data / repos (old Mac is retired; the seed
  block is removable afterward).
- App-specific `~/Library` state (per-machine, rebuildable, or re-auth).
