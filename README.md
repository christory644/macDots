# macDots

Declarative macOS configuration using **nix-darwin** + **home-manager** + **NixVim**.

> there are many others like it, but these are mine.

## Using this repo

This is my personal system config. You're welcome to browse, fork, and steal ideas — but **the secrets, SSH configs, and repo manifests are mine**. If you fork this:

1. Delete `secrets/` (those are my age-encrypted SSH keys and private config — useless to you)
2. Replace `home/ssh.nix` with your own SSH host config
3. Replace `home/git.nix` with your own identity
4. Edit `repos.yml` with your own repos (or delete it)
5. Create your own `repos-private.yml` for private/work repos (gitignored)
6. Edit `hosts/macbook/homebrew.nix` to match your apps

The bootstrap script gracefully skips SSH decryption and repo cloning if it doesn't find my encrypted keys, so it'll still work for a fork — you just won't get my keys (obviously).

## Set up a new Mac

On a brand new machine, run:

```bash
curl -fsSL https://raw.githubusercontent.com/christory644/macDots/main/scripts/bootstrap.sh | bash
```

That single command:

1. Installs Xcode Command Line Tools
2. Clones this repo via HTTPS (no SSH keys needed)
3. Installs Nix via Lix (recommended by nix-darwin)
4. Decrypts SSH keys from `secrets/` (prompts for passphrase)
5. Switches the repo remote from HTTPS to SSH
6. Builds and activates nix-darwin (installs everything)
7. Installs the default Rust toolchain via rustup
8. Clones all repos listed in `repos.yml`

After bootstrap, open a new terminal and run `rebuild` to verify.

### Post-bootstrap

```bash
# Re-auth with Google Cloud
gcloud auth login
gcloud auth application-default login

# Install Node version(s) via mise
mise use -g node@24

# All future config changes
rebuild
```

## What's managed

| Layer | Tool | Manages |
|-------|------|---------|
| System | nix-darwin | CLI packages, system preferences, fonts, shells, trackpad, keyboard |
| GUI Apps | nix-homebrew | Homebrew casks + formulas (terminals, browsers, AI tools, etc.) |
| User Config | home-manager | Shell (zsh), git, SSH, tmux, starship prompt, terminal configs |
| Editor | NixVim | Neovim with LSP, treesitter, DAP debugging, telescope, etc. |
| Secrets | age | SSH keys + private config encrypted in repo, decrypted on bootstrap |
| Repos | repos.yml | Public repos cloned to ~/repos/ (private repos in gitignored repos-private.yml) |
| Fonts | home-manager | Nerd Fonts via nixpkgs + licensed fonts symlinked from private repo |

### System settings managed by nix-darwin

- **Dock** — autohide, magnification, no recents, no MRU spaces
- **Finder** — column view, show hidden files, path bar, no desktop icons
- **Keyboard** — fastest repeat rate, no press-and-hold (key repeat everywhere)
- **Trackpad** — tap to click, high tracking speed, force click
- **Menu bar** — clock format, battery %, Bluetooth, Focus, Now Playing
- **Global** — dark mode, always-show scroll bars, all auto-correct disabled, save to disk by default
- **Siri** — disabled
- **Desktop** — wallpaper rotation from `~/repos/wallpapers`

### Languages and runtimes

| Language | Managed by | Notes |
|----------|-----------|-------|
| Go, Python, Elixir, Zig, PHP | Nix | Declarative, pinned to nixpkgs |
| Java 17, Java 21 | Nix | JDKs + Maven + Gradle + Quarkus CLI |
| Rust | rustup (binary from Nix) | `rustup` installed by nix, toolchains managed by rustup |
| Node | mise (from Nix) | Universal version manager (also handles Java, Python, etc.) |
| Bun | Nix | Fast JS runtime |

### AI / ML tooling

