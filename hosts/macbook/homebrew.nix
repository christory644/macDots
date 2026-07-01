{ ... }:

{
  # Homebrew — GUI casks only (CLI tools managed by Nix)
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      # upgrade = false on purpose: don't upgrade installed brews/casks on every
      # system rebuild. With `upgrade = true`, a single flaky formula upgrade
      # (e.g. a transient bad mlx-lm revision) aborts the ENTIRE darwin-rebuild
      # before any nix changes activate. The AI casks (claude, codex, cursor, …)
      # self-update internally anyway. Run `brew upgrade` / `brew upgrade --cask`
      # manually when you actually want to bump versions.
      upgrade = false;
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
      "elm"               # Elm compiler — nixpkgs requires GHC from source (broken on macOS/Lix)
      "elm-format"        # Elm formatter — same GHC issue
      "gastown"           # multi-agent orchestration (Steve Yegge) — not in nixpkgs
      "gascity"           # Gas City — open-source orchestration SDK (successor to Gastown)
      "pi-coding-agent"   # minimal AI coding agent (supports Ollama, Claude, OpenAI, etc.)
      "gemini-cli"        # Google Gemini CLI coding agent (fast updates)
      "mlx-lm"            # Apple MLX LLM toolkit — fine-tuning + inference on Apple Silicon
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
      "google-chrome"

      # Development
      "cursor"
      "visual-studio-code"
      "docker-desktop"
      "bruno"
      "github"
      # firefoo (Firestore GUI) — not in Homebrew, install manually from https://firefoo.app

      # AI coding tools (managed by Homebrew for fast updates — these ship multiple times/day)
      "chatgpt"
      "claude"
      "claude-code@latest"
      "codex"           # Codex CLI binary (/opt/homebrew/bin/codex)
      "codex-app"       # Codex Desktop app (separate from the CLI; launched 2026-02)
      "coderabbit"
      "supacode"        # Native terminal coding agents command center (.app, requires macOS >= 26)

      # Window management
      # aerospace — cask fails to install on newer macOS (aborts `brew bundle`,
      # which in turn aborts the whole darwin-rebuild BEFORE home-manager user
      # activation runs — no shell aliases/config get written). Re-enable once
      # the cask supports the target OS, or install manually:
      #   brew install --cask aerospace
      # "aerospace"

      # Productivity
      "obsidian"
      "raycast"
      "maccy"
      "whimsical"
      "google-drive"
      "zoom"

      # Communication
      "discord"
      "slack"

      # Media
      "spotify"

      # Hardware
      # insta360-link-controller — requires sudo TTY for .pkg installer, install manually:
      #   brew install --cask insta360-link-controller
    ];

  };
}
