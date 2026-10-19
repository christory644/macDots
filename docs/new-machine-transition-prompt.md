# Prompt: get this Mac transition-ready, then move daily life to the new one

> Paste everything below into a fresh Claude Code session started in `~/repos/macDots`.
> Facts in "Verified state" were checked on 2026-08-30 — re-verify before relying on any of them.

---

I'm moving to a new work MacBook. The move keeps getting deferred, and I want it to stop being a big scary event.

Your job has two halves:

1. **Get THIS machine into a state where the new machine can clone `macDots`, run the bootstrap, and more or less just start working.**
2. **Produce a transition guide** I can actually execute: bring the new machine up, get every file across, and make daily life fully functional on it.

It does not need to be perfect. The bar is: *daily life can move to the new machine, and we iron out the kinks over there.* Prefer shipping a good-enough path over designing a flawless one.

## Decisions already made — don't re-litigate these

- **The new machine is a work MacBook with 256GB unified memory.** A Mac Studio was once planned; that's cancelled, but the memory tier is not — this is still a ~14x jump from the current M3/18GB. All the RAM-dependent tuning (Ollama parallelism, KV cache precision, loaded-model count, which large models to pull, MLX fine-tuning workflows) **does** apply and is real work, not a footnote.
- **It's MDM-managed, but the same way this machine already is.** nix-darwin works here, so it will work there. This is a retired risk — don't build contingency around it.
- **Coexistence, not cutover.** Both machines stay online until the new one is good and stable. *Then* the old one gets wiped of all repos, tools, and personal files and **returned to the employer.** The wipe-and-return is a real phase of the guide, not an afterthought — it has its own checklist and its own "did I actually get everything off?" verification.
- **Re-logging into services is fine**, and often preferable to migrating auth. Don't build elaborate credential-migration machinery where a fresh login would do.
- **These must actually move**, not be recreated: browser profiles, local agent memories and files, important local files, and keychains.
- The flake already encodes the two hosts: `macbook` / `christopherstory` is this (old) machine, marked TEARDOWN; `christoryCertifyOSMacbook` / `christory` is the new keeper. Confirm the new machine's real hostname matches before bootstrap day.

## Still ask me about

Interview me in small batches (2–4 questions), not one wall of text. Then write a plan, show me, and execute after I approve. **Don't change anything before the interview.**

- **Keychain migration is the hard one.** Work out the options and their trade-offs before asking me to choose — Migration Assistant moves keychains wholesale but may fight a nix-managed setup (or be restricted by MDM); manual keychain export is fiddly; per-service re-login is simplest but loses things I've forgotten I have. I said keychains should move "if possible" — tell me what possible actually costs here.
- **Which browser profiles, and how.** Arc, Chrome, Firefox all differ; some state syncs through the browser account and some (extensions, local storage, open tabs/spaces) doesn't.
- **What counts as "important local files"** outside `~/repos` — Documents, Desktop, Downloads, Obsidian vaults, screenshots, Docker volumes, local databases.
- **Which agent state matters** — `~/.claude-personal` is the live Claude config dir (`CLAUDE_CONFIG_DIR`), and there are other agents installed (codex, gemini, gastown/gas city, pi). Ask which of their memories/histories I care about.
- **What "daily life fully functional" means on day one** versus what can wait a week.
- **Old-machine wipe standard** — factory erase, or targeted removal of personal data? It's going back to an employer, so ask what they require.

## Verified state (checked 2026-08-30 — re-verify)

**What already exists — do not rebuild these:**

- `scripts/bootstrap.sh` — one-liner new-Mac setup: Xcode CLT → clone repo over HTTPS → install Lix → decrypt SSH keys from `secrets/` (passphrase prompt) → swap remote to SSH → build/activate nix-darwin → rustup → clone repos from manifests. **The clone+passphrase age bootstrap already works — do not propose replacing it with agenix.**
- `docs/migration.md` (151 lines) — a runbook already exists with pre-flight, bootstrap, Syncthing pairing, re-auth, and verification sections. **Extend and correct this rather than writing a new one.** It has no wipe-and-return phase yet.
- `docs/superpowers/specs/2026-06-30-new-macbook-migration-design.md` and the two-machine coexistence spec + plan (the coexistence design is still live given the decision above).
- `scripts/clone-repos.sh`, `verify-secrets.sh`, `encrypt-keys.sh`, `setup-gcp-agent-sa.sh`.
- Two-host flake (`mkHost`), per-host hostname, per-host `rebuild`/`update` aliases, Universal Control disabled — all landed.

