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
  # Opens Apple's GUI installer. Don't wait on a keypress: under `curl … | bash`
  # stdin is the script itself, so `read` never sees the keyboard. Poll instead.
  xcode-select --install || true
  echo "    Waiting for Xcode Command Line Tools to finish installing..."
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  echo "    Xcode Command Line Tools installed."
fi

# ── Clone macDots (HTTPS — no SSH keys needed) ───────────────────────
if [ ! -d "$DOTS" ]; then
  echo "==> Cloning macDots..."
  mkdir -p "$HOME/repos"
  git clone https://github.com/christory644/macDots.git "$DOTS"
fi

# ── Nix ──────────────────────────────────────────────────────────────
if ! command -v nix &>/dev/null; then
  echo "==> Installing Nix via Lix (recommended by nix-darwin)..."
  curl -sSf -L https://install.lix.systems/lix | sh -s -- install
fi

# Put nix on PATH for THIS shell — unconditionally, not just after a fresh
# install. `curl … | bash` is a non-interactive shell that never sources
# /etc/zshrc, so on a re-run (nix already installed) it still won't be on
# PATH until we source the daemon profile here.
# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null \
  || . /nix/var/nix/profiles/default/etc/profile.d/nix.sh 2>/dev/null \
  || true

# Enable flakes process-wide so every `nix` call below works regardless of
# the machine's default nix.conf (a fresh install has none yet).
export NIX_CONFIG="extra-experimental-features = nix-command flakes"

if ! command -v nix &>/dev/null; then
  echo "!! Nix is installed but not on PATH in this shell." >&2
  echo "   Open a new terminal and re-run this script, or first run:" >&2
  echo "     . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" >&2
  exit 1
fi

# ── Decrypt secrets (SSH keys, private repo manifest) ────────────────
if [ -f "$DOTS/secrets/age-identity.txt" ]; then
  AGE_PKG="$(nix build nixpkgs#age --no-link --print-out-paths)"
  AGE="${AGE_PKG}/bin/age"
  IDENTITY="$DOTS/secrets/age-identity.txt"

  # Decrypt the age identity first (prompts for passphrase once)
  if [ ! -f /tmp/age-identity-decrypted ]; then
    echo "==> Enter passphrase to decrypt secrets (one time only)"
    $AGE -d -o /tmp/age-identity-decrypted "$IDENTITY"
  fi

  # Decrypt SSH keys
  if [ ! -f "$HOME/.ssh/christory644" ] || [ ! -f "$HOME/.ssh/chris-certifyos" ]; then
    echo "==> Decrypting SSH keys..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    for name in christory644 chris-certifyos; do
      $AGE -d -i /tmp/age-identity-decrypted -o "$HOME/.ssh/${name}" "$DOTS/secrets/${name}.age"
      chmod 600 "$HOME/.ssh/${name}"
      $AGE -d -i /tmp/age-identity-decrypted -o "$HOME/.ssh/${name}.pub" "$DOTS/secrets/${name}.pub.age"
      chmod 644 "$HOME/.ssh/${name}.pub"
    done

    echo "==> SSH keys decrypted and installed."
  fi

  # Decrypt private repo manifest
  if [ -f "$DOTS/secrets/repos-private.yml.age" ] && [ ! -f "$DOTS/repos-private.yml" ]; then
    echo "==> Decrypting private repo manifest..."
    $AGE -d -i /tmp/age-identity-decrypted -o "$DOTS/repos-private.yml" "$DOTS/secrets/repos-private.yml.age"
  fi

  # Clean up decrypted identity
  rm -f /tmp/age-identity-decrypted

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
nix build "$DOTS#darwinConfigurations.$HOSTNAME.system"

echo "==> Activating nix-darwin (first run)..."
# First-run activation writes /etc, /run/current-system and loads launchd
# daemons — it needs root. Without sudo the switch fails on permissions and
# home-manager user activation (shell aliases, tmux/cmux, etc.) never runs.
sudo "$DOTS/result/sw/bin/darwin-rebuild" switch --flake "$DOTS#$HOSTNAME"

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
echo "    - Node versions: managed by mise (mise use -g node@24)"
