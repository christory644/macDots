#!/usr/bin/env bash
#
# bootstrap.sh — one-shot setup for a fresh Mac
#
# Usage:
#   git clone git@github.com:<you>/macDots.git ~/repos/macDots
#   cd ~/repos/macDots
#   ./scripts/bootstrap.sh
#
set -euo pipefail

DOTS="$HOME/repos/macDots"
HOSTNAME="macbook"

echo "==> macDots bootstrap"

# ── SSH keys (decrypt from repo) ─────────────────────────────────────
if [ ! -f "$HOME/.ssh/christory644" ] || [ ! -f "$HOME/.ssh/chris-certifyos" ]; then
  echo "==> Decrypting SSH keys (enter the passphrase you used to encrypt them)"
  mkdir -p "$HOME/.ssh"

  AGE="age"
  command -v age &>/dev/null || AGE="nix run nixpkgs#age --"

  for name in christory644 chris-certifyos; do
    $AGE -d -o "$HOME/.ssh/${name}" "$DOTS/secrets/${name}.age"
    chmod 600 "$HOME/.ssh/${name}"
    $AGE -d -o "$HOME/.ssh/${name}.pub" "$DOTS/secrets/${name}.pub.age"
    chmod 644 "$HOME/.ssh/${name}.pub"
  done

  echo "==> SSH keys decrypted and installed."
fi

# ── Xcode Command Line Tools (git, clang, etc.) ─────────────────────
if ! xcode-select -p &>/dev/null; then
  echo "==> Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "    Press any key after the installation finishes."
  read -r -n 1
fi

# ── Nix ──────────────────────────────────────────────────────────────
if ! command -v nix &>/dev/null; then
  echo "==> Installing Nix (Determinate Systems installer)..."
  curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix | sh -s -- install
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# ── First nix-darwin build ───────────────────────────────────────────
echo "==> Building nix-darwin configuration..."
nix build "$DOTS#darwinConfigurations.$HOSTNAME.system" --extra-experimental-features "nix-command flakes"

echo "==> Activating nix-darwin (first run)..."
./result/sw/bin/darwin-rebuild switch --flake "$DOTS#$HOSTNAME"

# ── Rust toolchain (rustup is installed by nix, but needs initial setup) ──
if ! command -v rustc &>/dev/null; then
  echo "==> Installing default Rust toolchain via rustup..."
  rustup-init -y --no-modify-path
fi

# ── Clone all repos from manifest ────────────────────────────────────
echo "==> Cloning repos from repos.yml..."
"$DOTS/scripts/clone-repos.sh"

# ── Post-setup verification ──────────────────────────────────────────
echo ""
echo "==> Bootstrap complete! Verify with:"
echo "    - Open a new terminal (shell config is now managed by nix)"
echo "    - Run: rebuild"
echo ""
echo "    Tools not managed by nix (installed above):"
echo "    - Rust toolchains: managed by rustup (rustup update)"
echo "    - Node versions: managed by nvm (nvm install <version>)"
