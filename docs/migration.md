# Migrating to the new MacBook

The executable runbook for standing up the new work MacBook (256GB) and retiring
this one. Decisions baked in (interview 2026-08-30): coexistence then targeted
wipe; hybrid keychain (iCloud + archive copy); Arc + Chrome profiles move;
iCloud Photos carries the photo library; local DBs are recreated, not dumped;
only `.claude*`/`.codex*` agent state carries over.

**Strategy:** clean bootstrap — everything reproducible comes from this repo.
Non-reproducible *user data* (agent memories, personal folders, repo working
trees) carries over Syncthing; a handful of things Syncthing doesn't cover
(browser profiles, keychain archive) move once by hand (§4). Everything
ephemeral or rebuildable (toolchains, caches, `node_modules`, model downloads,
credentials) comes fresh.

The flake defines **two hosts**: `macbook` (this old M3/18GB machine — marked
TEARDOWN) and `christoryCertifyOSMacbook` (the keeper). `bootstrap.sh` selects
via `BOOTSTRAP_HOST` or a matching LocalHostName and refuses to guess.
Per-host settings (hostname, `rebuild` alias, Ollama tuning) follow the
hostname automatically.

---

## 1. Old Mac — pre-flight (do BEFORE touching the new Mac)

1. **Repo hygiene is a standing rule:** everything in `~/repos` has a git
   remote, is in a manifest (`repos.yml` / `repos-private.yml`), or is
   deliberately disposable. (Triage completed 2026-08-30: 14 repos got new
   private remotes; junk was deleted; `second_brain` is the one exception —
   its >100MB conversation archives don't fit GitHub, so it lives in Syncthing
   plus a bundle backup, next step.) If you created new strays since, fix them
   now.

2. **Push all committable work.** For every repo with changes you care about:
   ```bash
   git add -A && git commit -m "wip: pre-migration" && git push
   ```
   Do `macDots` first. Uncommitted/untracked files (local `.env`, stashes)
   still travel via Syncthing, but pushing is the safety net.

3. **Refresh the second_brain bundle** (its only off-repo backup):
   ```bash
   git -C ~/repos/second_brain bundle create \
     ~/Documents/backups/second_brain-$(date +%F).bundle --all
   ```

4. **Verify you can still decrypt your secrets — BLOCKING.**
   ```bash
   ./scripts/verify-secrets.sh
   ```
   Confirms you remember the age passphrase and the encrypted SSH keys match
   `~/.ssh`. **If it fails, fix it before wiping this machine** — otherwise the
   new Mac cannot decrypt SSH keys during bootstrap. To rotate:
   `./scripts/encrypt-keys.sh && git add secrets/ && git commit && git push`.
   Re-run `encrypt-keys.sh` any time `repos-private.yml` changes.

5. **API-key env file.** `~/repos/macDots/.zshenv_secrets` is gitignored *and*
   not in `secrets/`. If it exists, copy it by hand in §4.

6. **Apple ID services are the transport for photos + passwords.** Confirm on
   this machine (both verified on 2026-08-30): iCloud Photos ON, iCloud
   Keychain ON.

7. **Note this machine's Syncthing Device ID:** <http://127.0.0.1:8384> →
   Actions → Show ID.

## 2. New Mac — bootstrap

8. **Confirm identity assumptions** on first boot: the local account username
   should be `christory` (the flake hard-codes it). If MDM named the machine
   something else, that's fine — nix-darwin renames it to
   `christoryCertifyOSMacbook` on first switch.

9. Run the one-liner (host selection is explicit — do not let it guess):
   ```bash
   curl -fsSL https://raw.githubusercontent.com/christory644/macDots/main/scripts/bootstrap.sh \
     | BOOTSTRAP_HOST=christoryCertifyOSMacbook bash
   ```
   Installs Xcode CLT → clones macDots (HTTPS) → Nix via Lix → decrypts SSH
   keys + private repo manifest (age passphrase prompt) → switches remote to
   SSH → builds + activates nix-darwin for `christoryCertifyOSMacbook` →
   rustup → clones all repos fresh from the manifests.

10. Open a new terminal and confirm the shell config is live: `rebuild` runs
    clean (the alias already targets the right host).

## 3. Pair Syncthing and let data flow

