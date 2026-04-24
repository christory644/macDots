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
      "gastownhall/gascity"
    ];

    # Homebrew formulas — only for things not in nixpkgs or that work better via brew
    brews = [
      "borders"           # JankyBorders — not in nixpkgs, needs tap
      "gastown"           # multi-agent orchestration (Steve Yegge) — not in nixpkgs
      "gascity"           # Gas City — open-source orchestration SDK (successor to Gastown)
      "pi-coding-agent"   # minimal AI coding agent (supports Ollama, Claude, OpenAI, etc.)
      "nvm"               # Node version manager — not in nixpkgs (migrate to mise when ready)
      "gemini-cli"        # Google Gemini CLI coding agent (fast updates)
    ];

    # GUI applications (casks) — Nix can't handle macOS .app bundles well
    casks = [
      # Terminals
      "alacritty"
      "cmux"
      "kitty"
      "iterm2"

      # Browsers
      "arc"
      "firefox"

      # Development
      "cursor"
      "visual-studio-code"
      "docker-desktop"
      "bruno"
      "github"

      # AI coding tools (managed by Homebrew for fast updates — these ship multiple times/day)
      "claude-code"
      "codex"
      "coderabbit"

      # Window management
      "aerospace"

      # Productivity
      "obsidian"
      "raycast"
      "maccy"
      "zoom"

      # Communication
      "discord"

      # Media
      "spotify"
    ];

  };
}
