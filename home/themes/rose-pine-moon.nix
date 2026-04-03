{
  name = "rose-pine-moon";
  slug = "rose_pine_moon";

  apps = {
    nvim = "rose-pine-moon";
    nvimPlugin = "rose-pine";
    nvimSetup = ''require("rose-pine").setup({ variant = "moon" })'';
    lualine = "auto";
    vscode = "Rose Pine Moon";
    bat = "Nord";
    batBuiltin = true;
  };

  terminal = {
    foreground = "#e0def4";
    background = "#232136";
    cursor = "#56526e";
    selection_fg = "#e0def4";
    selection_bg = "#44415a";

    color0  = "#393552";
    color1  = "#eb6f92";
    color2  = "#3e8fb0";
    color3  = "#f6c177";
    color4  = "#9ccfd8";
    color5  = "#c4a7e7";
    color6  = "#ea9a97";
    color7  = "#e0def4";

    color8  = "#6e6a86";
    color9  = "#eb6f92";
    color10 = "#3e8fb0";
    color11 = "#f6c177";
    color12 = "#9ccfd8";
    color13 = "#c4a7e7";
    color14 = "#ea9a97";
    color15 = "#e0def4";
  };

  palette = {
    bg         = "#232136";
    bg_dark    = "#1f1d2e";
    bg_light   = "#2a273f";
    bg2        = "#2a273f";
    bg3        = "#393552";
    bg4        = "#44415a";
    fg         = "#e0def4";
    fg_dim     = "#6e6a86";
    accent     = "#c4a7e7";
    cyan       = "#9ccfd8";
    red        = "#eb6f92";
    red_bright = "#eb6f92";
    green      = "#3e8fb0";
    green_bright = "#3e8fb0";
    yellow     = "#f6c177";
    orange     = "#ea9a97";
    magenta    = "#c4a7e7";
    purple     = "#c4a7e7";
    blue       = "#9ccfd8";
    white      = "#e0def4";
    selection   = "#44415a";
    cursor      = "#56526e";
    line        = "#44415a";
    current     = "#1f1d2e";
    current_nr  = "#e0def4";
  };

  starship = {
    background        = "#232136";
    dark_background   = "#1f1d2e";
    second_background = "#2a273f";
    third_background  = "#393552";
    fourth_background = "#44415a";
    foreground        = "#e0def4";
    current           = "#1f1d2e";
    selection         = "#44415a";
    cursor            = "#56526e";
    line              = "#44415a";
    current_number    = "#e0def4";
    cyan              = "#9ccfd8";
    gray              = "#6e6a86";
    red               = "#eb6f92";
    error_red         = "#eb6f92";
    green             = "#3e8fb0";
    lime              = "#3e8fb0";
    blue              = "#9ccfd8";
    orange            = "#ea9a97";
    magenta           = "#c4a7e7";
    white             = "#e0def4";
    bright            = "#6e6a86";
    purple            = "#c4a7e7";
    yellow            = "#f6c177";
  };
}
