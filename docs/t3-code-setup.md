# T3 Code — what it is, and how to set it up here

> Researched 2026-10-19 on `christoryCertifyOSMacbook`. Nothing was changed: every
> recommendation below is a proposal, and `~/.t3` is exactly as it was found.
>
> Two kinds of claim appear in this document and they are kept apart on purpose:
> **Verified here** means I checked it on this machine (filesystem, SQLite, the
> app bundle, or the TypeScript sources recovered from the shipped sourcemaps
> inside `app.asar`). **Upstream** means it comes from the public repo and docs
> for a version you do not have installed yet. Where the two disagree, they
> disagree because your build is a month old — and that gap is the single most
> important fact in here.

---

## 1. What T3 Code is

It is not an agent and it does not sell you tokens. It is a **GUI control plane
over the agent CLIs already installed on this machine** — `claude`, `codex`,
and others — run by a local server that owns the processes, the terminals, the
git operations and the project state. Desktop (Electron), web and mobile clients
all drive that one local server.

The product shape, in the terms it uses itself:

- A **project** is a repo. A **thread** is one task in that repo, with its own
  conversation, its own provider instance and model, and optionally its own git
  worktree.
- A **provider instance** is a configured agent: a driver (`claudeAgent`,
  `codex`, `cursor`, `grok`, `opencode`, `antigravity`) plus a binary path, a
  config directory, and launch arguments. You can configure **several instances
  of the same driver** — this is the part that matters for your setup.
- Threads run in parallel, can be forked, settled, snoozed and pinned, and the
  server keeps running them whether or not a client is attached.

Source: `t3.codes`, `github.com/pingdotgg/t3code` (MIT), and the shipped sources.

### The genuinely distinctive bit

Everything else on this machine that manages agents is a thing you sit in front
of. T3 Code's server/client split means the agents run **here** while you drive
them from a phone, a browser, or another machine — over LAN pairing, Tailscale,
or T3's own relay ("T3 Connect"). That is the one capability nothing else in
your stack has. If you do not want that, most of the rest of T3 Code overlaps
with tools you already run (see §9).

---

## 2. What is actually on this machine

**Verified here, 2026-10-19:**

| Thing | State |
|---|---|
| App | `/Applications/T3 Code (Alpha).app`, version **0.0.40**, bundle id `com.t3tools.t3code`, Electron, built 2026-09-07 |
| Cask | `t3-code` installed at 0.0.40 on 2026-09-09. The **current cask is 0.1.0** and its artifact is now `T3 Code (Beta).app`. `auto_updates true` — Homebrew is not the update channel |
| macDots | `t3-code` is **already declared** in `hosts/macbook/homebrew.nix:69` |
| State | `~/.t3/{dev,userdata}`, 113 MB total — of which **112 MB is log files** |
| Databases | `userdata/state.sqlite` and `dev/state.sqlite`: **0 projects, 0 threads, 0 orchestration events, 0 turns, 0 messages, 0 provider sessions.** 47 schema migrations applied, the last on 2026-09-05 |
| Settings | **No `settings.json` in either state directory.** Every server setting is at its built-in default and no provider was ever configured |
| Logs | Traces span **2026-09-29 17:31Z → 2026-10-04 04:02Z**. The only span names present are `PortDiscovery.pollTick`, `ServerSecretStore.get`, `sql.execute`, `ThreadSettlementReactor.sweep` and resource telemetry. **No provider spans at all** |
| Electron profile | No `~/Library/Application Support/t3code`, no `T3 Code (Alpha)` profile, no `com.t3tools.t3code.plist` |
| Agent CLIs | `claude` **2.1.303** → `/opt/homebrew/bin/claude`; `codex` **0.154.0** → `/opt/homebrew/bin/codex` |

Read that table together and it says something quite specific: on the old Mac
the T3 server was started and left running idle for about four and a half days,
burning roughly **1 MB of trace log per idle hour**, and in that time **not one
project was created and not one agent was ever launched**. You carried over
112 MB of nothing. The Electron app has never run on *this* machine at all.

Two useful consequences:

