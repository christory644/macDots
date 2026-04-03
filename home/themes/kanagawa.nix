{
  name = "kanagawa";
  slug = "kanagawa";

  apps = {
    nvim = "kanagawa-wave";
    nvimPlugin = "kanagawa-nvim";
    nvimSetup = ''require("kanagawa").setup({ theme = "wave" })'';
    lualine = "auto";
    vscode = "Kanagawa";
    bat = "gruvbox-dark";
    batBuiltin = true;
  };

  terminal = {
    foreground = "#dcd7ba";
    background = "#1f1f28";
    cursor = "#c8c093";
    selection_fg = "#dcd7ba";
    selection_bg = "#2d4f67";

    color0  = "#16161d";
    color1  = "#c34043";
    color2  = "#76946a";
    color3  = "#c0a36e";
    color4  = "#7e9cd8";
    color5  = "#957fb8";
    color6  = "#6a9589";
    color7  = "#c8c093";

    color8  = "#727169";
    color9  = "#e82424";
    color10 = "#98bb6c";
    color11 = "#e6c384";
    color12 = "#7fb4ca";
    color13 = "#938aa9";
    color14 = "#7aa89f";
    color15 = "#dcd7ba";
  };

  palette = {
    bg         = "#1f1f28";
    bg_dark    = "#16161d";
    bg_light   = "#2a2a37";
    bg2        = "#223249";
    bg3        = "#2d4f67";
    bg4        = "#363646";
    fg         = "#dcd7ba";
    fg_dim     = "#727169";
    accent     = "#7e9cd8";
    cyan       = "#6a9589";
    red        = "#c34043";
    red_bright = "#e82424";
    green      = "#76946a";
    green_bright = "#98bb6c";
    yellow     = "#c0a36e";
    orange     = "#ffa066";
    magenta    = "#957fb8";
    purple     = "#938aa9";
    blue       = "#7e9cd8";
    white      = "#dcd7ba";
    selection   = "#2d4f67";
    cursor      = "#c8c093";
    line        = "#363646";
    current     = "#16161d";
    current_nr  = "#dcd7ba";
  };

  starship = {
    background        = "#1f1f28";
    dark_background   = "#16161d";
    second_background = "#223249";
    third_background  = "#2a2a37";
    fourth_background = "#363646";
    foreground        = "#dcd7ba";
    current           = "#16161d";
    selection         = "#2d4f67";
    cursor            = "#c8c093";
    line              = "#363646";
    current_number    = "#dcd7ba";
    cyan              = "#6a9589";
    gray              = "#727169";
    red               = "#e82424";
    error_red         = "#c34043";
    green             = "#76946a";
    lime              = "#98bb6c";
    blue              = "#7e9cd8";
    orange            = "#ffa066";
    magenta           = "#957fb8";
    white             = "#dcd7ba";
    bright            = "#727169";
    purple            = "#938aa9";
    yellow            = "#c0a36e";
  };
}
