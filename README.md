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
2. [Nix](https://determinate.systems/nix-installer/) installed with flakes enabled

## Setup

```bash
# 1. Install Nix (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Clone this repo
git clone git@github.com:christory644/macDots.git ~/repos/macDots
cd ~/repos/macDots

# 3. Build and apply
darwin-rebuild switch --flake .#macbook

# 4. Open a new terminal — everything should be configured
```

## Applying changes

After editing any `.nix` file:

```bash
darwin-rebuild switch --flake .#macbook
```

## Updating dependencies

```bash
nix flake update
darwin-rebuild switch --flake .#macbook
```

## Structure

```
├── flake.nix                  # Entry point
├── hosts/macbook/
│   ├── default.nix            # System packages & settings
│   └── homebrew.nix           # GUI app casks
├── home/
│   ├── default.nix            # Home-manager entry
│   ├── shell/                 # Zsh + Starship
│   ├── git.nix                # Git config + identity management
│   ├── tmux.nix               # Tmux + Night Owl theme
│   ├── terminal/              # Ghostty/cmux + Kitty configs
│   ├── aerospace.toml         # Window manager
│   └── nvim/                  # NixVim (Neovim IDE)
│       ├── default.nix        # Options + imports
│       ├── keymaps.nix        # All keybindings
│       ├── theme.nix          # Night Owl colorscheme
│       └── plugins/           # One file per plugin group
└── rollback-to-pre-nix.sh     # Emergency rollback
```

## Terminal

Primary: **cmux** (Ghostty-based terminal built for AI coding agents)
Fallback: **Kitty**

cmux reads `~/.config/ghostty/config` for visual settings. The config is managed by `home/terminal/ghostty.nix`.

## Editor (Neovim)

Leader key: `Space`

Key bindings are organized by prefix:
- `<leader>f` — Find (telescope)
- `<leader>b` — Buffer management
- `<leader>s` — Splits, sessions
- `<leader>e` — Explorer (nvim-tree, oil)
- `<leader>d` — Debug (DAP)
- `<leader>g` — Git
- `<leader>h` — Hunks (gitsigns)
- `<leader>x` — Trouble/diagnostics
- `<leader>c` — Code actions, symbols
- `g` — Go to (definition, references, etc.)

## Git Identity

- **Default:** Personal identity (configured in `home/git.nix`)
- **Work repos:** Automatically uses work identity for repos under `~/repos/certifyos/` via `includeIf`
- **SSH keys:** Managed separately via `~/.ssh/config` (not in this repo)

## Secrets

API keys and tokens are stored in `~/repos/macDots/.zshenv_secrets` (git-ignored). The shell config sources this file on startup.

## Rollback

If something breaks:

```bash
# Quick: revert to previous nix-darwin generation
darwin-rebuild --rollback

# Full: restore pre-Nix configs
./rollback-to-pre-nix.sh
```