- There is **no state worth preserving**. You can delete `~/.t3` outright and
  lose nothing but a pairing identity you would re-create on first launch.
- You are clean of upstream issue #15001 (a V2 desktop build seeding its
  profile from a stale "T3 Code (Alpha)" Electron profile and corrupting the
  connection catalog), because no such profile exists here.

### One collision, already in your shell

`home/shell/zsh.nix` defines `t3 = "tree -L 3"`. T3 Code's CLI is **`t3`**.
Verified: `command -v t3` finds nothing on PATH today, so the alias wins and
installing T3's shim would silently shadow — or be shadowed by — your tree
alias depending on load order. This needs a decision before you install the CLI
(§6, step 2).

---

## 3. How it connects to Claude and Codex

### Claude — the Agent SDK, pointed at your binary

**Verified from the shipped sources.** T3 Code does not call the Anthropic API
and does not shell out to `claude -p`. It uses `@anthropic-ai/claude-agent-sdk`
and hands it `pathToClaudeCodeExecutable` — the SDK then spawns **your**
installed `claude`. Your 2.1.303 is current enough for every model in the
manifest (the newest, `claude-fable-5-1`, wants 2.1.257+).

Per-instance settings, in the order the settings form shows them:

| Setting | Meaning |
|---|---|
| **Binary path** | Path to `claude`. Placeholder is the bare name `claude`, resolved on the server's PATH |
| **CLAUDE_CONFIG_DIR path** | *"Custom Claude home and config directory. Keeps `.claude.json` and `.claude` separate."* |
| **Auto-compact after** | 100,000–1,000,000 tokens, or empty for Claude's default |
| **Launch arguments** | Extra CLI args |

Auth is **your existing CLI login** — subscription OAuth or whatever that config
directory already holds. There is no T3 API key and no T3 account for agent
auth. (A T3 Connect account exists, but only for the remote-access relay.)

The mechanism is worth quoting, because it is exactly the trap you would
otherwise hit:

> Isolate this instance's config via `CLAUDE_CONFIG_DIR` rather than `HOME`.
> Overriding `HOME` also relocates the macOS login keychain lookup
> (`$HOME/Library/Keychains`), so the spawned CLI can't find its stored OAuth
> credentials and reports "Not logged in". `CLAUDE_CONFIG_DIR` points Claude
> Code at its config dir directly while leaving `HOME` (and the keychain)
> intact.
>
> — `apps/server/src/provider/Drivers/ClaudeHome.ts`, verbatim from the bundle

### Codex — the CLI in `app-server` mode

**Verified from the shipped sources.** T3 spawns `codex app-server` and speaks
its JSON-RPC protocol through a hand-written Effect client. Settings:
**Binary path**, **CODEX_HOME path**, **Shadow home path**, **Launch arguments**.

The shadow home is an auth overlay: the private entries (`auth.json`,
`models_cache.json`) live in the shadow directory while `sessions`,
`archived_sessions`, `sqlite`, `shell_snapshots`, `worktrees`, `skills`,
`plugins`, `cache` and `logs` are shared from `CODEX_HOME`. It exists so two
accounts can continue the *same* threads. **You don't need it** — you already
keep `~/.codex-work` and `~/.codex-personal` fully separate, which is the
"direct" mode and is the cleaner arrangement.

### Your aliases do not reach it — this is the crux

Your profile separation lives entirely in zsh aliases:

```
claude-personal  = CLAUDE_CONFIG_DIR=~/.claude-personal  command claude …
claude-work-sub  = CLAUDE_CONFIG_DIR=~/.claude-work-sub  command claude …
codex-personal   = CODEX_HOME=~/.codex-personal  command codex
codex-work       = CODEX_HOME=~/.codex-work      command codex
```

T3 Code will never see any of that. **Verified from the sources:** on macOS the
server hydrates exactly two variables from your login shell — `PATH` (via
`zsh -ilc`, 5-second timeout, falling back to `launchctl getenv PATH`) and
`HOME`. Nothing else. And even a full environment inherit would not help,
because `CLAUDE_CONFIG_DIR` is set *inside* the aliases, never exported.

