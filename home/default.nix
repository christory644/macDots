{ pkgs, lib, username, nixvim, ... }:

{
  imports = [
    nixvim.homeModules.nixvim

    ./themes/default.nix
    ./shell/zsh.nix
    ./shell/starship.nix
    ./git.nix
    ./ssh.nix
    ./tmux.nix
    ./terminal/ghostty.nix
    ./terminal/kitty.nix
    ./nvim/default.nix
    ./vscode.nix
    ./ollama.nix
    ./headroom.nix
    ./supacode.nix
    ./second-brain-autocommit.nix
    ./mise.nix
    ./syncthing.nix
  ];

  home = {
    username = username;
    homeDirectory = "/Users/${username}";
    stateVersion = "24.11";

    # Font symlinks — use activation script to avoid pure-eval restriction on absolute paths
    activation.linkCustomFonts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      FONT_SRC="/Users/${username}/repos/fonts"
      FONT_DST="/Users/${username}/Library/Fonts"

      link_font_dir() {
        local src="$1"
        local dst="$2"
        if [ -d "$src" ]; then
          run mkdir -p "$dst"
          for f in "$src"/*; do
            [ -e "$f" ] || continue
            local base="$(basename "$f")"
            local target="$dst/$base"
            if [ ! -e "$target" ] && [ ! -L "$target" ]; then
              run ln -s "$f" "$target"
            fi
          done
        else
          verboseEcho "Font source not found: $src"
        fi
      }

      link_font_dir "$FONT_SRC/Operator Mono Lig" "$FONT_DST/OperatorMonoLig"
      link_font_dir "$FONT_SRC/Dank Mono" "$FONT_DST/DankMono"
      link_font_dir "$FONT_SRC/Fira Code" "$FONT_DST/FiraCode"
    '';
  };

  # Aerospace config (window manager)
  xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;

  # Bat custom theme (only needed for themes not built into bat)
  xdg.configFile."bat/themes/night-owl.tmTheme".source = ./bat/themes/night-owl.tmTheme;
  home.activation.buildBatCache = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.bat}/bin/bat cache --build 2>/dev/null || true
  '';

  # Desktop wallpaper — see hosts/macbook/default.nix postActivation (must run after Dock restart)

  programs.home-manager.enable = true;
}
