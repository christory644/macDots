{ theme, ... }:

let t = theme.terminal; in
{
  programs.kitty = {
    enable = true;

    font = {
      name = "Operator Mono Lig";
      size = 13;
    };

    settings = {
      # Appearance
      background_opacity = "0.85";
      background_blur = 10;

      # Nerd Font symbol map
      symbol_map = "U+e000-U+e00a,U+ea60-U+ebeb,U+e0a0-U+e0c8,U+e0ca,U+e0cc-U+e0d4,U+e200-U+e2a9,U+e300-U+e3e3,U+e5fa-U+e6b1,U+e700-U+e7c5,U+f000-U+f2e0,U+f300-U+f372,U+f400-U+f532,U+f0001-U+f1af0 Symbols Nerd Font Mono";

      # macOS
      macos_option_as_alt = "both";

      # Scrollback
      scrollback_lines = 10000;

      # Theme colors (from ${theme.name})
      foreground = t.foreground;
      background = t.background;
      selection_foreground = t.selection_fg;
      selection_background = t.selection_bg;
      cursor = t.cursor;

      color0  = t.color0;
      color1  = t.color1;
      color2  = t.color2;
      color3  = t.color3;
      color4  = t.color4;
      color5  = t.color5;
      color6  = t.color6;
      color7  = t.color7;
      color8  = t.color8;
      color9  = t.color9;
      color10 = t.color10;
      color11 = t.color11;
      color12 = t.color12;
      color13 = t.color13;
      color14 = t.color14;
      color15 = t.color15;
    };

    keybindings = {
      "ctrl+shift+k" = "scroll_line_up";
      "ctrl+shift+j" = "scroll_line_down";
    };
  };
}