So: **the config directory must be typed into each provider instance's settings
by hand.** That is the single configuration step that makes T3 Code fit your
setup rather than quietly running everything against a default `~/.claude` that
has never been logged in.

(Measured: `zsh -ilc` takes 0.30–0.32 s here, comfortably inside the 5 s budget.
Your `compinit -i -D` fix is what buys that — worth remembering if the PATH
hydration ever starts failing.)

### Permission modes

**Verified:** T3's thread runtime modes are `approval-required`,
`auto-accept-edits`, `auto`, `full-access`, defaulting to **`full-access`**,
which the Claude adapter maps to the SDK's `permissionMode: "bypassPermissions"`
with `allowDangerouslySkipPermissions` set.

That is already equivalent to your
`--enable-auto-mode --allow-dangerously-skip-permissions` aliases. **Do not also
put those flags in Launch arguments** — you would be fighting T3's own
per-thread permission plumbing for no gain.

### Models

`~/.t3/userdata/model-manifest.json` (fetched 2026-09-12) is the cached
catalogue. For Claude it offers Fable 5.1 / Opus 5 / Sonnet 5, each with a
reasoning-effort selector (including `ultracode` and `ultrathink`) and a context
window selector. Note for you specifically: choosing the **1M** window makes T3
append the `[1m]` model suffix — the same mechanism your Headroom proxy note in
`zsh.nix` is about. T3 handles it correctly and per-thread, which is nicer than
pinning it in an alias.

---

## 4. Worktrees

**Verified in the installed 0.0.40:**

- `defaultThreadEnvMode` defaults to **`local`** — new threads work in the
  existing checkout. Worktrees are opt-in.
- Worktree root is **`<baseDir>/worktrees`** = `~/.t3/worktrees`, computed in
  `config.ts` and **not configurable in this build**. (I probed the bundle: the
  strings "Worktree location", "Worktree branch naming" and "Keep worktrees with
  local changes" do not exist in 0.0.40.)
- `newWorktreesStartFromOrigin` defaults to true.
- A repo can opt in by committing `t3.json` at its root:
  `{"$schema": "https://t3.codes/schema/t3.json", "defaultThreadEnvMode":
  "worktree", "scripts": [{"name": …, "command": …, "runOnWorktreeCreate":
  true}]}` (max 50 scripts).

**Upstream in 0.1.0**, not verifiable here: a per-machine *Settings → Storage →
Worktree location*, worktree branch naming (static prefix, default `t3/`, or a
model-chosen semantic prefix), and automatic cleanup policies (off by default;
"keep worktrees with local changes" protects tracked edits and untracked files
**but deletes ignored files such as `.env` and build output**).

### What this means for your layout

You already have two worktree conventions — `~/repos/.worktrees/*` and
`<repo>/.claude/worktrees/*` — and supacode is separately creating and
*auto-archiving* worktrees on a 14-day timer. Adding a third tool with its own
lifecycle policy into the same directories is how worktrees get deleted out from
under a running agent.

Keep T3's worktrees in their own root, and on a build that lets you move them,
move them somewhere explicit (`~/repos/.t3-worktrees`) rather than leaving them
buried in `~/.t3`. Do **not** point T3 at `~/repos/.worktrees`.

One pleasant surprise, verified: T3's `AgentSessionScanner` reads your existing
Claude Code and Codex transcripts (read-only, newest-first, capped at 5000 per
source) and uses the recorded `cwd` values to *propose* projects during
onboarding. With 165 entries under `~/repos` that is a real convenience — but
expect it to offer you a long list.

---

## 5. Known issues

**In the alpha you have (0.0.40), verified by absence in the bundle:** no
worktree location setting, no branch naming, no cleanup policies, no
"Connect with ChatGPT" for Codex, and it is the **V1 orchestrator** (no
`statev2`). It also logs ~1 MB/hour while completely idle, which is how you
ended up carrying 112 MB of traces across machines.

**Upstream, for the 0.1.0 you would be upgrading to:**

- The **V1 → V2 migration is a one-way copy** made on first start. The old
  version keeps its own database; changes in one do not appear in the other.
  Live provider sessions, old checkpoints and diffs, tool activity, approval
  history and proposed plans are not carried over. *(Irrelevant to you — your V1
  database is empty.)*
- **Version lockstep**: a V2 server cannot talk to a V1 app. Server, desktop,
  background service and mobile must move together.
- **Switching provider mid-thread is lossy** — the new provider gets a budgeted
  selection of messages, not the previous provider's reasoning, tool calls or
  attachments.
- Minimum provider versions for 0.1.0: **Claude Code 2.1.280+** (you have
  2.1.303 ✓) and **Codex 0.159+** (you have **0.154.0 ✗** — see step 7).
- Open issues that would bite *your* setup specifically: **#15353** (Claude auto
  mode on orchestrator V2 running ask-rule commands without prompting) and
  **#16672** (custom Claude model effort/thinking selections saved but dropped
  at runtime).
