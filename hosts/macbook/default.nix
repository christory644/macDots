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
    google-cloud-sdk
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
      };

      # ── Finder ─────────────────────────────────────────────────────
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;      # show hidden files
        FXPreferredViewStyle = "clmv"; # column view
        ShowPathbar = true;
        ShowStatusBar = true;
        ShowExternalHardDrivesOnDesktop = false;
        ShowRemovableMediaOnDesktop = false;
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
      };
    };
    # Required for nix-darwin
    stateVersion = 6;
  };

  # Local service hostnames (appended to /etc/hosts)
  networking.hostName = hostname;
  networking.localHostName = hostname;   # Bonjour .local name
  networking.computerName = hostname;    # friendly name in Sharing/Finder
  environment.etc."hosts".text = ''
    127.0.0.1       localhost
    255.255.255.255 broadcasthost
    ::1             localhost

    # Local services (managed by nix-darwin)
    127.0.0.1       chat.local        # Open WebUI        → localhost:4080
    127.0.0.1       ollama.local      # Ollama API        → localhost:11434
  '';

  # Desktop wallpaper — macOS Tahoe broke the AppleScript folder rotation API.
  # Set manually once via System Settings → Wallpaper → Add Folder → ~/repos/wallpapers
  # This persists across reboots; only needs to be set once on a fresh machine.

  # Shell
  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

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
    shell = pkgs.zsh;
  };

  # Platform
  nixpkgs.hostPlatform = "aarch64-darwin";
}
