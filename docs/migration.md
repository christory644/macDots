# Migrating to a new Mac

The durable checklist for standing up a new Mac and retiring the old one.

**Strategy:** clean bootstrap — everything reproducible comes from this repo. Only
non-reproducible *user data* (agent memories, personal folders, repo working trees)
is carried over Syncthing. Everything ephemeral or rebuildable (toolchains, caches,
`node_modules`, model downloads, credentials) comes fresh on the new machine.

The hostname is hardcoded `macbook` throughout the flake — nix-darwin renames the
new machine to `macbook` on first switch, so there's no per-machine config to touch.

---

## 1. Old Mac — pre-flight (do this BEFORE touching the new Mac)

1. **Push all committable work.** For every repo with changes you care about:
   ```bash
   git add -A && git commit -m "wip: pre-migration" && git push
   ```
   Do `macDots` first. Uncommitted/untracked files (local `.env`, stashes) still
   travel via Syncthing in step 4, but pushing is the safety net.

2. **Verify you can still decrypt your secrets — BLOCKING.**
   ```bash
   ./scripts/verify-secrets.sh
   ```
   This confirms you remember the age passphrase and that the encrypted SSH keys
   match `~/.ssh`. **If it fails, fix it before wiping this machine** — otherwise
   the new Mac cannot decrypt your SSH keys during bootstrap. To rotate:
   `./scripts/encrypt-keys.sh && git add secrets/ && git commit && git push`.

3. **API-key env file.** `~/repos/macDots/.zshenv_secrets` is gitignored *and* not in
   `secrets/`, so nothing carries it automatically. It's currently absent (no such
   secrets). If you add one before migrating, copy it to the new Mac by hand.

4. **Activate Syncthing with the full folder set.**
   ```bash
   rebuild
   ```
   Then open the Syncthing UI at <http://127.0.0.1:8384> and note this machine's
   **Device ID** (Actions → Show ID).

## 2. New Mac — bootstrap

5. Run the one-liner:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/christory644/macDots/main/scripts/bootstrap.sh | bash
   ```
   Installs Xcode CLT → clones macDots (HTTPS) → Nix via Lix → decrypts SSH keys
   (prompts for passphrase) → switches remote to SSH → builds + activates
   nix-darwin → rustup → clones all repos fresh from the manifests.

6. Open a new terminal and confirm the shell config is live: `rebuild` runs clean.

## 3. Pair Syncthing and let data flow

7. Open the Syncthing UI on **both** machines (<http://127.0.0.1:8384>):
   - On each, add the other as a **Remote Device** (paste the Device ID from step 4
     / the new Mac's own ID).
   - The declarative config already defines the same folders on both machines. As
     each folder is offered, **Accept / Share** it on the receiving side.
   - Folders that flow: agent state (`.claude*`, `.codex*`), `Downloads`,
     `Documents`, `Pictures`, `Movies`, `Music`, `Screenshots`, and `repos`
     (source + `.git` only — build artifacts are ignored). Media and 148 repos take
     the longest; let it settle.

   > Tip: the new Mac is a clean target, so it's safe to let it be receive/send.
   > If you want to be extra careful, set the new Mac's folders to **Receive Only**
   > during the seed so nothing accidentally flows back to the old machine.

## 4. Re-auth the rebuildable bits (intentionally not synced)

8. ```bash
   gcloud auth login
   gcloud auth application-default login
   gh auth login
   mise use -g node@24
   rustup default stable
   ```
   Optional: trial Headroom — install the venv (see `home/headroom.nix`), set
   `launchd.agents.headroom.enable = true`, restore the proxy env vars on
   `claude-personal` in `home/shell/zsh.nix`, then `rebuild`.

## 5. Verify, then retire the old Mac

9. On the new Mac, confirm everything works:
   - `rebuild` is clean.
   - `claude-work` and `claude-personal` both connect and start.
   - Agent memories are present under `~/.claude*` / `~/.codex*`.
   - Your repos and personal folders are fully synced (check Syncthing shows
     "Up to Date" for every folder).

10. Once satisfied: **unpair Syncthing** on both machines (remove the device), then
    wipe the old Mac.

11. Optional cleanup commit: delete the "migration seed" folder block from
    `home/syncthing.nix` (the old Mac is gone), leaving only agent-state continuity
    for a future third machine (e.g. the Mac Studio).