- The README's own line: *"We are very very early in this project. Expect bugs."*
  771 of 2,813 open issues are labelled `bug`.
- **Telemetry is on by default** (provider, model, effort, permission mode, turn
  result, duration, token totals — not prompts or file contents), sent to
  `ingest.t3.codes`. Documented opt-out: `T3CODE_TELEMETRY_ENABLED=false`.

There is **no docs site and no changelog file**. All documentation is raw
markdown in the repo under `docs/`; release notes exist only on GitHub Releases.
For an alpha-to-beta tool that is a legitimate finding, not an oversight on my
part — plan on reading source when something is unclear, as I did here.

---

## 6. Recommended setup

Eight steps. Steps 1–4 are the ones that matter.

### Step 1 — Upgrade before you ever launch it

```sh
brew upgrade --cask t3-code
```

Do this *first*, not after. Your 0.0.40 is the V1 orchestrator and lacks every
worktree setting you would want; launching it first just means doing a one-way
V1→V2 migration of an empty database for no reason.

The cask artifact was renamed `T3 Code (Alpha).app` → `T3 Code (Beta).app`.
Afterwards, check whether the old bundle was left behind and remove it if so:

```sh
ls -d "/Applications/T3 Code"*.app
```

A leftover Alpha bundle is also what feeds upstream issue #15001, so don't leave
one lying around.

### Step 2 — Decide what `t3` means

`t3` is currently `tree -L 3`. If you want T3 Code's CLI (`t3 app`, `t3 serve`,
`t3 doctor`, `t3 service install`), the alias has to move. Proposal, in
`home/shell/zsh.nix` alongside `t1`/`t2`:

```nix
t3 = "tree -L 3";   # remove
t3d = "tree -L 3";  # or drop it entirely — `tree -L 3` is not long
```

If you would rather keep the alias, simply never install T3's CLI shim and drive
it from the GUI only. Either is fine; leaving both is not.

### Step 3 — Start from a clean `~/.t3`

The carried-over state is 112 MB of idle traces and two empty databases. The
cleanest start, and the one I would take:

```sh
rm -rf ~/.t3
```

You lose three `auth_sessions` rows and two key files in `secrets/` — a pairing
identity that is regenerated on first launch. If you would rather be
conservative, the minimum useful version is:

```sh
rm -rf ~/.t3/userdata/logs/* ~/.t3/dev/logs/*
```

`~/.t3/dev` is only ever used when running T3 from source with a dev server URL.
You have no reason to keep it.

### Step 4 — Create four provider instances

This is the step that makes T3 fit your profiles. Settings → Providers → add an
instance per row. Use **absolute binary paths** — the PATH it hydrates is your
login shell's, and pinning removes a whole class of failure.

| Instance id | Driver | Binary path | Config dir |
|---|---|---|---|
| `claude_work_sub` | claudeAgent | `/opt/homebrew/bin/claude` | **CLAUDE_CONFIG_DIR** `~/.claude-work-sub` |
| `claude_personal` | claudeAgent | `/opt/homebrew/bin/claude` | **CLAUDE_CONFIG_DIR** `~/.claude-personal` |
| `codex_work` | codex | `/opt/homebrew/bin/codex` | **CODEX_HOME** `~/.codex-work` |
| `codex_personal` | codex | `/opt/homebrew/bin/codex` | **CODEX_HOME** `~/.codex-personal` |

