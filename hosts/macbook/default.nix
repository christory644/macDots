{ pkgs, username, hostname, ... }:

{
  # Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    warn-dirty = false;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages — CLI tools (replaces Homebrew formulas)
  environment.systemPackages = with pkgs; [
    # Ensures the baseline /etc/hosts entries exist in a REGULAR file (see
    # the hosts note further down for why it is not managed declaratively).
    # Idempotent; appends only what is missing; never touches other entries.
    (writeShellScriptBin "hosts-ensure" ''
      set -euo pipefail
      [ "$(id -u)" -eq 0 ] || { echo "run as: sudo hosts-ensure" >&2; exit 1; }

      # A symlinked hosts file (old environment.etc management) is invisible
      # to mDNSResponder: materialize a regular file with identical content.
      if [ -L /etc/hosts ]; then
        content="$(cat /etc/hosts)"
        rm -f /etc/hosts
        printf '%s\n' "$content" > /etc/hosts
        chown root:wheel /etc/hosts
        chmod 644 /etc/hosts
        echo "converted /etc/hosts from symlink to regular file"
      fi

      while IFS= read -r line; do
        [ -z "$line" ] && continue
        if ! grep -qxF "$line" /etc/hosts; then
          printf '%s\n' "$line" >> /etc/hosts
          echo "added: $line"
        fi
      done <<'BASELINE'
      127.0.0.1       localhost
      255.255.255.255 broadcasthost
      ::1             localhost
      127.0.0.1       chat.local
      127.0.0.1       ollama.local
      BASELINE

      dscacheutil -flushcache
      killall -HUP mDNSResponder 2>/dev/null || true
      echo "hosts baseline ensured; resolver cache flushed"
    '')

    # Core utilities
    bat
    btop
    coreutils
    curl
    eza
    fd
    fzf
    jq
    yq             # jq but for YAML/TOML/XML
    ripgrep
    tldr
    tree
    watch          # run a command repeatedly and watch output
    wget
    zoxide

    # Development tools
    git
    git-lfs
    lazygit
    delta          # modern git diff viewer (replaces diff-so-fancy)
    just
    tokei
    commitizen
    httpie
    gh
    lazydocker     # TUI for Docker containers/images/volumes
    dive           # explore Docker image layers
    glow           # terminal markdown renderer
    shellcheck     # shell script linter
    shfmt          # shell script formatter

    # Shell
    starship
    tmux
    fastfetch
    direnv         # per-directory environment variables
    atuin          # better shell history (ctrl+r replacement)
    mise           # universal version manager (node, java, python, etc.)
    sesh           # smart tmux session manager

    # Languages & runtimes — managed by mise (see ~/.config/mise/config.toml)
    # Per-project versions pinned via .mise.toml in each repo
    # Elm: installed via Homebrew (GHC fails to build from source on macOS with Lix)
    dolt           # version-controlled SQL DB (Gastown dependency)

    # Cloud & infrastructure
    # gke-gcloud-auth-plugin: kubectl/pulumi exec-credential auth for GKE
    # (certifyos-pulumi manages GKE for agentOS; kubeconfigs use the plugin)
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])
    pulumi-bin # certifyos-pulumi IaC (local previews/ups per its docs)
    terraform

    # Static sites & content
    zola           # static site generator (Rust)

    # Language formatters (used by conform.nvim)
    # elm-format: installed via Homebrew (GHC fails to build from source on macOS with Lix)
    # Java: formatted by Spotless (palantir style) via Gradle — no standalone formatter needed

    # AI coding agents (for Gastown multi-agent orchestration)
    # aider-chat   # DISABLED — nixpkgs 0.86.1 has broken tests (gpt-4-32k removed from litellm)
                    # Install via: pipx install aider-chat (when needed on bigger machine)
    opencode       # AI coding agent (supports any OpenAI-compatible endpoint)
    ollama         # local LLM server (llama, codellama, mistral, etc.)

    # Media & transcription (used by second_brain YouTube ingestion)
    yt-dlp         # YouTube + many other sites: metadata + caption + audio fetcher
    whisper-cpp    # OpenAI Whisper inference in C++ (Metal-accelerated on Apple Silicon)
    ffmpeg         # video decode + scene-change keyframe extraction for /process-youtube visual layer

    # File management & search
    yazi           # terminal file manager (Rust, blazing fast)
    ast-grep       # structural code search/replace by AST patterns

    # Git workflow
    git-branchless   # stacked PRs / dependent branch management
    git-filter-repo  # git history rewriting

    # Build tools
    gnumake
    cmake

    # Nix tools
    nh             # nicer nix rebuild output (nh darwin switch)
    age            # simple file encryption (used to encrypt SSH keys in repo)

    # Go toolchain extras. These lived in ~/go/bin on the old Mac, installed
    # ad-hoc with `go install`, so a fresh bootstrap recreated none of them.
    # beads is github.com/gastownhall/beads — the `bd` that gt-personal and
    # gt-work need, and those two repos have no remote, so the data crossed
    # tonight while the tool to read it did not.
    beads
    gopls          # Go language server
    delve          # Go debugger (dlv)
    go-tools       # staticcheck
    air            # live reload for Go
    # NOT packaged: swag (swaggo/swag). go-swagger in nixpkgs is a different
    # project. Still needs `go install github.com/swaggo/swag/cmd/swag@latest`.

    # JDKs are NOT here — see hosts/macbook/homebrew.nix. A nixpkgs JDK puts
    # java on PATH but stays invisible to /usr/libexec/java_home, which was
    # the actual failure, and it would also shadow mise's java. The temurin
    # casks install where java_home looks.

    # Other CLI tools that were on the old Mac via Homebrew
    google-cloud-sql-proxy
    poppler        # pdftotext and friends
    yarn

    # Fun
    cowsay
    fortune
  ];

  # System settings
  system = {
    defaults = {
      # ── Dock ───────────────────────────────────────────────────────
      dock = {
        autohide = true;
        mru-spaces = false;            # don't rearrange Spaces by most recent use
        minimize-to-application = true;
        show-recents = false;
        tilesize = 48;
        magnification = true;
        orientation = "bottom";

        # Hot corners OFF, all four. 1 = no action. These were never declared,
        # so the new Mac picked up the macOS default of Quick Note on the
        # bottom-right and fired it whenever the pointer reached the corner.
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;

        largesize = 60;                # magnified icon size
        expose-group-apps = true;      # Mission Control groups windows by app
      };

      # ── Trackpad ───────────────────────────────────────────────────
      # Tap to click. NSGlobalDomain's "com.apple.mouse.tapBehavior" (below)
      # is NOT what modern macOS reads for the built-in trackpad — `Clicking`
      # in com.apple.AppleMultitouchTrackpad is. The old Mac had tap-to-click
      # because it was set by hand years ago; the declaration never worked.
      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
      };

      # ── Finder ─────────────────────────────────────────────────────
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;      # show hidden files
        FXPreferredViewStyle = "Nlsv"; # list view (the old Mac's actual habit;
                                       # this was declared as column and never lived with)
        ShowPathbar = true;
        ShowStatusBar = true;
        ShowExternalHardDrivesOnDesktop = false;
        ShowRemovableMediaOnDesktop = false;
        FXEnableExtensionChangeWarning = false;  # no nag when renaming extensions
        FXDefaultSearchScope = "SCev";           # search the current folder, not the Mac
      };

      # ── Stage Manager / desktop ────────────────────────────────────
      WindowManager = {
        AutoHide = true;               # hide desktop items until the wallpaper is clicked
      };

      # ── Menu bar clock ─────────────────────────────────────────────
      menuExtraClock = {
        Show24Hour = false;
        ShowAMPM = true;
        ShowDayOfWeek = true;
        ShowDate = 0;                  # 0 = "When Space Allows"
        ShowSeconds = false;
        IsAnalog = false;
        FlashDateSeparators = false;
      };

      # ── Control Center ─────────────────────────────────────────────
      controlcenter = {
        BatteryShowPercentage = true;
        Bluetooth = true;
        Sound = true;
        FocusModes = true;
        NowPlaying = true;
      };

      # ── Global preferences ─────────────────────────────────────────
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        AppleInterfaceStyle = "Dark";
        AppleShowScrollBars = "Always";

        # Keyboard — fast repeat for fast typing
        KeyRepeat = 2;                 # fastest repeat rate
        InitialKeyRepeat = 15;         # shortest delay before repeat
        ApplePressAndHoldEnabled = false; # disable press-and-hold for accents, enable key repeat

        # Trackpad
        "com.apple.mouse.tapBehavior" = 1;       # tap to click
        "com.apple.trackpad.scaling" = 3.0;      # high tracking speed
        "com.apple.trackpad.forceClick" = true;

        # Disable auto-correct annoyances
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;

        # Save to disk (not iCloud) by default
        NSDocumentSaveNewDocumentsToCloud = false;

        # Drag any window from anywhere with ctrl+cmd held
        NSWindowShouldDragOnGesture = true;
      };

      # ── Custom preferences ─────────────────────────────────────────
      CustomUserPreferences = {
        "com.apple.screencapture" = {
          location = "/Users/${username}/Screenshots";
          type = "png";
        };
        # Disable Siri
        "com.apple.assistant.support"."Assistant Enabled" = false;
        # Finder: new windows open Downloads
        "com.apple.finder" = {
          NewWindowTarget = "PfLo";
          NewWindowTargetPath = "file:///Users/${username}/Downloads/";
        };
        # Tap to click on an external/Bluetooth trackpad too. The `trackpad`
        # block above only covers the built-in one.
        "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
          Clicking = true;
        };
        # Mouse tracking speed. Not a typed system.defaults option in this
        # nix-darwin, so it goes through CustomUserPreferences.
        NSGlobalDomain = {
          "com.apple.mouse.scaling" = 3.0;
        };
        # Horizontal swipes off, as on the old Mac — AeroSpace owns space
        # switching, and the system gesture fights it.
        "com.apple.AppleMultitouchTrackpad" = {
          TrackpadThreeFingerHorizSwipeGesture = 0;
          TrackpadFourFingerHorizSwipeGesture = 0;
        };
        # Input sources: the old Mac also had PressAndHold enabled.
        "com.apple.HIToolbox" = {
          AppleEnabledInputSources = [
            {
              InputSourceKind = "Keyboard Layout";
              "KeyboardLayout ID" = 0;
              "KeyboardLayout Name" = "U.S.";
            }
            {
              InputSourceKind = "Non Keyboard Input Method";
              "Bundle ID" = "com.apple.CharacterPaletteIM";
            }
            {
              InputSourceKind = "Non Keyboard Input Method";
              "Bundle ID" = "com.apple.PressAndHold";
            }
          ];
        };
      };
    };

    # ── Keyboard ─────────────────────────────────────────────────────
    # Caps Lock → Escape. This was set by hand on the old Mac through
    # System Settings → Modifier Keys, which `defaults export` does not
    # capture, so it was invisible to the settings audit and never crossed.
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };

    # Required for nix-darwin
    stateVersion = 6;
  };

  # Spotlight's ⌘Space is freed for Raycast. This has to MERGE rather than
  # write: AppleSymbolicHotKeys is one dictionary holding every shortcut, and
  # `defaults write` on it replaces the lot — this machine has 19 entries, 3
  # with custom bindings, which a wholesale write would silently reset.
  # `-dict-add` adds the two keys and leaves the rest alone.
  #   64 = Show Spotlight search, 65 = Show Finder search window
  # Activation runs as root in this nix-darwin, so the user-scoped `defaults`
  # calls go through `sudo -u`; writing them as root would land in root's
  # preferences and silently do nothing for him.
  system.activationScripts.postActivation.text = ''
    hk() {
      sudo -u ${username} /usr/bin/defaults write com.apple.symbolichotkeys \
        AppleSymbolicHotKeys -dict-add "$1" "$2" || true
    }

    # Mission Control / Spaces — off, AeroSpace owns these
    hk 32  '{enabled = 0; value = {parameters = (65535, 126, 8650752); type = standard;};}'
    hk 33  '{enabled = 0; value = {parameters = (65535, 125, 8650752); type = standard;};}'
    hk 34  '{enabled = 0;}'
    hk 35  '{enabled = 1; value = {parameters = (65535, 125, 8781824); type = standard;};}'
    hk 36  '{enabled = 0; value = {parameters = (65535, 103, 8388608); type = standard;};}'
    hk 37  '{enabled = 1; value = {parameters = (65535, 103, 8519680); type = standard;};}'
    hk 44  '{enabled = 0;}'
    hk 45  '{enabled = 0;}'
    hk 46  '{enabled = 0;}'
    hk 48  '{enabled = 0;}'
    hk 49  '{enabled = 0;}'
    hk 52  '{enabled = 0; value = {parameters = (100, 2, 1572864); type = standard;};}'

    # 64/65 — Spotlight and Finder search. OFF so Raycast owns cmd+space.
    hk 64  '{enabled = 0; value = {parameters = (32, 49, 1048576); type = standard;};}'
    hk 65  '{enabled = 0; value = {parameters = (32, 49, 1572864); type = standard;};}'

    # 79/81 — Move left/right a space. OFF; AeroSpace binds these itself.
    hk 79  '{enabled = 0; value = {parameters = (65535, 123, 8650752); type = standard;};}'
    hk 81  '{enabled = 0; value = {parameters = (65535, 124, 8650752); type = standard;};}'
    hk 82  '{enabled = 1; value = {parameters = (65535, 124, 8781824); type = standard;};}'

    hk 118 '{enabled = 0; value = {parameters = (65535, 18, 262144); type = standard;};}'
    hk 190 '{enabled = 0; value = {parameters = (113, 12, 8388608); type = standard;};}'

    sudo -u ${username} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u || true

    # Dock and Finder re-read their preferences only on restart.
    sudo -u ${username} /usr/bin/killall Dock 2>/dev/null || true
    sudo -u ${username} /usr/bin/killall Finder 2>/dev/null || true
  '';

  networking.hostName = hostname;
  networking.localHostName = hostname;   # Bonjour .local name
  networking.computerName = hostname;    # friendly name in Sharing/Finder
  # /etc/hosts is deliberately NOT managed declaratively. environment.etc
  # makes it a symlink into the store, and mDNSResponder — the resolver
  # browsers use — does not ingest a symlinked hosts file (CLI tools read
  # through it; browsers resolve nothing). A regular file also lets other
  # tools append their own entries without going through nix. The baseline
  # entries live in the `hosts-ensure` script (systemPackages above):
  # run `sudo hosts-ensure` after a rebuild or whenever the baseline drifts.

  # Desktop wallpaper — macOS Tahoe broke the AppleScript folder rotation API.
  # Set manually once via System Settings → Wallpaper → Add Folder → ~/repos/wallpapers
  # This persists across reboots; only needs to be set once on a fresh machine.

  # Shell
  #
  # Login shell is Apple's /bin/zsh, NOT pkgs.zsh — see users.users below.
  # programs.zsh.enable stays on: it generates /etc/zshrc + /etc/zprofile, which
  # Apple's zsh reads identically (verified: nix PATH, NIX_PROFILES and the nix
  # profile binaries all resolve correctly under `/bin/zsh -l`).
  programs.zsh.enable = true;
  environment.shells = [
    pkgs.zsh
    "/bin/zsh"
  ];

  # Enforce the login shell on every rebuild.
  #
  # `users.users.<name>.shell` (below) is inert for this account: nix-darwin only
  # manages users listed in `users.knownUsers`, and the generated activation
  # script's "setting up users" step touches _nixbld* and nothing else. Without
  # this hook the /bin/zsh choice lives only in the directory service — it would
  # survive reboots and rebuilds on THIS machine, but a machine freshly built
  # from this flake would silently get the hanging nixpkgs zsh again.
  #
  # preActivation rather than postActivation: the Homebrew step runs at the very
  # end of activation (line ~2755 of ~2788), so a `brew bundle` failure aborts
  # before postActivation would ever run. This has to be immune to that.
  #
  # Idempotent — only writes when the value differs.
  system.activationScripts.preActivation.text = ''
    loginShell=/bin/zsh
    current=$(dscl . -read /Users/${username} UserShell 2>/dev/null | awk '{print $2}')
    if [ "$current" != "$loginShell" ]; then
      echo "setting ${username} login shell: $current -> $loginShell" >&2
      dscl . -create /Users/${username} UserShell "$loginShell"
    fi

    # Agent state synced from the old Mac (Claude settings hooks, plugin
    # marketplaces, orchestrator prompts, scheduled tasks) hardcodes that
    # machine's home. Alias it here rather than rewriting files that still
    # sync back to it. No-op on the old Mac, where it is a real directory.
    oldHome=/Users/christopherstory
    if [ ! -e "$oldHome" ] && [ ! -L "$oldHome" ]; then
      echo "aliasing $oldHome -> /Users/${username}" >&2
      ln -s /Users/${username} "$oldHome"
    fi
  '';

  # Fonts — we reference ~/repos/fonts/ in terminal configs
  # Fira Code Nerd Font from nixpkgs as fallback
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
  ];

  # Primary user (required by nix-darwin for user-scoped settings)
  system.primaryUser = username;

  # Users
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";

    # Apple's /bin/zsh, not pkgs.zsh.
    #
    # The nixpkgs zsh build hits a long-standing zsh race in getoutput(): the
    # child forked for a command substitution can exit and have its SIGCHLD
    # handled *before* waitforpid() is called, so the parent then blocks in
    # signal_suspend()/pause() forever waiting for a signal already consumed.
    # (Same failure documented in Red Hat bz#1198671.) The shell dead-ends after
    # the login banner with no prompt — the "new tab never loads" hang.
    #
    # Both builds are zsh 5.9; only the nixpkgs one trips it, so this is a build
    # /SDK difference, not a version difference (nix: aarch64-apple-darwin25.3.0,
    # Apple: arm64-apple-darwin25.0). Measured on this machine, same moment:
    #
    #   30 command substitutions, no rc files:
    #     /bin/zsh                  0/6 hangs
    #     nix zsh                   6/6 hangs
    #   full interactive startup with our own config:
    #     /bin/zsh                  0/8 hangs
    #
    # Revisit if nixpkgs ships a zsh with the getoutput() race fixed.
    #
    # NOTE: this setting is currently DECLARATIVE-ONLY. nix-darwin only manages
    # users listed in `users.knownUsers`, and this user is not one of them — the
    # generated activation script's "setting up users" step touches _nixbld1..5
    # and nothing else. The live change was made with:
    #
    #   chsh -s /bin/zsh
    #
    # which persists in the directory service. Enrolling this user in
    # knownUsers would make nix-darwin own the account lifecycle (including
    # deletion), which is not worth it on a managed work machine.
    shell = "/bin/zsh";
  };

  # Platform
  nixpkgs.hostPlatform = "aarch64-darwin";
}
