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
    diff-so-fancy
    just
    tokei
    commitizen
    httpie

    # Shell
    starship
    tmux
    fastfetch # replaces deprecated neofetch

    # Development tools (continued)
    gh

    # Languages & runtimes
    go
    python3
    # Node managed by NVM via Homebrew — not here

    # Build tools
    gnumake
    cmake
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
          location = "~/Desktop/Screenshots";
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
