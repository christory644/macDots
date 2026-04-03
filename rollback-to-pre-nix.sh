#!/usr/bin/env bash
set -euo pipefail

# Emergency rollback script — restores pre-Nix configuration
# Run this if the Nix migration breaks something critical

BACKUP_DIR="$HOME/.config-backup-pre-nix"
DOTS_HOME="$HOME/repos/macDots"

echo "=== macDots Pre-Nix Rollback ==="
echo ""

if [ ! -d "$BACKUP_DIR" ]; then
  echo "ERROR: Backup directory not found at $BACKUP_DIR"
  echo "Cannot rollback without backups."
  exit 1
fi

echo "This will:"
echo "  1. Attempt nix-darwin rollback (if available)"
echo "  2. Remove Nix-managed config symlinks"
echo "  3. Restore original configs from backup"
echo "  4. Re-link macDots symlinks"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# Step 1: Try nix-darwin rollback
echo ""
echo "--- Step 1: nix-darwin rollback ---"
if command -v darwin-rebuild &> /dev/null; then
  echo "Running darwin-rebuild --rollback..."
  darwin-rebuild --rollback || echo "darwin-rebuild rollback failed (may not have a previous generation)"
else
  echo "darwin-rebuild not found, skipping."
fi

# Step 2: Remove potentially conflicting Nix-managed files
echo ""
echo "--- Step 2: Removing Nix-managed config files ---"
for dir in nvim zsh starship kitty aerospace bat zellij ghostty; do
  target="$HOME/.config/$dir"
  if [ -L "$target" ] || [ -d "$target" ]; then
    echo "  Removing $target"
    rm -rf "$target"
  fi
done

# Remove home-dir level configs that home-manager may have placed
for file in .zshenv .tmux.conf .gitconfig; do
  target="$HOME/$file"
  if [ -L "$target" ] || [ -f "$target" ]; then
    echo "  Removing $target"
    rm -f "$target"
  fi
done

# Step 3: Restore from backup
echo ""
echo "--- Step 3: Restoring configs from backup ---"
for dir in nvim zsh starship kitty aerospace bat zellij; do
  if [ -d "$BACKUP_DIR/$dir" ] || [ -L "$BACKUP_DIR/$dir" ]; then
    echo "  Restoring ~/.config/$dir"
    cp -a "$BACKUP_DIR/$dir" "$HOME/.config/$dir"
  fi
done

if [ -f "$BACKUP_DIR/.zshenv" ]; then
  echo "  Restoring ~/.zshenv"
  cp "$BACKUP_DIR/.zshenv" "$HOME/.zshenv"
fi

if [ -f "$BACKUP_DIR/.tmux.conf" ]; then
  echo "  Restoring ~/.tmux.conf"
  cp "$BACKUP_DIR/.tmux.conf" "$HOME/.tmux.conf"
fi

if [ -f "$BACKUP_DIR/.gitconfig" ]; then
  echo "  Restoring ~/.gitconfig"
  cp "$BACKUP_DIR/.gitconfig" "$HOME/.gitconfig"
fi

# Step 4: Re-establish macDots symlinks
echo ""
echo "--- Step 4: Re-linking macDots symlinks ---"
if [ -d "$DOTS_HOME/config" ]; then
  for dir in aerospace bat kitty nvim starship zellij zsh; do
    if [ -d "$DOTS_HOME/config/$dir" ]; then
      ln -sf "$DOTS_HOME/config/$dir" "$HOME/.config/$dir" 2>/dev/null && \
        echo "  Linked ~/.config/$dir → $DOTS_HOME/config/$dir" || \
        echo "  WARNING: Could not link $dir (may already exist)"
    fi
  done

  if [ -f "$DOTS_HOME/.zshenv" ]; then
    ln -sf "$DOTS_HOME/.zshenv" "$HOME/.zshenv" && \
      echo "  Linked ~/.zshenv" || echo "  WARNING: Could not link .zshenv"
  fi
fi

# Step 5: Restore Homebrew if needed
echo ""
echo "--- Step 5: Homebrew ---"
if [ -f "$BACKUP_DIR/Brewfile.snapshot" ]; then
  echo "  Homebrew snapshot available at: $BACKUP_DIR/Brewfile.snapshot"
  echo "  To restore: brew bundle --file=$BACKUP_DIR/Brewfile.snapshot"
else
  echo "  No Homebrew snapshot found."
fi

echo ""
echo "=== Rollback complete ==="
echo ""
echo "Next steps:"
echo "  1. Open a new terminal window to test"
echo "  2. Verify: nvim, git, tmux, shell prompt all work"
echo "  3. If using git, you can also: cd $DOTS_HOME && git checkout backup/pre-nix-migration"
echo ""
