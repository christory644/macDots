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

## 2. Syncthing seed — COMPLETE (2026-09-10 ~05:20)

All 14 folders settled; `scripts/sync-status.sh` exits 0. Verified against the
old Mac: 126 of 126 repo directories, 12,662 of 12,662 Downloads files,
Documents matching, `second_brain` intact at 12 GB with matching HEAD. Sleep
guards released on both machines.

Two problems surfaced during the seed and are worth knowing about:

- **The receiving side wedged.** `Downloads` sat in `sync-preparing` for over
  90 minutes with zero throughput while the sending side was idle and healthy
  with all 12,661 files ready. Restarting the local service
  (`launchctl kickstart -k gui/$(id -u)/org.nix-community.home.syncthing`)
  cleared it immediately. Worth checking for if a folder ever looks stuck:
  compare both ends before assuming a network problem.
- **16 files in `Documents/work-scratch` failed repeatedly** with
  `finishing: pull: generic error`, leaving `.syncthing.*.tmp` files behind.
  Ordinary small files, writable target directories, and a manual rename in
  the same directory worked, so the cause was never identified. Resolved by
  rsyncing those 16 directly and rescanning.

**Live `.git` on two machines produced real conflicts**, exactly the risk noted
in §4. 23 `.sync-conflict-*` files appeared, confined to the two repos being
written on both machines at once: `macDots` (edited here) and `second_brain`
(its auto-commit service running there). All were `.git` internals — index,
refs, logs, one loose object. Neither repo was damaged: both `fsck` clean and
both HEADs match the old Mac exactly. The debris has been removed. This is the
concrete argument for §4's pruning job, not a hypothetical one.

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
