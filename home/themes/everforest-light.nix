{
  name = "everforest-light";
  slug = "everforest_light";

  apps = {
    nvim = "everforest";
    nvimPlugin = "everforest";
    nvimSetup = ''vim.g.everforest_background = "hard"; vim.o.background = "light"; vim.g.everforest_enable_italic = 1'';
    lualine = "everforest";
    vscode = "Everforest Light";
    bat = "gruvbox-light";
    batBuiltin = true;
  };

  terminal = {
    foreground = "#5c6a72";
    background = "#fff9e8";
    cursor = "#5c6a72";
    selection_fg = "#5c6a72";
    selection_bg = "#e0dcc7";

    color0  = "#5c6a72";
    color1  = "#f85552";
    color2  = "#8da101";
    color3  = "#dfa000";
    color4  = "#3a94c5";
    color5  = "#df69ba";
    color6  = "#35a77c";
    color7  = "#dfddc8";

    color8  = "#939f91";
    color9  = "#f85552";
    color10 = "#8da101";
    color11 = "#dfa000";
    color12 = "#3a94c5";
    color13 = "#df69ba";
    color14 = "#35a77c";
    color15 = "#fff9e8";
  };

  palette = {
    bg         = "#fff9e8";
    bg_dark    = "#f3efda";
    bg_light   = "#edeada";
    bg2        = "#f3efda";
    bg3        = "#edeada";
    bg4        = "#e0dcc7";
    fg         = "#5c6a72";
    fg_dim     = "#939f91";
    accent     = "#3a94c5";
    cyan       = "#35a77c";
    red        = "#f85552";
    red_bright = "#f85552";
    green      = "#8da101";
    green_bright = "#8da101";
    yellow     = "#dfa000";
    orange     = "#f57d26";
    magenta    = "#df69ba";
    purple     = "#df69ba";
    blue       = "#3a94c5";
    white      = "#5c6a72";
    selection   = "#e0dcc7";
    cursor      = "#5c6a72";
    line        = "#e0dcc7";
    current     = "#f3efda";
    current_nr  = "#5c6a72";
  };

  starship = {
    background        = "#fff9e8";
    dark_background   = "#f3efda";
    second_background = "#f3efda";
    third_background  = "#edeada";
    fourth_background = "#e0dcc7";
    foreground        = "#5c6a72";
    current           = "#f3efda";
    selection         = "#e0dcc7";
    cursor            = "#5c6a72";
    line              = "#e0dcc7";
    current_number    = "#5c6a72";
    cyan              = "#35a77c";
    gray              = "#939f91";
    red               = "#f85552";
    error_red         = "#f85552";
    green             = "#8da101";
    lime              = "#8da101";
    blue              = "#3a94c5";
    orange            = "#f57d26";
    magenta           = "#df69ba";
    white             = "#5c6a72";
    bright            = "#939f91";
    purple            = "#df69ba";
    yellow            = "#dfa000";
  };
}