| Tool | Managed by | Purpose |
|------|-----------|---------|
| Ollama | Nix | Local LLM server (MLX backend enabled) |
| mlx-lm | Homebrew | Apple MLX fine-tuning + inference |
| Claude Code | Homebrew cask | AI coding agent |
| Codex | Homebrew cask | AI coding agent |
| Gemini CLI | Homebrew | AI coding agent |
| OpenCode | Nix | AI coding agent |

## Day-to-day workflow

### Making changes

Edit the relevant `.nix` file, then rebuild:

```bash
nvim ~/repos/macDots/home/shell/zsh.nix

# Flakes only see committed/staged files
cd ~/repos/macDots && git add -A && git commit -m "add new alias"

rebuild
```

### Where to add things

| Want to add... | Edit this file |
|---|---|
| CLI tool (ripgrep, jq, etc.) | `hosts/macbook/default.nix` → `systemPackages` |
| GUI app (Slack, Discord, etc.) | `hosts/macbook/homebrew.nix` → `casks` |
| Homebrew formula (nvm, etc.) | `hosts/macbook/homebrew.nix` → `brews` |
| Neovim plugin | `home/nvim/plugins/` (new file + add to `default.nix` imports) |
| Shell alias | `home/shell/zsh.nix` → `shellAliases` |
| Git config | `home/git.nix` |
| SSH host | `home/ssh.nix` |
| Environment variable | `home/shell/zsh.nix` → `sessionVariables` |
| macOS system default | `hosts/macbook/default.nix` → `system.defaults` |
| tmux keybind or plugin | `home/tmux.nix` |
| New repo to track | `repos.yml` |

### Updating all dependencies

```bash
update   # alias for: nix flake update && rebuild
```

### Rotating SSH keys or updating private repos

```bash
# After generating new keys or editing repos-private.yml:
./scripts/encrypt-keys.sh   # re-encrypts everything with your passphrase
git add secrets/ && git commit -m "rotate secrets"
git push
```

## Structure

```
.
├── flake.nix                     # Entry point — all inputs and module wiring
├── flake.lock                    # Pinned dependency versions
├── repos.yml                    # Public repos to clone (committed)
├── repos-private.yml            # Private/work repos (gitignored, encrypted in secrets/)
├── secrets/                      # Age-encrypted SSH keys + private config
│   ├── christory644.age          # Personal SSH key
│   ├── christory644.pub.age
│   ├── chris-certifyos.age       # Work SSH key
│   ├── chris-certifyos.pub.age
│   └── repos-private.yml.age     # Private repo manifest
├── scripts/
│   ├── bootstrap.sh              # One-command setup for a fresh Mac
│   ├── encrypt-keys.sh           # Re-encrypt SSH keys after rotation
│   └── clone-repos.sh            # Clone all repos from repos.yml
├── hosts/macbook/
│   ├── default.nix               # System packages, macOS settings, fonts
│   └── homebrew.nix              # GUI casks + Homebrew formulas
├── home/
│   ├── default.nix               # Home-manager entry + font symlinks
│   ├── shell/
│   │   ├── zsh.nix               # Zsh config, aliases, Ollama env, integrations
│   │   └── starship.nix          # Starship prompt
│   ├── git.nix                   # Git config, delta diffs, identity management
│   ├── ssh.nix                   # SSH config (GitHub host aliases)
│   ├── tmux.nix                  # Tmux config + plugins
│   ├── vscode.nix                # VS Code settings + extensions
│   ├── ollama.nix                # Ollama LLM server config
│   ├── terminal/
│   │   ├── ghostty.nix           # cmux/Ghostty config
│   │   └── kitty.nix             # Kitty fallback config
│   ├── aerospace.toml            # AeroSpace window manager
│   └── nvim/                     # NixVim (full Neovim IDE)
│       ├── default.nix           # Options + plugin imports
│       ├── keymaps.nix           # General keybindings
│       ├── theme.nix             # Theme + transparency
│       └── plugins/              # LSP, treesitter, telescope, DAP, etc.
└── rollback-to-pre-nix.sh        # Emergency rollback script
```

