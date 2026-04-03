{ ... }:

{
  # Homebrew — GUI casks only (CLI tools managed by Nix)
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # "zap" removes casks not listed here; "uninstall" removes formulas not listed
      # Using "none" for safety during migration — switch to "zap" once stable
      cleanup = "none";
    };

    taps = [
      "felixkratz/formulae"
      "nikitabobko/tap"
    ];

    # Homebrew formulas — only for things not in nixpkgs or that work better via brew
    brews = [
      "borders" # JankyBorders — not in nixpkgs, needs tap
    ];

    # GUI applications (casks) — Nix can't handle macOS .app bundles well
    casks = [
      # Terminals
      "cmux"
      "kitty"
      "iterm2"

      # Browsers
      "arc"
      "firefox"

      # Development
      "cursor"
      "visual-studio-code"
      "docker"
      "bruno"
      "github"

      # Window management
      "aerospace"

      # Productivity
      "obsidian"
      "raycast"
      "maccy"
      "zoom"

      # Media
      "spotify"
    ];

  };
}