11. On **both** machines open <http://127.0.0.1:8384> and add the other as a
    Remote Device (Device IDs from step 7 / the new Mac's UI). Then make it
    declarative in `home/syncthing.nix`:
    - set `christoryCertifyOSMacbook.id = "…"` under `devices`
      (on the old machine's checkout, the old Mac's ID on the new one),
    - set `peers = [ "<other machine's device name>" ]`,
    - `rebuild` on both.
12. As each folder is offered, **Accept / Share** on the receiving side.
    Folders that flow: agent state (`.claude*`, `.codex*`), `Downloads`,
    `Documents` (includes `backups/` and `work-scratch/`), `Pictures` (loose
    images only — the Photos Library bundle is excluded; iCloud carries it),
    `Movies`, `Music`, `Screenshots`, and `repos` (source + `.git`; build
    artifacts ignored). Media and ~125 repos take hours; let it settle.

    > Safety: set the new Mac's folders to **Receive Only** during the seed so
    > nothing accidentally flows back. Flip to Send & Receive once settled.
    > Replication is not backup — a deletion propagates to both machines.

## 4. One-shot copies Syncthing doesn't cover

Do these with the relevant apps **quit on both machines**. Easiest transport:
enable Remote Login on the old Mac (System Settings → General → Sharing), then
pull from the new Mac:

13. **Arc** (spaces, pinned tabs, profiles are local-only). Install Arc, launch
    once, quit, then:
    ```bash
    rsync -a --delete --exclude 'Cache*' --exclude 'GPUCache' \
      'christopherstory@macbook.local:Library/Application Support/Arc/' \
      ~/Library/Application\ Support/Arc/
    ```
14. **Chrome** (open tabs + extension local state; the rest syncs via Google):
    ```bash
    rsync -a --delete --exclude 'Cache*' \
      'christopherstory@macbook.local:Library/Application Support/Google/Chrome/' \
      ~/Library/Application\ Support/Google/Chrome/
    ```
15. **Keychain archive** (read-on-demand copy of everything local — app
    passwords, certs, secure notes you forgot you have):
    ```bash
    rsync -a 'christopherstory@macbook.local:Library/Keychains/login.keychain-db' \
      ~/Documents/old-mac-login.keychain-db
    ```
    Open **Keychain Access → File → Add Keychain…** and add that file as a
    *secondary* keychain. It unlocks with the OLD Mac's login password. Do not
    make it the default/login keychain.
16. **`.zshenv_secrets`** if step 5 found one: `scp` it to the same path.

## 5. Re-auth (intentionally not migrated)

17. In rough dependency order:
    ```bash
    # Apple ID first — starts iCloud Photos (97GB, takes days) + iCloud Keychain
    # System Settings → Sign in

    gh auth login          # chris-certifyos (work)
    gh auth login          # christory644 (personal) — then:
    gh auth switch --user chris-certifyos

    gcloud auth login                      # christopher.story@certifyos.com
    gcloud auth application-default login  # ADC — pulumi/terraform read this

    mise use -g node@24
    rustup default stable
    ```
18. Apps and grants:
    - Slack, email, calendar — sign in, check notifications work.
    - Arc + Chrome: sign into browser accounts on top of the copied profiles.
    - Docker Desktop: launch once, accept license; `docker login` if you pull
      private images.
    - AeroSpace: System Settings → Privacy & Security → Accessibility →
      enable AeroSpace.app (re-grant after any flake update that bumps it).
    - Manual casks (documented in `hosts/macbook/homebrew.nix`):
      `brew install --cask insta360-link-controller` (needs sudo TTY), and
      firefoo from <https://firefoo.app> (not in Homebrew).

## 6. Day-one verification ("daily life works")

19. All of these pass before the old Mac stops being your daily driver:
    - [ ] `rebuild` clean; `scutil --get LocalHostName` →
          `christoryCertifyOSMacbook`.
    - [ ] Work stack: certifyos repos cloned, `certify-local` compose stack up,
          `pulumi preview` (or equivalent) succeeds against ADC.
    - [ ] Agents: `claude-personal` and `claude-work` launch; memories present
          (spot-check `MEMORY.md` recall); codex launches with history.
    - [ ] Arc: spaces + pinned tabs intact. Chrome: profile + extensions.
    - [ ] Comms: Slack/email/calendar signed in and notifying.
    - [ ] Syncthing: every folder "Up to Date" on both machines.
    - [ ] Keychain archive opens in Keychain Access with the old password.
    - [ ] Photos: iCloud library downloading (spot-check recent photos exist).

## 7. Week one — use the 256GB

Per-host Ollama tuning is automatic (f16 KV cache, 4 parallel requests, 3
loaded models, 1h keep-alive — `home/ollama.nix`). Worth pulling at this tier
(sizes are q4 defaults; all fit with room to spare):

| Model | ~RAM | Why |
|---|---|---|
| `qwen3-coder:30b` | ~19GB | fast MoE daily-driver for local coding |
| `gpt-oss:120b` | ~65GB | strong general model, MoE so still quick |
| `qwen3:235b-a22b` | ~140GB | the quality tier — impossible on 18GB |
| `nomic-embed-text` | ~1GB | local embeddings |

Try two loaded at once (`ollama ps`) — that's the point of the RAM. Also now
practical with `mlx-lm` (installed via brew): LoRA fine-tuning of 30B-class
models (`mlx_lm.lora --model mlx-community/… --train --data …`) and full-BF16
inference of 70B models. Optional: trial Headroom (`home/headroom.nix`).

## 8. Wipe and return the old Mac (targeted removal)

Employer wants the machine back working — **not** factory-erased. MDM
enrollment and macOS stay; everything personal goes. Do steps in this order.

**Preconditions:** §6 checklist passed ≥1 week ago; no red Syncthing folders;
step 3's bundle re-run within the last day.

20. **Cut replication FIRST** (so the deletions below cannot propagate):
    remove the other device in Syncthing's UI **on both machines**.
21. **On the NEW Mac** — teardown commit in macDots: delete the `macbook` host
    entry from `flake.nix` (marked TEARDOWN), delete the migration-seed folder
    block + `peers` entry in `home/syncthing.nix` (keep agent-state folders for
    a future third machine), push.
22. **Sign out** on the old Mac: iCloud (System Settings → Apple ID → Sign Out
    — turns off Find My), browsers, Slack, any App Store apps.
23. **Revoke local credentials** (do NOT revoke the SSH keys on GitHub — the
    same keypair now lives on the new Mac):
    ```bash
    gh auth logout --user chris-certifyos
    gh auth logout --user christory644
    gcloud auth revoke --all
    docker logout
    ```
24. **Delete personal data:**
    ```bash
    rm -rf ~/repos ~/Documents ~/Downloads ~/Desktop ~/Pictures ~/Movies \
           ~/Music ~/Screenshots
    rm -rf ~/.claude ~/.claude-personal ~/.claude-work ~/.claude-work-sub \
           ~/.codex ~/.codex-personal ~/.codex-work ~/.gemini ~/.pi
    rm -rf ~/.ssh ~/.config/gcloud ~/.gnupg ~/.ollama
    rm -rf ~/Library/Application\ Support/{Arc,Google,Firefox,BraveSoftware,Slack,obsidian}
    rm -f  ~/.zsh_history ~/.*_history
    docker system prune -a --volumes -f
    ```
25. **Keychain:** after sign-outs, delete the login keychain (a fresh empty one
    is created at next login):
    ```bash
    security delete-keychain ~/Library/Keychains/login.keychain-db
    ```
26. **Optional near-stock handback** (IT reimages anyway; skip unless asked):
    uninstall nix-darwin then Lix —
    `nix run nix-darwin#darwin-uninstaller`, then
    `sudo /nix/lix-installer uninstall` (path exists if Lix installed it).
27. **Last-chance audit** — every line must come back empty / logged-out:
    ```bash
    ls ~/repos ~/Documents ~/Desktop ~/Pictures 2>&1        # No such file
    ls -d ~/.claude* ~/.codex* ~/.gemini ~/.ssh 2>&1        # No such file
    find ~ -maxdepth 4 -name .git -not -path '*/Library/*' 2>/dev/null
    find ~ -maxdepth 3 -name 'id_*' -o -maxdepth 3 -name '*.pem' \
      -o -maxdepth 3 -name '*.age' 2>/dev/null
    gh auth status 2>&1 | head -2                           # not logged in
    gcloud auth list 2>&1 | head -3                         # no accounts
    defaults read MobileMeAccounts 2>/dev/null | grep AccountID   # nothing
    ls ~/Library/Application\ Support | grep -iE 'arc|chrome|slack|obsidian'
    security list-keychains -d user                         # fresh login only
    ```
    Empty the Trash. FileVault means residual blocks are cryptographically
    unreadable once the account password changes hands.
28. Hand it back.

---

## Troubleshooting: bootstrap died partway

`bootstrap.sh` is idempotent — **re-running it is always safe**; open a
**fresh terminal** and re-run the one-liner (with `BOOTSTRAP_HOST`). It skips
whatever already completed.

- **`nix: command not found` in a fresh shell** — source the daemon profile,
  then re-run:
  ```bash
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  ```

- **Nix installed, but nothing is activated** (`nh`/`rebuild` missing, even
  after reboot) — the switch never completed; `/run/current-system` won't
  exist. Finish by hand:
  ```bash
  cd ~/repos/macDots
  nix build ".#darwinConfigurations.christoryCertifyOSMacbook.system"
  sudo ./result/sw/bin/darwin-rebuild switch --flake ".#christoryCertifyOSMacbook"
  ```

- **Switch aborts on existing `/etc` files** (`… would be clobbered`):
  ```bash
  sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
  sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
  sudo mv /etc/zprofile /etc/zprofile.before-nix-darwin
  ```

- **System came up but shell aliases / `cmux` / tmux config are missing** —
  home-manager runs **after** Homebrew during the switch, so a failing
  `brew bundle` aborts before home-manager writes `~/.zshrc`. Confirm with
  `ls -la ~/.zshrc` (should be a symlink into `/nix/store`). Fix the brew
  failure and re-switch.

- **A Homebrew cask won't install on this macOS** — remove it from
  `hosts/macbook/homebrew.nix` `casks` and re-switch; casks after the failing
  one get skipped too and install on retry.

- **Aerospace runs but won't manage windows** — grant Accessibility (§5), and
  re-grant after flake updates that bump its version.
