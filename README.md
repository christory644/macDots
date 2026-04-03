# macDots

Declarative macOS configuration using **nix-darwin** + **home-manager** + **NixVim**.

> there are many others like it, but these are mine.

## What's managed

| Layer | Tool | Manages |
|-------|------|---------|
| System | nix-darwin | CLI packages, system preferences, fonts, shells |
| GUI Apps | nix-homebrew | Homebrew casks (cmux, kitty, aerospace, browsers, etc.) |
| User Config | home-manager | Shell (zsh), git, tmux, starship prompt, terminal configs |
| Editor | NixVim | Neovim with LSP, treesitter, DAP debugging, telescope, etc. |

## Prerequisites

1. macOS on Apple Silicon
2. [Nix via Lix installer](https://install.lix.systems) (recommended by nix-darwin)

## Setup

```bash
# 1. Install Nix via Lix
curl -sSf -L https://install.lix.systems/lix | sh -s -- install

# 2. Clone this repo
git clone git@github.com:christory644/macDots.git ~/repos/macDots
cd ~/repos/macDots

# 3. First build (darwin-rebuild doesn't exist yet)
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#macbook

# 4. Open a new terminal — everything should be configured
# 5. All future rebuilds:
rebuild   # alias for: sudo darwin-rebuild switch --flake ~/repos/macDots#macbook
```

## Day-to-day workflow

### Making changes

Edit the relevant `.nix` file, commit, then rebuild:

```bash
# Edit something...
nvim ~/repos/macDots/home/shell/zsh.nix

# Commit (flakes only see committed files!)
cd ~/repos/macDots && git add -A && git commit -m "add new alias"

# Apply
rebuild
```

### Where to add things

| Want to add... | Edit this file |
|---|---|
| CLI tool (ripgrep, jq, etc.) | `hosts/macbook/default.nix` → `systemPackages` |
| GUI app (Slack, Discord, etc.) | `hosts/macbook/homebrew.nix` → `casks` |
| Homebrew formula (nvm, php, etc.) | `hosts/macbook/homebrew.nix` → `brews` |
| Neovim plugin | `home/nvim/plugins/` (new file + add to `default.nix` imports) |
| Shell alias | `home/shell/zsh.nix` → `shellAliases` |
| Git alias | `home/git.nix` → `settings.alias` |
| Environment variable | `home/shell/zsh.nix` → `sessionVariables` |
| macOS system default | `hosts/macbook/default.nix` → `system.defaults` |
| tmux keybind or plugin | `home/tmux.nix` |

### Updating all dependencies

```bash
cd ~/repos/macDots
nix flake update   # updates flake.lock to latest nixpkgs, home-manager, etc.
rebuild
```

### Searching for packages

```bash
# Search nixpkgs
nix search nixpkgs <package-name>

# Or browse: https://search.nixos.org/packages
```

## Structure

```
.
├── flake.nix                     # Entry point — all inputs and module wiring
├── flake.lock                    # Pinned dependency versions
├── hosts/macbook/
│   ├── default.nix               # System packages, macOS settings, fonts
│   └── homebrew.nix              # GUI casks + Homebrew formulas
├── home/
│   ├── default.nix               # Home-manager entry + font symlinks
│   ├── shell/
│   │   ├── zsh.nix               # Zsh config, aliases, direnv, atuin, fzf
│   │   └── starship.nix          # Starship prompt (Night Owl theme)
│   ├── git.nix                   # Git config, delta diffs, identity management
│   ├── tmux.nix                  # Tmux config + Night Owl theme
│   ├── terminal/
│   │   ├── ghostty.nix           # cmux/Ghostty config (Night Owl)
│   │   └── kitty.nix             # Kitty fallback config
│   ├── aerospace.toml            # AeroSpace window manager
│   └── nvim/                     # NixVim (full Neovim IDE)
│       ├── default.nix           # Options + plugin imports
│       ├── keymaps.nix           # General keybindings
│       ├── theme.nix             # Night Owl + transparency
│       └── plugins/
│           ├── alpha.nix         # Dashboard (cowsays)
│           ├── cmp.nix           # Completion (nvim-cmp + LuaSnip)
│           ├── dap.nix           # Debug adapters (Go, Python)
│           ├── diffview.nix      # Side-by-side git diffs
│           ├── editor.nix        # Oil, flash, surround, nvim-tree, etc.
│           ├── formatting.nix    # Conform + nvim-lint
│           ├── git.nix           # Gitsigns + lazygit
│           ├── harpoon.nix       # Quick file switching
│           ├── lsp.nix           # 16+ LSP servers (no Mason)
│           ├── telescope.nix     # Fuzzy finder
│           ├── treesitter.nix    # Syntax highlighting (29 grammars)
│           ├── ui.nix            # Lualine, bufferline, which-key
│           ├── undotree.nix      # Visual undo history
│           └── utils.nix         # Trouble, todo-comments, auto-session
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
| `<leader>ha` | Harpoon add | Add current file to harpoon |
| `<leader>hh` | Harpoon menu | Toggle harpoon quick menu |
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

## Key tools

| Tool | Purpose | Invoke |
|------|---------|--------|
| **direnv** | Per-project env vars — auto-loads `.envrc` on cd | Automatic |
| **atuin** | Better shell history search | `ctrl+r` |
| **mise** | Universal version manager (node, java, python...) | `mise use node@20` |
| **sesh** | Smart tmux session manager | `sesh connect` |
| **lazygit** | TUI git client | `lazygit` or `<leader>gl` in nvim |
| **lazydocker** | TUI Docker manager | `lazydocker` |
| **delta** | Syntax-highlighted git diffs | Automatic (git pager) |
| **glow** | Terminal markdown viewer | `glow README.md` |
| **telescope** | Fuzzy find anything in nvim | `<leader>ff`, `<leader>fs` |
| **harpoon** | Quick-switch between files in nvim | `<leader>ha` add, `<leader>1-4` jump |

## Git identity

- **Default:** Personal — Christopher Story / christory@pm.me
- **Work:** Auto-switches for repos under `~/repos/certifyos/` via `includeIf`
- **SSH keys:** Managed separately via `~/.ssh/config` (not in this repo)

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
