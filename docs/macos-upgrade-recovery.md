# Recovering nix after a macOS upgrade

Written 2026-10-19, before upgrading from macOS 26.5.2. Read this with `cat` —
it is deliberately plain text in the repo, because the thing it fixes is nix
being unavailable.

## What breaks, and when

A **minor** update (26.5.2 → 26.7.1) is usually harmless. A **major** one
(26.x → 27.0) breaks nix on macOS in one of two ways. Check which you did:

```
sw_vers -productVersion
```

### 1. /etc/zshrc replaced — likely, annoying, easy

nix-darwin owns these as symlinks:

```
/etc/zshrc    -> /etc/static/zshrc
/etc/bashrc   -> /etc/static/bashrc
/etc/zshenv   -> /etc/static/zshenv
/etc/zprofile -> /etc/static/zprofile
```

A major upgrade replaces them with Apple's own regular files. Your PATH then
loses the nix entries and nothing nix-installed is on it.

**Symptom:** a new terminal says `command not found` for nix, git, nvim, claude
— basically everything, because they all come from nix.

**Check:**
```
ls -l /etc/zshrc        # should say "-> /etc/static/zshrc"
```

**Fix** — darwin-rebuild recreates the symlinks, and it can be run by absolute
path even when PATH is broken:
```
sudo /run/current-system/sw/bin/darwin-rebuild switch --flake ~/repos/macDots
```
If it refuses because Apple's file is in the way, move it aside first:
```
sudo mv /etc/zshrc /etc/zshrc.apple-upgrade
sudo mv /etc/bashrc /etc/bashrc.apple-upgrade
```
then re-run. Open a new terminal afterwards — the current one keeps the old env.

### 2. /nix does not mount — rarer, and total

`/nix` is a separate APFS volume, mounted at boot because of one line in
`/etc/synthetic.conf`. Some major upgrades discard that file.

**Symptom:** `/nix` is empty or missing, and `/run/current-system` does not
exist. Nothing above will work.

**Check:**
```
mount | grep /nix          # expect: /dev/diskNsN on /nix (apfs, ...)
cat /etc/synthetic.conf    # expect a line reading: nix
```

**Fix:**
```
printf 'nix\n' | sudo tee /etc/synthetic.conf
sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t
```
Then reboot. If `/nix` is still empty, the volume itself may need remounting —
`diskutil list` will show an APFS volume named `Nix Store`; it has not been
erased, only unmounted.

## Other things an upgrade resets

- **Accessibility permission for AeroSpace.** macOS ties it to the binary path.
  Windows stop responding to keybindings and it looks like a bad config.
  Re-grant in System Settings → Privacy & Security → Accessibility.
- **Full Disk Access / Screen Recording** for terminals and Raycast.
- **The per-power-source sleep policy** is written with `pmset` at activation,
  so a rebuild restores it. Verify with `pmset -g custom`.

## Order to check after rebooting

1. `mount | grep /nix` — the volume is there
2. `ls -l /etc/zshrc` — still a symlink
3. new terminal, `which nix git claude` — all under /run/current-system
4. `pmset -g custom` — displaysleep 0 on AC, 30 on battery
5. AeroSpace keybindings respond; if not, re-grant Accessibility