- Leave **Shadow home path** empty on both Codex instances. Your homes are
  already fully separate; the overlay solves a problem you don't have.
- Leave **Launch arguments** empty on all four. In particular do not add
  `--allow-dangerously-skip-permissions` or `--enable-auto-mode`; T3's
  `full-access` runtime mode already sets the SDK equivalent (§3).
- Set `claude_work_sub` as the default instance, mirroring your bare `claude`
  alias.
- Caveat, documented upstream: **an existing thread can only switch between
  Claude instances that share a config directory.** Pick the account when you
  create the thread.
- If a provider shows "not logged in", the fix is to log in *on this machine for
  that config dir* — `CLAUDE_CONFIG_DIR=~/.claude-personal claude auth login` —
  not to change anything in T3.

### Step 5 — Worktrees

Leave the global default at **`local`**. Opt specific repos in by committing a
`t3.json`, rather than flipping the global switch across 165 repos.

On 0.1.0, set *Settings → Storage → Worktree location* to a dedicated path:

```
~/repos/.t3-worktrees
```

Not `~/repos/.worktrees`, and not `<repo>/.claude/worktrees` — those belong to
your scripts and to Claude Code. If you enable T3's cleanup policies later, read
the "keep worktrees with local changes" caveat first: it protects tracked and
untracked files but still deletes ignored ones, which means `.env` files.

### Step 6 — Turn telemetry off

Documented opt-out is `T3CODE_TELEMETRY_ENABLED=false`. Note the wrinkle: for a
Finder-launched Electron app, a variable exported in `zsh.nix` does **not**
reach the process. If 0.1.x exposes a Settings toggle, use that. If it does not,
the env-var route needs `launchctl setenv` or a launchd agent — which is a
bigger lever than it is worth for a tool you are still evaluating. Check the
Settings UI first.

### Step 7 — Bring Codex up to the minimum

```sh
brew upgrade --cask codex   # 0.154.0 → 0.159+ required by T3 Code 0.1.0
```

### Step 8 — Verify, in this order

1. Open one project in **local** mode (not worktree) — `~/repos/macDots` is a
   good low-stakes choice.
2. Send a trivial prompt on `claude_work_sub`. Confirm it answers and that the
   account is the right one.
3. Repeat on `claude_personal`, `codex_work`, `codex_personal`. The point of
   this step is catching a wrong `CLAUDE_CONFIG_DIR` *before* it does work under
   the wrong account.
4. Only then try a worktree thread in one repo.

---

## 7. What should be declared in macDots

**Already declared, correctly:** the `t3-code` cask, `hosts/macbook/homebrew.nix:69`.
Worth updating the trailing comment to note the cask now ships
`T3 Code (Beta).app` and self-updates, so `brew` will drift from the installed
version by design.

**Should be declared:** the `t3` alias decision in `home/shell/zsh.nix`
(step 2). That is a shell fact and it belongs in the flake like every other
alias.

**Should NOT be declared — deliberately:** `~/.t3/userdata/settings.json`.
It is tempting to pin the four provider instances there, and I recommend against
it:

- T3 Code **writes that file itself** (atomic write) every time any setting
  changes. A home-manager-managed file is either read-only, which the app will
  fight, or copied once and then diverged, which is worse than not managing it.
- The `ServerSettings` schema is visibly mid-migration — the shipped source
  carries a `providers.<kind>` block explicitly marked legacy and a newer
  `providerInstances` map, with a comment saying the old one *"shrinks to
  nothing and is removed entirely"*. Pinning a hand-written file to a schema
  that is actively being replaced in an alpha is a recipe for a provider list
  that silently stops decoding.

The §6 table **is** the declaration. Reapply it by hand if `~/.t3` is ever
rebuilt; it is four form fills.

**Worth considering, not yet worth building:** log hygiene. At ~1 MB/idle-hour,
`~/.t3/*/logs` will reach 100 MB again on its own. If T3 Code becomes part of
daily life, a small launchd job trimming those rotations is the right shape. If
it doesn't, delete `~/.t3` instead.

