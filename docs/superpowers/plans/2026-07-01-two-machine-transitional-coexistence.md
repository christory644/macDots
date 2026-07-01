# Two-Machine Transitional Coexistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the old (`christopherstory`) and new (`christory`) Macs build and run concurrently from one flake without competing, with a one-line teardown seam once the old Mac is wiped.

**Architecture:** Replace the single hardcoded `darwinConfigurations.macbook` with a `mkHost { hostname, username }` helper that emits two entries sharing every module; only `hostname` and `username` differ, threaded through `specialArgs`/`extraSpecialArgs`. Hostname becomes per-host (fixes the `macbook.local` collision); the `rebuild` alias becomes per-host; Universal Control is disabled via a home-manager activation step (per-user ByHost write).

**Tech Stack:** Nix flakes, nix-darwin, home-manager. No test framework — correctness is gated by `nix eval` (evaluates cleanly) and targeted value checks, which stand in for unit tests here.

## Global Constraints

- Machine identities (exact): old = username `christopherstory`, hostname `macbook` (being wiped); new = username `christory`, hostname `christoryCertifyOSMacbook` (keeper).
- No macOS user-account renames — each hostname maps to the account that already exists on that box.
- Spec: `docs/superpowers/specs/2026-07-01-two-machine-transitional-coexistence-design.md`.
- Push to `main` is gated in this environment; the user pushes manually.
- After the code lands, the **old Mac must `rebuild`** to re-pin `christopherstory` (its working tree currently carries the global `christory` flip from commit 3de5095).
- **New-Mac rollout ordering (footgun):** the new machine's hostname is still `macbook`, so its first post-pull switch MUST be the explicit `--flake .#christoryCertifyOSMacbook`, never plain `rebuild`.

## File Structure

- `flake.nix` — MODIFY: `mkHost` helper + two `darwinConfigurations` entries; thread `hostname`.
- `hosts/macbook/default.nix` — MODIFY: accept `hostname`; set `hostName`/`localHostName`/`computerName` from it.
- `home/shell/zsh.nix` — MODIFY: accept `hostname`; per-host `rebuild`/`update` aliases.
- `home/universal-control.nix` — CREATE: home-manager activation disabling Universal Control.
- `home/default.nix` — MODIFY: import `./universal-control.nix`.

---

### Task 1: Parameterize the flake into two hosts (`mkHost`)

**Files:**
- Modify: `flake.nix` (the `outputs` `let … in { darwinConfigurations… }` block)

**Interfaces:**
- Consumes: nothing new.
- Produces: `darwinConfigurations.macbook` and `darwinConfigurations.christoryCertifyOSMacbook`; `hostname` (string) available in each host's nix-darwin `specialArgs` and home-manager `extraSpecialArgs`.

- [ ] **Step 1: Replace the single-host block with `mkHost` + two entries**

In `flake.nix`, replace everything from `let` (line ~31) through the closing of `darwinConfigurations.${hostname}` (the `};` before the final `};` at line ~74) with:

```nix
    let
      # Transitional two-machine setup — see
      # docs/superpowers/specs/2026-07-01-two-machine-transitional-coexistence-design.md
      # Both machines build from one flake; only hostname + username differ.
      # TEARDOWN: delete the `macbook` (old) entry once that Mac is wiped.
      mkHost = { hostname, username }: nix-darwin.lib.darwinSystem {
        specialArgs = { inherit username hostname nixvim nix-vscode-extensions; };
        modules = [
          # Overlay: fix packages that fail to build from source on macOS
          {
            nixpkgs.overlays = [
              (final: prev: {
                direnv = prev.direnv.overrideAttrs (old: {
                  doCheck = false;  # test suite hangs on macOS (checkPhase >1hr)
                });
              })
            ];
          }

          ./hosts/macbook/default.nix
          ./hosts/macbook/homebrew.nix

          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = false;
              user = username;
              autoMigrate = true;
            };
          }

          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-bak";
              extraSpecialArgs = { inherit username hostname nixvim nix-vscode-extensions; };
              users.${username} = import ./home/default.nix;
            };
          }
        ];
      };
    in
    {
      darwinConfigurations = {
        # OLD machine — wiped after migration; delete this entry at teardown.
        macbook = mkHost {
          hostname = "macbook";
          username = "christopherstory";
        };

        # NEW machine — the keeper / canonical config.
        christoryCertifyOSMacbook = mkHost {
          hostname = "christoryCertifyOSMacbook";
          username = "christory";
        };
      };
    };
```