**Known gaps — these are the actual work:**

1. **107 of 139 directories in `~/repos` are not in any manifest.** `repos.yml` (18) + `repos-private.yml` (14) = 32 listed; a fresh bootstrap recreates only those. Worse: **21 of the unlisted repos have no git remote at all** — including `second_brain` — so they exist nowhere but this disk. There are also ~11 non-git directories. Triage with me: which get a remote, which get archived, which are disposable (several `-wt-` worktrees and `open_graph_previewer*` variants probably are).
2. **Syncthing has no peer configured.** `home/syncthing.nix:79` is a placeholder (`# studio.id = "XXXXXXX-..."`) — stale naming from the cancelled Studio plan; rename it for the new MacBook. It's `enable = true` but syncs with nothing. Since both machines will run side by side, Syncthing is the natural transport for exactly the "must actually move" list above — getting it paired early is high-leverage. Note replication is not backup: a deletion propagates to both.
3. **The coexistence plan's checkboxes are stale** — Tasks 1–4 are unchecked in the doc but landed in git. Fix or archive so it doesn't mislead.
4. **Unpushed commits.** The new machine clones from GitHub, so anything local is invisible to it. As of writing, `main` was ahead of `origin/main` by 4. Make "push everything, everywhere" a pre-flight step, and check the other repos too.
5. **Local-LLM config is hardcoded for an 18GB machine, and duplicated.** `home/shell/zsh.nix:70-75` and `home/ollama.nix:15-19` both set `OLLAMA_NUM_PARALLEL=1`, `OLLAMA_MAX_LOADED_MODELS=1`, `OLLAMA_KV_CACHE_TYPE=q8_0` with comments literally saying "RAM limited". Two problems: the values are wrong for 256GB, and they're **not per-host** — the new machine would inherit the 18GB tuning. The flake is already two-host (hostname and shell aliases are parameterised), so this should follow the same pattern rather than being edited in place. Also revisit which models are worth pulling at that tier, and whether `mlx-lm` fine-tuning (already installed via brew) becomes practical.

6. **Re-auth inventory is undocumented.** Two `gh` accounts (`chris-certifyos` active, `christory644`), `gcloud` as `christopher.story@certifyos.com` currently in a failed-reauth state, plus a separate `~/.config/gcloud/application_default_credentials.json` that pulumi/terraform use. Also `mise` toolchains and Homebrew casks that need manual install (`aerospace`, `insta360-link-controller`, firefoo). `docs/migration.md` §4 covers some of this — verify it's complete. Since I'm happy to re-login, this is mostly a *checklist* problem, not a migration problem.

## Deliverables

**A. This machine, transition-ready.** Everything I care about is either in a git remote, in the age-encrypted `secrets/`, declared in the nix config, on the Syncthing move-list, or explicitly written down as "re-created by hand." Nothing important exists only as an undeclared file on this disk.

**B. A transition guide** — extend `docs/migration.md` to cover, in executable order: pre-flight here; bootstrap there; moving the files git and nix don't cover; re-auth checklist; a "daily life works" verification list from my interview answers; and finally the wipe-and-return phase for this machine, including a last-chance check that nothing personal is left on it.

## How to work

- **Verify, don't assume.** Check current state before acting, and say what you actually ran. Several facts above contradicted the repo's own docs.
- **Push back** if I'm asking for something that won't survive contact with the new machine.
- Commit as you go with focused commits; don't push without asking.
- Small batches of questions → plan → my approval → execution.
- Flag anything that can only happen on the *new* machine separately — I can't act on those until I have it.

The end state I want: I open the new MacBook, run one command, walk away, come back, and it's my machine — with a short, honest list of what I still have to do by hand. And when I hand the old one back, I'm confident nothing of mine is on it.
