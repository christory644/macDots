{ ... }:

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

      # Night Owl colors
      foreground = "#d6deeb";
      background = "#011627";
      selection_foreground = "#d6deeb";
      selection_background = "#1d3b53";
      cursor = "#80a4c2";

      # Normal colors
      color0 = "#011627";
      color1 = "#ef5350";
      color2 = "#22da6e";
      color3 = "#ecc48d";
      color4 = "#82aaff";
      color5 = "#c792ea";
      color6 = "#7fdbca";
      color7 = "#d6deeb";

      # Bright colors
      color8 = "#637777";
      color9 = "#ff6363";
      color10 = "#addb67";
      color11 = "#f78c6c";
      color12 = "#82aaff";
      color13 = "#c792ea";
      color14 = "#7fdbca";
      color15 = "#ffffff";
    };

    keybindings = {
      "ctrl+shift+k" = "scroll_line_up";
      "ctrl+shift+j" = "scroll_line_down";
    };
  };
}