(The old `username`/`hostname` `let` bindings are removed — they're now per-host arguments to `mkHost`.)

- [ ] **Step 2: Verify both hosts evaluate**

Run:
```bash
nix eval .#darwinConfigurations.macbook.system.drvPath
nix eval .#darwinConfigurations.christoryCertifyOSMacbook.system.drvPath
```
Expected: each prints a `/nix/store/…-darwin-system-*.drv` path (no eval errors).

- [ ] **Step 3: Commit**

```bash
git add flake.nix
git commit -m "refactor: parameterize flake into two hosts via mkHost"
```

---

### Task 2: Per-host hostname in `hosts/macbook/default.nix`

**Files:**
- Modify: `hosts/macbook/default.nix:1` (module args), `hosts/macbook/default.nix:197` (`networking.hostName`)

**Interfaces:**
- Consumes: `hostname` (string) from `specialArgs` (Task 1).
- Produces: `networking.hostName`/`localHostName`/`computerName` all equal to the per-host `hostname`.

- [ ] **Step 1: Show the current (wrong) value — the "failing test"**

Run:
```bash
nix eval --raw .#darwinConfigurations.christoryCertifyOSMacbook.config.networking.hostName
```
Expected right now: `macbook` (wrong — both hosts still share the hardcoded name).

- [ ] **Step 2: Accept `hostname` in the module args**

Change `hosts/macbook/default.nix:1` from:
```nix
{ pkgs, username, ... }:
```
to:
```nix
{ pkgs, username, hostname, ... }:
```

- [ ] **Step 3: Drive the three name fields from `hostname`**

Replace `hosts/macbook/default.nix:197`:
```nix
  networking.hostName = "macbook";
```
with:
```nix
  networking.hostName = hostname;
  networking.localHostName = hostname;   # Bonjour .local name
  networking.computerName = hostname;    # friendly name in Sharing/Finder
```

- [ ] **Step 4: Verify each host now reports its own hostname**

Run:
```bash
nix eval --raw .#darwinConfigurations.christoryCertifyOSMacbook.config.networking.hostName
nix eval --raw .#darwinConfigurations.macbook.config.networking.hostName
```
Expected: `christoryCertifyOSMacbook` and `macbook` respectively.

- [ ] **Step 5: Commit**

```bash
git add hosts/macbook/default.nix
git commit -m "feat: per-host hostname (hostName/localHostName/computerName)"
```

---

### Task 3: Per-host `rebuild`/`update` aliases in `home/shell/zsh.nix`

**Files:**
- Modify: `home/shell/zsh.nix` (module args near line 1-3; aliases at lines 164 and 167)

**Interfaces:**
- Consumes: `hostname` (string) from home-manager `extraSpecialArgs` (Task 1).
- Produces: `rebuild`/`update` aliases that target `-H ${hostname}`.

- [ ] **Step 1: Show the current (wrong) alias — the "failing test"**

Run:
```bash
nix eval --raw .#darwinConfigurations.christoryCertifyOSMacbook.config.home-manager.users.christory.programs.zsh.shellAliases.rebuild
```
Expected right now: `nh darwin switch ~/repos/macDots -H macbook` (wrong host).

- [ ] **Step 2: Accept `hostname` in the module args**

In `home/shell/zsh.nix`, add `hostname` to the function arguments. Change:
```nix
{
  pkgs,
  lib,
```
to:
```nix
{
  pkgs,
  lib,
  hostname,
```

- [ ] **Step 3: Make the aliases per-host**

Replace `home/shell/zsh.nix:164`:
```nix
      rebuild = "nh darwin switch ~/repos/macDots -H macbook";
```
with:
```nix
      rebuild = "nh darwin switch ~/repos/macDots -H ${hostname}";
```

Replace `home/shell/zsh.nix:167`:
```nix
      update = "nix flake update --flake ~/repos/macDots && nh darwin switch ~/repos/macDots -H macbook";
```
with:
```nix
      update = "nix flake update --flake ~/repos/macDots && nh darwin switch ~/repos/macDots -H ${hostname}";
```

- [ ] **Step 4: Verify the alias is now per-host**

Run:
```bash
nix eval --raw .#darwinConfigurations.christoryCertifyOSMacbook.config.home-manager.users.christory.programs.zsh.shellAliases.rebuild
nix eval --raw .#darwinConfigurations.macbook.config.home-manager.users.christopherstory.programs.zsh.shellAliases.rebuild
```
Expected: `nh darwin switch ~/repos/macDots -H christoryCertifyOSMacbook` and `… -H macbook`.

- [ ] **Step 5: Commit**

```bash
git add home/shell/zsh.nix
git commit -m "feat: per-host rebuild/update aliases"
```

---

### Task 4: Disable Universal Control via home-manager activation

**Files:**
- Create: `home/universal-control.nix`
- Modify: `home/default.nix` (imports list, lines ~4-24)

**Interfaces:**
- Consumes: nothing new (uses `lib`).
- Produces: `home.activation.disableUniversalControl`.

- [ ] **Step 1: Create the module**

Create `home/universal-control.nix`:
```nix
{ lib, ... }:

# Disable Universal Control so the pointer/keyboard don't cross to a nearby Mac
# signed into the same Apple ID. This is a per-user ByHost preference (verified
# 2026-07-01), so it CANNOT go through nix-darwin's system.defaults, which writes
# the (nonexistent) global domain. home-manager activation runs as the user, so
# `defaults -currentHost write` lands in the right ByHost plist
# (~/Library/Preferences/ByHost/com.apple.universalcontrol.<UUID>.plist).
# The `Disable` key is undocumented but confirmed honored on macOS 26 (Tahoe):
# after the write the cursor stopped crossing between machines, no re-login needed.
{
  home.activation.disableUniversalControl =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run /usr/bin/defaults -currentHost write com.apple.universalcontrol Disable -bool true
    '';
}
```

- [ ] **Step 2: Import it**

In `home/default.nix`, add `./universal-control.nix` to the `imports` list (e.g. after `./syncthing.nix`):
```nix
    ./syncthing.nix
    ./universal-control.nix
  ];
```

- [ ] **Step 3: Verify it evaluates**

Run:
```bash
nix eval .#darwinConfigurations.christoryCertifyOSMacbook.system.drvPath
nix eval .#darwinConfigurations.macbook.system.drvPath
```
Expected: both print a `.drv` path (the whole system, including the new activation script, evaluates).

- [ ] **Step 4: Commit**

```bash
git add home/universal-control.nix home/default.nix
git commit -m "feat: disable Universal Control via home-manager activation"
```

---

## Rollout (manual — after the tasks land and are pushed)

**Old Mac (this one):**
1. `rebuild` — alias is now `-H macbook`, builds `christopherstory @ macbook`, re-pinning it (undoes the working-tree `christory` flip) and applying the Universal Control disable.

**New Mac (keeper) — ORDER MATTERS:**
1. `git pull`.
2. First switch MUST be explicit (hostname is still `macbook`, so `rebuild` would wrongly target `.#macbook` = `christopherstory`):
   ```bash
   sudo darwin-rebuild switch --flake ~/repos/macDots#christoryCertifyOSMacbook
   ```
3. Afterwards, plain `rebuild` resolves to `-H christoryCertifyOSMacbook`.

**Verify (each machine):** `scutil --get HostName`, `whoami`, and — with both Macs present — that swapping trackpads no longer moves the other machine's cursor.

## Teardown seam (when old Mac is wiped)

1. Delete the `macbook = mkHost { … };` entry from `flake.nix` (one block).
2. Point `bootstrap.sh`'s `HOSTNAME="macbook"` at `christoryCertifyOSMacbook` for the future Mac Studio.
3. Optionally collapse `mkHost` back inline; the Universal Control module stays.
