{
  name = "catppuccin-macchiato";
  slug = "catppuccin_macchiato";

  apps = {
    nvim = "catppuccin-macchiato";
    nvimPlugin = "catppuccin-nvim";
    nvimSetup = ''require("catppuccin").setup({ flavour = "macchiato" })'';
    lualine = "catppuccin";
    vscode = "Catppuccin Macchiato";
    bat = "Catppuccin Macchiato";
    batBuiltin = true;
  };

  terminal = {
    foreground = "#cad3f5";
    background = "#24273a";
    cursor = "#f4dbd6";
    selection_fg = "#cad3f5";
    selection_bg = "#494d64";

    color0  = "#494d64";
    color1  = "#ed8796";
    color2  = "#a6da95";
    color3  = "#eed49f";
    color4  = "#8aadf4";
    color5  = "#f5bde6";
    color6  = "#8bd5ca";
    color7  = "#b8c0e0";

    color8  = "#5b6078";
    color9  = "#ed8796";
    color10 = "#a6da95";
    color11 = "#eed49f";
    color12 = "#8aadf4";
    color13 = "#f5bde6";
    color14 = "#8bd5ca";
    color15 = "#a5adcb";
  };

  palette = {
    bg         = "#24273a";
    bg_dark    = "#1e2030";
    bg_light   = "#363a4f";
    bg2        = "#2a2d42";
    bg3        = "#363a4f";
    bg4        = "#494d64";
    fg         = "#cad3f5";
    fg_dim     = "#a5adcb";
    accent     = "#8aadf4";
    cyan       = "#8bd5ca";
    red        = "#ed8796";
    red_bright = "#ed8796";
    green      = "#a6da95";
    green_bright = "#a6da95";
    yellow     = "#eed49f";
    orange     = "#f5a97f";
    magenta    = "#f5bde6";
    purple     = "#c6a0f6";
    blue       = "#8aadf4";
    white      = "#cad3f5";
    selection   = "#494d64";
    cursor      = "#f4dbd6";
    line        = "#5b6078";
    current     = "#1e2030";
    current_nr  = "#cad3f5";
  };

  starship = {
    background        = "#24273a";
    dark_background   = "#1e2030";
    second_background = "#2a2d42";
    third_background  = "#363a4f";
    fourth_background = "#494d64";
    foreground        = "#cad3f5";
    current           = "#1e2030";
    selection         = "#494d64";
    cursor            = "#f4dbd6";
    line              = "#5b6078";
    current_number    = "#cad3f5";
    cyan              = "#8bd5ca";
    gray              = "#6e738d";
    red               = "#ed8796";
    error_red         = "#ed8796";
    green             = "#a6da95";
    lime              = "#a6da95";
    blue              = "#8aadf4";
    orange            = "#f5a97f";
    magenta           = "#f5bde6";
    white             = "#cad3f5";
    bright            = "#5b6078";
    purple            = "#c6a0f6";
    yellow            = "#eed49f";
  };
}