## Terminal

**Primary:** cmux (Ghostty-based terminal with vertical tabs + AI agent notifications)
**Fallback:** Kitty

cmux reads `~/.config/ghostty/config` — managed by `home/terminal/ghostty.nix`.

**AeroSpace shortcut:** `alt+enter` opens a new cmux window.

## Editor (Neovim)

Leader key: `Space`

### Key bindings by prefix

| Prefix | Purpose | Examples |
|--------|---------|----------|
| `<leader>f` | Find (telescope) | `ff` find files, `fs` live grep, `fb` buffers |
| `<leader>b` | Buffers | `bn` next, `bp` prev, `bd` delete |
| `<leader>s` | Splits/sessions | `sv` vertical, `sh` horizontal, `ss` save session |
| `<leader>e` | Explorer | `ee` nvim-tree, `eo` oil, `ef` find in tree |
| `<leader>d` | Debug (DAP) | `db` breakpoint, `dc` continue, `du` toggle UI |
| `<leader>g` | Git | `gd` diffview, `gh` file history, `gl` lazygit |
| `<leader>h` | Hunks (gitsigns) | `hs` stage, `hr` reset, `hp` preview |
| `<leader>x` | Diagnostics | `xx` trouble toggle, `xw` workspace diags |
| `<leader>c` | Code | `ca` code action, `cr` rename |
| `<leader>u` | Undotree | Toggle visual undo history |
| `<leader>1-4` | Harpoon | Jump to harpooned file 1-4 |
| `g` | Go to | `gd` definition, `gr` references, `gi` implementation |
| `s` | Substitute | `ss` line, `S` to EOL |
| `-` | Oil | Open parent directory |

## tmux cheatsheet

Prefix key: `ctrl+a` (not the default `ctrl+b`)

### Sessions

| Keys | Action |
|------|--------|
| `prefix d` | Detach from session |
| `prefix s` | List sessions |
| `prefix $` | Rename session |
| `prefix (` / `)` | Previous / next session |

Or use **sesh** for smart session management: `sesh connect <project>`

### Windows (tabs)

| Keys | Action |
|------|--------|
| `prefix c` | New window |
| `prefix ,` | Rename window |
| `prefix n` / `p` | Next / previous window |
| `prefix 0-9` | Jump to window by number |
| `prefix &` | Kill window |

### Panes (splits)

| Keys | Action |
|------|--------|
| `prefix \|` | Vertical split |
| `prefix -` | Horizontal split |
| `prefix h/j/k/l` | Navigate panes (vim-style) |
| `prefix H/J/K/L` | Resize panes |
| `prefix z` | Toggle pane zoom (fullscreen) |
| `prefix x` | Kill pane |
| `prefix space` | Cycle layouts |

### Copy mode (vi-style)

| Keys | Action |
|------|--------|
| `prefix [` | Enter copy mode |
| `v` | Start selection |
| `y` | Copy selection |
| `prefix ]` | Paste |
| `/` | Search forward |
| `?` | Search backward |

### Plugins (auto-managed)

- **resurrect** — `prefix ctrl+s` save, `prefix ctrl+r` restore
- **continuum** — auto-saves every 10 seconds

## Git identity

- **Default:** Personal — Christopher Story / christory@pm.me
- **Work:** Auto-switches for CertifyOS repos via `hasconfig:remote.*.url` match
- **SSH keys:** Managed by home-manager (`home/ssh.nix`), encrypted in `secrets/`

## Secrets

API keys and tokens live in `~/repos/macDots/.zshenv_secrets` (git-ignored). Sourced automatically on shell startup.

## Rollback

```bash
# Quick: revert to previous nix-darwin generation
sudo darwin-rebuild --rollback

# Full: restore pre-Nix configs from backup
./rollback-to-pre-nix.sh
# Backups at: ~/.config-backup-pre-nix/
```
