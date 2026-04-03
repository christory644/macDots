{
  name = "rose-pine-dawn";
  slug = "rose_pine_dawn";

  apps = {
    nvim = "rose-pine-dawn";
    nvimPlugin = "rose-pine";
    nvimSetup = ''require("rose-pine").setup({ variant = "dawn" })'';
    lualine = "auto";
    vscode = "Rose Pine Dawn";
    bat = "OneHalfLight";
    batBuiltin = true;
  };

  terminal = {
    foreground = "#575279";
    background = "#faf4ed";
    cursor = "#cecacd";
    selection_fg = "#575279";
    selection_bg = "#dfdad9";

    color0  = "#f2e9e1";
    color1  = "#b4637a";
    color2  = "#286983";
    color3  = "#ea9d34";
    color4  = "#56949f";
    color5  = "#907aa9";
    color6  = "#d7827e";
    color7  = "#575279";

    color8  = "#9893a5";
    color9  = "#b4637a";
    color10 = "#286983";
    color11 = "#ea9d34";
    color12 = "#56949f";
    color13 = "#907aa9";
    color14 = "#d7827e";
    color15 = "#575279";
  };

  palette = {
    bg         = "#faf4ed";
    bg_dark    = "#f2e9e1";
    bg_light   = "#f2e9de";
    bg2        = "#f2e9e1";
    bg3        = "#dfdad9";
    bg4        = "#cecacd";
    fg         = "#575279";
    fg_dim     = "#9893a5";
    accent     = "#907aa9";
    cyan       = "#56949f";
    red        = "#b4637a";
    red_bright = "#b4637a";
    green      = "#286983";
    green_bright = "#286983";
    yellow     = "#ea9d34";
    orange     = "#d7827e";
    magenta    = "#907aa9";
    purple     = "#907aa9";
    blue       = "#56949f";
    white      = "#575279";
    selection   = "#dfdad9";
    cursor      = "#cecacd";
    line        = "#cecacd";
    current     = "#f2e9e1";
    current_nr  = "#575279";
  };

  starship = {
    background        = "#faf4ed";
    dark_background   = "#f2e9e1";
    second_background = "#f2e9e1";
    third_background  = "#dfdad9";
    fourth_background = "#cecacd";
    foreground        = "#575279";
    current           = "#f2e9e1";
    selection         = "#dfdad9";
    cursor            = "#cecacd";
    line              = "#cecacd";
    current_number    = "#575279";
    cyan              = "#56949f";
    gray              = "#9893a5";
    red               = "#b4637a";
    error_red         = "#b4637a";
    green             = "#286983";
    lime              = "#286983";
    blue              = "#56949f";
    orange            = "#d7827e";
    magenta           = "#907aa9";
    white             = "#575279";
    bright            = "#9893a5";
    purple            = "#907aa9";
    yellow            = "#ea9d34";
  };
}
