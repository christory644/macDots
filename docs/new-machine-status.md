# New MacBook — what's done, what's left

Companion to `docs/migration.md` (the runbook). The runbook says how; this says
where we actually are. Last verified **2026-09-10**, on
`christoryCertifyOSMacbook`.

**Why it felt half-baked:** the original bootstrap died silently. On a fresh Mac
`rustc` isn't on PATH, so `bootstrap.sh` took its rust branch and called
`rustup-init`, which nothing in the flake provides. Under `set -euo pipefail`
that exits 127 on the line immediately before the repo clone. nix-darwin had
already activated and every cask was installed, so the machine looked fine and
`~/repos` was empty. Fixed in `scripts/bootstrap.sh`; the class of bug is now
guarded against by making that step non-fatal.

---

## 1. Done and verified

| Area | State |
|---|---|
| nix-darwin | generation activated, hostname `christoryCertifyOSMacbook` |
| home-manager | `.zshrc`, `.zshenv`, `.ssh/config`, `.aerospace.toml` all symlinked into the store |
| SSH keys | decrypted **and** unlocked into the login keychain (both accounts authenticate to GitHub) |
| Homebrew | 24 casks installed |
| GitHub CLI | both accounts logged in, `chris-certifyos` active |
| gcloud | account + project `certifyos-development` + ADC with quota project |
| Docker | daemon runs |
| mise | 11 runtimes incl. elixir 1.20.4 on Erlang/OTP 29; php dropped |
| AeroSpace | running with Accessibility granted |
| Fonts | 26 user fonts incl. Operator Mono Lig — see note below |
| Arc / Chrome | profiles copied (861 MB / 4.9 GB), spaces and both Chrome profiles intact |
| Keychain archive | `~/Documents/old-mac-login.keychain-db` |
| Syncthing | paired, all 14 folders shared both directions |

> **Fonts were a silent trap.** `~/Library/Fonts` is not a synced folder and is
> not in the flake, yet `home/vscode.nix` and the terminal configs ask for
> `Operator Mono Lig` by name — a licensed font that isn't in nixpkgs. It would
> never have arrived on its own. Copied from the old Mac on 2026-09-10. If a
> third machine is ever built, this needs a real answer (vendor the font from
> `~/repos/fonts` via home-manager, since that repo already carries all 12
> families).

## 2. In flight — nothing to do but wait

The Syncthing seed. Check with:

```bash
scripts/sync-status.sh      # exits 0 when settled, 1 while syncing
```

Agent state, Documents, Pictures, Movies, Music and Screenshots are complete.
`repos` and `Downloads` are still transferring. Both machines are held awake
with `caffeinate -ims` and must stay on AC with lids open until it finishes.

Release the guards once settled:

```bash
pkill -x caffeinate
ssh christopherstory@macbook.local pkill -x caffeinate
```

## 3. Blocked on you — GUI only, cannot be scripted

1. **Raycast** — installed but never launched, so it has no config at all.
   Launch it, then System Settings → Privacy & Security → Accessibility and
   enable it. There is **no cloud restore**: `subscriptions_active = 0`, so no
   Raycast Pro and no settings sync. Migrate it with Raycast's own
   export/import, **not** by copying files — its databases are encrypted with a
   key held in the old Mac's keychain. Steps in §4. This is a daily-driver tool,
   so do it first.
2. **Wallpaper** — `~/repos/wallpapers` is synced but nothing is applied.
   System Settings → Wallpaper → Add Folder → `~/repos/wallpapers`. This is
   deliberately manual: macOS Tahoe broke the AppleScript rotation API, so the
   activation hook was removed (`hosts/macbook/default.nix`, and commit
   f3a31a7). Not previously listed in the runbook's re-auth section.
3. **iCloud Photos** — signed in as `christory@pm.me`, but the local library is
   0 bytes, so the download never started. Open Photos.app and enable iCloud
   Photos. This is the only carrier for the 98 GB library, which is
   deliberately excluded from Syncthing.
4. **App sign-ins** — Slack, Discord, Spotify, ChatGPT, Obsidian, and the
   browser accounts on top of the copied Arc/Chrome profiles.
5. **`docker login`** — no auths configured; only needed for private images.
6. **Manual casks** — `brew install --cask insta360-link-controller` (needs a
   sudo TTY) and firefoo from <https://firefoo.app> (not in Homebrew).

## 4. Scriptable, once a precondition clears

- **Raycast config** — use Raycast's own export, **not** a file copy. Its two
  real databases are encrypted (`raycast-enc.sqlite` and
  `raycast-activities-enc.sqlite` have binary headers, while
  `raycast-emoji.sqlite` reads `SQLite format 3`), and the key lives in the old
  Mac's login keychain as service `Raycast`, account `database_key`. rsyncing
  the folder therefore produces an unreadable database — the same trap as the
  SSH key passphrases, and it fails just as quietly.

  The supported path (verified present in the app binary, and free — the Pro
  subscription is only for cloud sync, and `subscriptions_active = 0` here):

  1. **Old Mac** — Raycast → Settings → Advanced → **Export Settings & Data**.
     Save it into `~/Documents`, which is a synced folder, so it lands on the
     new Mac by itself.
  2. **New Mac** — launch Raycast, grant Accessibility, then Settings →
     Advanced → **Import Settings & Data** and pick the `.rayconfig`.

  Raycast is used constantly on the old machine, so treat this as the highest
  priority of the GUI items rather than a nice-to-have.

- **Stop replicating the clone-restorable repos** — after the seed settles.
  83 of 126 repos are exactly reproducible with `git clone`, and keeping them
  in a bidirectional sync means a live `.git` on two machines for no gain.
  `scripts/repo-triage.sh --host christopherstory@macbook.local --emit <dir>`
  produces the manifest and the ignore list.

## 5. Deferred by choice

Ollama models (runbook §7) — nothing pulled yet. `qwen3-coder:30b`,
`gpt-oss:120b`, `qwen3:235b-a22b`, `nomic-embed-text`. Also the optional
Headroom trial (`home/headroom.nix`).

## 6. Then: verify, then tear down

Runbook §6 is the day-one checklist and is **not yet run** — the work-stack
parts need `repos` to finish first (`certify-local` compose stack, a
`pulumi preview` against the new ADC, agent memories spot-check). Only after
that passes for a week does §8 teardown of the old Mac begin.
