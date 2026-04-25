#!/usr/bin/env bash
#
# bootstrap.sh — one-shot setup for a fresh Mac
#
# Usage (run this on a brand new machine):
#   curl -fsSL https://raw.githubusercontent.com/christory644/macDots/main/scripts/bootstrap.sh | bash
#
set -euo pipefail

DOTS="$HOME/repos/macDots"
HOSTNAME="macbook"

echo "==> macDots bootstrap"

# ── Xcode Command Line Tools (git, clang, etc.) ─────────────────────
if ! xcode-select -p &>/dev/null; then
  echo "==> Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "    Press any key after the installation finishes."
  read -r -n 1
fi

# ── Clone macDots (HTTPS — no SSH keys needed) ───────────────────────
if [ ! -d "$DOTS" ]; then
  echo "==> Cloning macDots..."
  mkdir -p "$HOME/repos"
  git clone https://github.com/christory644/macDots.git "$DOTS"
fi

# ── Nix ──────────────────────────────────────────────────────────────
if ! command -v nix &>/dev/null; then
  echo "==> Installing Nix (Determinate Systems installer)..."
  curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix | sh -s -- install
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# ── SSH keys (decrypt from repo — needed before cloning other repos) ─
if [ -f "$DOTS/secrets/christory644.age" ]; then
  if [ ! -f "$HOME/.ssh/christory644" ] || [ ! -f "$HOME/.ssh/chris-certifyos" ]; then
    echo "==> Decrypting SSH keys (enter the passphrase you used to encrypt them)"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    AGE="nix run nixpkgs#age --"

    for name in christory644 chris-certifyos; do
      $AGE -d -o "$HOME/.ssh/${name}" "$DOTS/secrets/${name}.age"
      chmod 600 "$HOME/.ssh/${name}"
      $AGE -d -o "$HOME/.ssh/${name}.pub" "$DOTS/secrets/${name}.pub.age"
      chmod 644 "$HOME/.ssh/${name}.pub"
    done

    echo "==> SSH keys decrypted and installed."
  fi

  # Switch macDots remote to SSH (now that keys exist)
  CURRENT_REMOTE="$(git -C "$DOTS" remote get-url origin)"
  if [[ "$CURRENT_REMOTE" == https://* ]]; then
    echo "==> Switching macDots remote from HTTPS to SSH..."
    git -C "$DOTS" remote set-url origin git@github.com-christory644:christory644/macDots.git
  fi
else
  echo "==> Skipping SSH key setup (no encrypted keys found — this is expected if you forked this repo)"
fi

# ── First nix-darwin build ───────────────────────────────────────────
echo "==> Building nix-darwin configuration..."
nix build "$DOTS#darwinConfigurations.$HOSTNAME.system" --extra-experimental-features "nix-command flakes"

echo "==> Activating nix-darwin (first run)..."
"$DOTS/result/sw/bin/darwin-rebuild" switch --flake "$DOTS#$HOSTNAME"

# ── Rust toolchain (rustup is installed by nix, but needs initial setup) ──
if ! command -v rustc &>/dev/null; then
  echo "==> Installing default Rust toolchain via rustup..."
  rustup-init -y --no-modify-path
fi

# ── Clone all repos from manifest (uses SSH — keys are decrypted) ────
if [ -f "$HOME/.ssh/christory644" ]; then
  echo "==> Cloning repos from repos.yml..."
  "$DOTS/scripts/clone-repos.sh"
else
  echo "==> Skipping repo cloning (no SSH keys — clone repos manually or set up your own repos.yml)"
fi

# ── Post-setup verification ──────────────────────────────────────────
echo ""
echo "==> Bootstrap complete! Verify with:"
echo "    - Open a new terminal (shell config is now managed by nix)"
echo "    - Run: rebuild"
echo ""
echo "    After bootstrap, re-auth with gcloud:"
echo "    - gcloud auth login"
echo "    - gcloud auth application-default login"
echo ""
echo "    Tools not managed by nix (installed above):"
echo "    - Rust toolchains: managed by rustup (rustup update)"
echo "    - Node versions: managed by nvm (nvm install <version>)"