**Never declare:** `~/.t3/*/secrets/`, `environment-id`, or `state.sqlite`.
Machine identity and live state, not configuration.

---

## 8. Assumptions I made

The session ran while you were asleep, so these were decided rather than asked:

1. **Upgrading before first launch is right.** It is reversible, your V1 state
   is empty, and 0.0.40 lacks settings the recommendation depends on.
2. **A clean `~/.t3` is better than the carried-over one.** Justified by the
   databases being empty — if they had held threads I would have said the
   opposite.
3. **Worktrees stay opt-in per repo.** Flipping the global default across 165
   repos while supacode is separately auto-archiving worktrees is the kind of
   change that is hard to notice and hard to undo.
4. **You want the same four profiles T3 that your shell has.** Including
   `claude-work` staying retired — it is not in the table.

---

## 9. How it compares to what you already run

| Tool | What it actually is | Overlap with T3 Code |
|---|---|---|
| **supacode** 0.10.8 (`app.supabit.supacode`) | Worktree-per-task GUI around coding agents: per-repo setup/run/archive scripts, auto-archive after 14 days, PR merge strategy, GitHub integration | **Heavy. This is the duplicate.** Same core idea: a GUI that spawns an agent per task in its own worktree, with per-repo scripts and PR plumbing. If you keep both, keep them for different reasons, and keep their worktree roots apart |
| **cmux** 0.64.22 (`com.cmuxterm.app`) | A terminal — tabs, panes, workspaces, sessions. In active use today | **None.** It is where you *run* things; T3 is a thing you'd run. Complementary |
| **Claude Desktop** | Anthropic's chat client: one vendor, one account, no repo model | Minimal |
| **Codex app** | OpenAI's desktop client, one account (`~/.codex`) | Minimal |
| **Gas Town / Gas City** (`gt`/`gc`) | Multi-agent orchestration across many repos, per-profile config, tmux-backed, fleet-scale | **Different axis.** Gas Town is about many agents on one body of work; T3 is one thread per task on one machine, with a good UI. They are not substitutes |

### The honest summary

Against **supacode**, T3 Code is largely a second implementation of the same
idea, and you configured supacode on this machine earlier tonight. The things T3
adds on top:

- **Multiple accounts of the same agent, side by side**, as a first-class
  concept — your four profiles as four provider instances, selectable per
  thread. Nothing else here does that in a GUI.
- **Multiple agent vendors behind one interface** — Claude and Codex in the same
  thread list, with per-thread model and reasoning-effort selection (including
  the 1M-context tag you currently pin in an alias).
- **Remote access to agents running on this Mac** — phone, browser, another
  machine. This is the genuinely unique capability and the only reason I would
  call installing it clearly worthwhile rather than a matter of taste.

If remote access doesn't appeal, the fair verdict is: you already own this
category, you have not used T3 Code once in the six weeks it has been installed,
and the honest options are to give it one real evaluation against a single repo
(§6) or to drop the cask from `homebrew.nix` and reclaim the `t3` alias.

Unrelated but noticed while comparing: `~/.supacode/settings.json` still
references `/Users/christopherstory/repos/...` — old-Mac paths that survived the
migration. Worth a look when you are next in there.

---

## 10. What I could not determine

- **Whether 0.1.x keeps the setting names I read out of 0.0.40.** Everything in
  §3 and §4 marked "verified" was read from the build on this disk. The upgrade
  in step 1 changes that build, and the provider settings schema is explicitly
  mid-migration.
- **Whether `brew upgrade --cask t3-code` removes the old Alpha bundle** given
  the artifact rename. The stored cask receipt here is empty, so I could not
  confirm it from metadata. Hence the explicit check in step 1.
- **Whether 0.1.x has a telemetry toggle in Settings.** Only the environment
  variable is documented, and that is awkward for a GUI-launched app.
- **How T3 Code behaves at your scale.** It has never been run with a project on
  this machine or, as far as the logs show, on the old one. 165 repos, 10
  existing worktrees and two other tools managing worktrees is not a
  configuration anyone has tested for you.
- **Whether you want it.** That one is genuinely yours.
