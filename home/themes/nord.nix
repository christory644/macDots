{
  name = "nord";
  slug = "nord";

  apps = {
    nvim = "nordfox";
    nvimPlugin = "nightfox-nvim";
    nvimSetup = ''require("nightfox").setup({})'';
    lualine = "nightfox";
    vscode = "Nord";
    bat = "Nord";
    batBuiltin = true;
  };

  terminal = {
    foreground = "#d8dee9";
    background = "#2e3440";
    cursor = "#d8dee9";
    selection_fg = "#d8dee9";
    selection_bg = "#434c5e";

    color0  = "#3b4252";
    color1  = "#bf616a";
    color2  = "#a3be8c";
    color3  = "#ebcb8b";
    color4  = "#81a1c1";
    color5  = "#b48ead";
    color6  = "#88c0d0";
    color7  = "#e5e9f0";

    color8  = "#4c566a";
    color9  = "#bf616a";
    color10 = "#a3be8c";
    color11 = "#ebcb8b";
    color12 = "#81a1c1";
    color13 = "#b48ead";
    color14 = "#8fbcbb";
    color15 = "#eceff4";
  };

  palette = {
    bg         = "#2e3440";
    bg_dark    = "#242933";
    bg_light   = "#3b4252";
    bg2        = "#353b49";
    bg3        = "#3b4252";
    bg4        = "#434c5e";
    fg         = "#d8dee9";
    fg_dim     = "#4c566a";
    accent     = "#81a1c1";
    cyan       = "#88c0d0";
    red        = "#bf616a";
    red_bright = "#bf616a";
    green      = "#a3be8c";
    green_bright = "#a3be8c";
    yellow     = "#ebcb8b";
    orange     = "#d08770";
    magenta    = "#b48ead";
    purple     = "#b48ead";
    blue       = "#81a1c1";
    white      = "#eceff4";
    selection   = "#434c5e";
    cursor      = "#d8dee9";
    line        = "#434c5e";
    current     = "#242933";
    current_nr  = "#d8dee9";
  };

  starship = {
    background        = "#2e3440";
    dark_background   = "#242933";
    second_background = "#353b49";
    third_background  = "#3b4252";
    fourth_background = "#434c5e";
    foreground        = "#d8dee9";
    current           = "#242933";
    selection         = "#434c5e";
    cursor            = "#d8dee9";
    line              = "#434c5e";
    current_number    = "#d8dee9";
    cyan              = "#88c0d0";
    gray              = "#4c566a";
    red               = "#bf616a";
    error_red         = "#bf616a";
    green             = "#a3be8c";
    lime              = "#a3be8c";
    blue              = "#81a1c1";
    orange            = "#d08770";
    magenta           = "#b48ead";
    white             = "#eceff4";
    bright            = "#4c566a";
    purple            = "#b48ead";
    yellow            = "#ebcb8b";
  };
}
