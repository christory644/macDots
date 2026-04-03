{ pkgs, username, ... }:

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
    ripgrep
    tldr
    tree
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
    glow           # terminal markdown renderer

    # Shell
    starship
    tmux
    fastfetch
    direnv         # per-directory environment variables
    atuin          # better shell history (ctrl+r replacement)
    mise           # universal version manager (node, java, python, etc.)
    sesh           # smart tmux session manager

    # Languages & runtimes
    go
    python3
    dolt           # version-controlled SQL DB (Gastown dependency)
    # Node managed by NVM via Homebrew — not here

    # Language formatters (used by conform.nvim)
    elmPackages.elm-format   # Elm formatter
    # Java: formatted by Spotless (palantir style) via Gradle — no standalone formatter needed

    # AI coding agents (for Gastown multi-agent orchestration)
    # aider-chat   # DISABLED — nixpkgs 0.86.1 has broken tests (gpt-4-32k removed from litellm)
                    # Install via: pipx install aider-chat (when needed on bigger machine)
    opencode       # AI coding agent (supports any OpenAI-compatible endpoint)
    ollama         # local LLM server (llama, codellama, mistral, etc.)

    # File management & search
    yazi           # terminal file manager (Rust, blazing fast)
    ast-grep       # structural code search/replace by AST patterns

    # Git workflow
    git-branchless # stacked PRs / dependent branch management

    # Build tools
    gnumake
    cmake

    # Nix tools
    nh             # nicer nix rebuild output (nh darwin switch)

    # Fun
    cowsay
    fortune
  ];

  # System settings
  system = {
    defaults = {
      dock = {
        autohide = true;
        mru-spaces = false;
        minimize-to-application = true;
        show-recents = false;
        tilesize = 48;
      };
      finder = {
        AppleShowAllExtensions = true;
        FXPreferredViewStyle = "clmv"; # column view
        ShowPathbar = true;
        ShowStatusBar = true;
      };
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        AppleInterfaceStyle = "Dark";
        KeyRepeat = 2;
        InitialKeyRepeat = 15;
        "com.apple.mouse.tapBehavior" = 1; # tap to click
      };
      CustomUserPreferences = {
        "com.apple.screencapture" = {
          location = "/Users/${username}/Screenshots";
          type = "png";
        };
      };
    };
    # Required for nix-darwin
    stateVersion = 6;
  };

  # Shell
  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

  # Fonts — we reference ~/repos/fonts/ in terminal configs
  # Fira Code Nerd Font from nixpkgs as fallback
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
  ];

  # Security
  security.pam.services.sudo_local.touchIdAuth = true;

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
