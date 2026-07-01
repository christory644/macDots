# Two-machine transitional coexistence

**Date:** 2026-07-01
**Status:** Design — pending review

## Problem

The migration overlap has both Macs running at once, and the single-host flake
can't serve them without conflict:

1. **Username competition.** `flake.nix` has one `username` literal. `origin/main`
   (3de5095) flipped it `christopherstory → christory` for the new machine, which
   breaks the old machine (its account is `christopherstory`). A single literal can
   only ever be correct on one of the two boxes.
2. **Network collision.** Both machines set `networking.hostName = "macbook"`
   (`hosts/macbook/default.nix:197`), so two `macbook.local` on one LAN collide
   (Bonjour/mDNS/SSH `.local`).
3. **Universal Control.** Same Apple ID + physical proximity lets the pointer and
   keyboard cross machines — swapping to the new Mac's trackpad moves the cursor on
   the old Mac. A macOS feature, not a config bug.

## Goals / non-goals

- **Goal:** both machines build and run correctly, concurrently, without competing.
- **Goal:** a **clean removal seam** — when the old Mac is wiped, collapsing back to
  a single canonical config is a tiny, obvious diff.
- **Non-goal:** a permanent, maintained multi-host setup. This is transitional.
- **Non-goal:** renaming any macOS user account. Each machine keeps the account it
  already has; we only map each host to the right existing username.

## Machine identities

| Role            | Account username   | Hostname                    | Fate      |
|-----------------|--------------------|-----------------------------|-----------|
| Old (this Mac)  | `christopherstory` | `macbook` (unchanged)       | wiped     |
| New (keeper)    | `christory`        | `christoryCertifyOSMacbook` | canonical |

Only the **new** machine renames; the old one keeps `macbook`, so the box that's
leaving sees no churn.

## Design

### 1. `mkHost` helper + two entries (flake.nix)

Introduce a small builder so the two entries share every module and differ only in
`hostname` and `username`:

```nix
let
  mkHost = { hostname, username }: nix-darwin.lib.darwinSystem {
    specialArgs = { inherit username hostname nixvim nix-vscode-extensions; };
    modules = [ <overlay> ./hosts/macbook/default.nix ./hosts/macbook/homebrew.nix
                <nix-homebrew module> <home-manager module> ];
  };
in {
  darwinConfigurations = {
    macbook                   = mkHost { hostname = "macbook";                   username = "christopherstory"; };
    christoryCertifyOSMacbook = mkHost { hostname = "christoryCertifyOSMacbook"; username = "christory"; };
  };
}
```

- The nix-homebrew `user` and the home-manager `users.${username}` already read
  `username`; they become per-host automatically.
- `hostname` is added to both `specialArgs` and the home-manager `extraSpecialArgs`
  so host modules and home modules can consume it.

### 2. Parameterize the hostname (hosts/macbook/default.nix)

Accept `hostname` in the module args and set the three name fields from it (today
only `hostName` is set, hardcoded):

```nix
networking.hostName      = hostname;
networking.localHostName = hostname;   # the Bonjour .local name
networking.computerName  = hostname;   # friendly name in Sharing/Finder
```

`christoryCertifyOSMacbook` is a valid hostname label (alphanumeric, no spaces),
so it is safe for all three.

### 3. Per-host `rebuild` alias (home/shell/zsh.nix)

Today: `rebuild = "nh darwin switch ~/repos/macDots -H macbook";` (hardcoded).
Change to consume the threaded hostname so each machine rebuilds its own entry:

```nix
rebuild = "nh darwin switch ~/repos/macDots -H ${hostname}";
```

`update` (line 167) gets the same treatment. `home/default.nix` passes `hostname`
into the shell module (it is already in `extraSpecialArgs`).

### 4. Disable Universal Control declaratively (hosts/macbook/default.nix)

Applies to both hosts via the shared module. Chosen over the manual toggle for
reproducibility.

```nix
system.defaults.CustomUserPreferences."com.apple.universalcontrol" = {
  Disable            = true;
  DisableMagnetEdges = true;
  DisableCrossDrag   = true;
};
```

**Caveat:** `com.apple.universalcontrol` is not an officially documented key. It may
require a logout/login (or `killall` of the relevant agent) to take effect. If it
doesn't stick, fall back to System Settings → Displays → Advanced → uncheck "Allow
your pointer and keyboard to move between any nearby Mac or iPad." This is safe to
keep permanently on the keeper.

## Rollout

**Old Mac (this one):**
1. `git pull` (fast-forward past 3de5095 + the new coexistence commit).
2. `rebuild` — alias is now `-H macbook`, builds `christopherstory @ macbook`. No change of identity; just re-pins it. Universal Control disabled.

**New Mac (keeper) — order matters:**
1. `git pull`.
2. **First command must be the explicit identity switch**, not `rebuild`:
   `sudo darwin-rebuild switch --flake ~/repos/macDots#christoryCertifyOSMacbook`
   — its hostname is still `macbook`, so `rebuild` (now `-H <hostname>`) would wrongly
   target `.#macbook` (= `christopherstory`) until the hostname flips. This switch sets
   the hostname to `christoryCertifyOSMacbook` and installs the per-host `rebuild` alias.
3. After that, plain `rebuild` works (resolves to `-H christoryCertifyOSMacbook`).

## Clean removal seam (when old Mac is wiped)

1. Delete the `macbook = mkHost { ... };` line from `flake.nix` (one line). The
   `christoryCertifyOSMacbook` entry is already the sole canonical config.
2. Point `bootstrap.sh`'s `HOSTNAME` at `christoryCertifyOSMacbook` (currently
   `"macbook"`) so a future fresh machine (e.g. the Mac Studio) builds the right
   entry. Optionally rename `hosts/macbook/` → `hosts/christoryCertifyOSMacbook/`
   for tidiness (not required — the directory name is arbitrary).
3. Optionally drop the `mkHost` helper back to an inline config if a single host no
   longer warrants it. The Universal Control block may stay.

## Risks / caveats

- **Transition-window footgun (new Mac):** running `rebuild` before the explicit
  `-H christoryCertifyOSMacbook` switch would try to activate `christopherstory` on
  the new box. Rollout step 2 above is ordered to prevent this; call it out loudly.
- **Universal Control key** may not be honored on this macOS version (see §4 caveat).
- **No account rename** — if the intent ever changes to unifying on one username,
  that's a separate, heavier task (macOS account rename), explicitly out of scope.

## Verification

- `nix eval .#darwinConfigurations.macbook.system.drvPath` and
  `.#darwinConfigurations.christoryCertifyOSMacbook.system.drvPath` both evaluate.
- Each machine: after its rebuild, `scutil --get HostName` / `LocalHostName` /
  `ComputerName` show the expected value; `whoami` matches the entry's username;
  `.local` names no longer collide.
- Universal Control: swapping trackpads no longer moves the other machine's cursor
  (after re-login if needed).
