{
  name = "night-owl";
  slug = "night_owl";  # for starship palette name (no hyphens)

  # Per-application theme identifiers
  apps = {
    nvim = "night-owl";         # vim colorscheme name
    nvimPlugin = "night-owl-nvim"; # nixpkgs vimPlugin name
    nvimSetup = ''require("night-owl").setup()'';
    lualine = "night-owl";
    vscode = "Night Owl";
    bat = "night-owl";          # custom .tmTheme
    batBuiltin = false;         # requires custom theme file
  };

  # Terminal 16-color palette (shared across kitty, ghostty, tmux)
  terminal = {
    foreground = "#d6deeb";
    background = "#011627";
    cursor = "#80a4c2";
    selection_fg = "#d6deeb";
    selection_bg = "#1d3b53";

    # Normal (0-7)
    color0  = "#011627";  # black
    color1  = "#ef5350";  # red
    color2  = "#22da6e";  # green
    color3  = "#ecc48d";  # yellow
    color4  = "#82aaff";  # blue
    color5  = "#c792ea";  # magenta
    color6  = "#7fdbca";  # cyan
    color7  = "#d6deeb";  # white

    # Bright (8-15)
    color8  = "#637777";  # bright black
    color9  = "#ff6363";  # bright red
    color10 = "#addb67";  # bright green
    color11 = "#f78c6c";  # bright orange
    color12 = "#82aaff";  # bright blue
    color13 = "#c792ea";  # bright magenta
    color14 = "#7fdbca";  # bright cyan
    color15 = "#ffffff";  # bright white
  };

  # Semantic colors (for tmux statusbar, starship, etc.)
  palette = {
    bg        = "#011627";
    bg_dark   = "#010e1a";
    bg_light  = "#112630";
    bg2       = "#0b2942";
    bg3       = "#13344f";
    bg4       = "#084d81";
    fg        = "#d6deeb";
    fg_dim    = "#637777";
    accent    = "#82aaff";
    cyan      = "#7fdbca";
    red       = "#ef5350";
    red_bright = "#ff6363";
    green     = "#22da6e";
    green_bright = "#addb67";
    yellow    = "#ecc48d";
    orange    = "#f78c6c";
    magenta   = "#c792ea";
    purple    = "#7e57c2";
    blue      = "#82aaff";
    white     = "#ffffff";
    selection  = "#1d3b53";
    cursor     = "#80a4c2";
    line       = "#4b6479";
    current    = "#01111d";
    current_nr = "#c5e4fd";
  };

  # Starship-specific extended palette
  starship = {
    background       = "#011627";
    dark_background  = "#010e1a";
    second_background = "#0b2942";
    third_background = "#13344f";
    fourth_background = "#084d81";
    foreground       = "#d6deeb";
    current          = "#01111d";
    selection        = "#1d3b53";
    cursor           = "#80a4c2";
    line             = "#4b6479";
    current_number   = "#c5e4fd";
    cyan             = "#7fdbca";
    gray             = "#637777";
    red              = "#ff6363";
    error_red        = "#ef5350";
    green            = "#22da6e";
    lime             = "#addb67";
    blue             = "#82aaff";
    orange           = "#f78c6c";
    magenta          = "#c792ea";
    white            = "#ffffff";
    bright           = "#575656";
    purple           = "#7e57c2";
    yellow           = "#ecc48d";
  };
}
