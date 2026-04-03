# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  System-wide theme switcher                                            ║
# ║                                                                        ║
# ║  Change `activeTheme` below and rebuild — every app updates:           ║
# ║  nvim, tmux, kitty, ghostty, starship, bat, vscode, cursor, lualine   ║
# ╚══════════════════════════════════════════════════════════════════════════╝
{ lib, ... }:

let
  # ── CHANGE THIS TO SWITCH THEMES ──────────────────────────────────────
  activeTheme = "night-owl";
  # ──────────────────────────────────────────────────────────────────────
  #
  # Dark themes:
  #   "night-owl"            — deep blue, warm accents
  #   "catppuccin-mocha"     — warm dark, pastel accents
  #   "catppuccin-macchiato" — teal-tinted dark, pastel
  #   "catppuccin-frappe"    — muted blue-gray, pastel
  #   "tokyo-night"          — cool purple/blue
  #   "kanagawa"             — Japanese ink painting, warm
  #   "rose-pine-moon"       — muted purple, soft contrast
  #   "dracula"              — classic purple/pink
  #   "nord"                 — arctic blue-gray
  #   "everforest-dark"      — green-tinted forest dark
  #   "gruvbox-dark"         — warm retro amber
  #
  # Light themes:
  #   "catppuccin-latte"     — warm pastel light
  #   "tokyo-night-day"      — cool blue light
  #   "rose-pine-dawn"       — soft pink/muted light
  #   "everforest-light"     — green-tinted forest light
  #   "github-light"         — clean modern white
  #   "gruvbox-light"        — warm retro light
  #
  # ──────────────────────────────────────────────────────────────────────

  themes = {
    # Dark
    night-owl = import ./night-owl.nix;
    catppuccin-mocha = import ./catppuccin-mocha.nix;
    catppuccin-macchiato = import ./catppuccin-macchiato.nix;
    catppuccin-frappe = import ./catppuccin-frappe.nix;
    tokyo-night = import ./tokyo-night.nix;
    kanagawa = import ./kanagawa.nix;
    rose-pine-moon = import ./rose-pine-moon.nix;
    dracula = import ./dracula.nix;
    nord = import ./nord.nix;
    everforest-dark = import ./everforest-dark.nix;
    gruvbox-dark = import ./gruvbox-dark.nix;

    # Light
    catppuccin-latte = import ./catppuccin-latte.nix;
    tokyo-night-day = import ./tokyo-night-day.nix;
    rose-pine-dawn = import ./rose-pine-dawn.nix;
    everforest-light = import ./everforest-light.nix;
    github-light = import ./github-light.nix;
    gruvbox-light = import ./gruvbox-light.nix;
  };

in
{
  _module.args.theme = themes.${activeTheme};
}
