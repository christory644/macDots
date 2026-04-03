{
  name = "everforest-dark";
  slug = "everforest_dark";

  apps = {
    nvim = "everforest";
    nvimPlugin = "everforest";
    nvimSetup = ''vim.g.everforest_background = "hard"; vim.g.everforest_enable_italic = 1'';
    lualine = "everforest";
    vscode = "Everforest Dark";
    bat = "gruvbox-dark";
    batBuiltin = true;
  };

  terminal = {
    foreground = "#d3c6aa";
    background = "#272e33";
    cursor = "#d3c6aa";
    selection_fg = "#d3c6aa";
    selection_bg = "#425047";

    color0  = "#343f44";
    color1  = "#e67e80";
    color2  = "#a7c080";
    color3  = "#dbbc7f";
    color4  = "#7fbbb3";
    color5  = "#d699b6";
    color6  = "#83c092";
    color7  = "#d3c6aa";

    color8  = "#475258";
    color9  = "#e67e80";
    color10 = "#a7c080";
    color11 = "#dbbc7f";
    color12 = "#7fbbb3";
    color13 = "#d699b6";
    color14 = "#83c092";
    color15 = "#d3c6aa";
  };

  palette = {
    bg         = "#272e33";
    bg_dark    = "#1e2326";
    bg_light   = "#343f44";
    bg2        = "#2e383c";
    bg3        = "#343f44";
    bg4        = "#425047";
    fg         = "#d3c6aa";
    fg_dim     = "#859289";
    accent     = "#a7c080";
    cyan       = "#83c092";
    red        = "#e67e80";
    red_bright = "#e67e80";
    green      = "#a7c080";
    green_bright = "#a7c080";
    yellow     = "#dbbc7f";
    orange     = "#e69875";
    magenta    = "#d699b6";
    purple     = "#d699b6";
    blue       = "#7fbbb3";
    white      = "#d3c6aa";
    selection   = "#425047";
    cursor      = "#d3c6aa";
    line        = "#475258";
    current     = "#1e2326";
    current_nr  = "#d3c6aa";
  };

  starship = {
    background        = "#272e33";
    dark_background   = "#1e2326";
    second_background = "#2e383c";
    third_background  = "#343f44";
    fourth_background = "#425047";
    foreground        = "#d3c6aa";
    current           = "#1e2326";
    selection         = "#425047";
    cursor            = "#d3c6aa";
    line              = "#475258";
    current_number    = "#d3c6aa";
    cyan              = "#83c092";
    gray              = "#859289";
    red               = "#e67e80";
    error_red         = "#e67e80";
    green             = "#a7c080";
    lime              = "#a7c080";
    blue              = "#7fbbb3";
    orange            = "#e69875";
    magenta           = "#d699b6";
    white             = "#d3c6aa";
    bright            = "#859289";
    purple            = "#d699b6";
    yellow            = "#dbbc7f";
  };
}
