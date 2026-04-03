{
  name = "catppuccin-frappe";
  slug = "catppuccin_frappe";

  apps = {
    nvim = "catppuccin-frappe";
    nvimPlugin = "catppuccin-nvim";
    nvimSetup = ''require("catppuccin").setup({ flavour = "frappe" })'';
    lualine = "catppuccin";
    vscode = "Catppuccin Frappé";
    bat = "Catppuccin Frappe";
    batBuiltin = true;
  };

  terminal = {
    foreground = "#c6d0f5";
    background = "#303446";
    cursor = "#f2d5cf";
    selection_fg = "#c6d0f5";
    selection_bg = "#51576d";

    color0  = "#51576d";
    color1  = "#e78284";
    color2  = "#a6d189";
    color3  = "#e5c890";
    color4  = "#8caaee";
    color5  = "#f4b8e4";
    color6  = "#81c8be";
    color7  = "#b5bfe2";

    color8  = "#626880";
    color9  = "#e78284";
    color10 = "#a6d189";
    color11 = "#e5c890";
    color12 = "#8caaee";
    color13 = "#f4b8e4";
    color14 = "#81c8be";
    color15 = "#a5adce";
  };

  palette = {
    bg         = "#303446";
    bg_dark    = "#292c3c";
    bg_light   = "#414559";
    bg2        = "#363a4f";
    bg3        = "#414559";
    bg4        = "#51576d";
    fg         = "#c6d0f5";
    fg_dim     = "#a5adce";
    accent     = "#8caaee";
    cyan       = "#81c8be";
    red        = "#e78284";
    red_bright = "#e78284";
    green      = "#a6d189";
    green_bright = "#a6d189";
    yellow     = "#e5c890";
    orange     = "#ef9f76";
    magenta    = "#f4b8e4";
    purple     = "#ca9ee6";
    blue       = "#8caaee";
    white      = "#c6d0f5";
    selection   = "#51576d";
    cursor      = "#f2d5cf";
    line        = "#626880";
    current     = "#292c3c";
    current_nr  = "#c6d0f5";
  };

  starship = {
    background        = "#303446";
    dark_background   = "#292c3c";
    second_background = "#363a4f";
    third_background  = "#414559";
    fourth_background = "#51576d";
    foreground        = "#c6d0f5";
    current           = "#292c3c";
    selection         = "#51576d";
    cursor            = "#f2d5cf";
    line              = "#626880";
    current_number    = "#c6d0f5";
    cyan              = "#81c8be";
    gray              = "#737994";
    red               = "#e78284";
    error_red         = "#e78284";
    green             = "#a6d189";
    lime              = "#a6d189";
    blue              = "#8caaee";
    orange            = "#ef9f76";
    magenta           = "#f4b8e4";
    white             = "#c6d0f5";
    bright            = "#626880";
    purple            = "#ca9ee6";
    yellow            = "#e5c890";
  };
}
