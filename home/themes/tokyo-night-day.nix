{
  name = "tokyo-night-day";
  slug = "tokyo_night_day";

  apps = {
    nvim = "tokyonight-day";
    nvimPlugin = "tokyonight-nvim";
    nvimSetup = ''require("tokyonight").setup({ style = "day" })'';
    lualine = "tokyonight";
    vscode = "Tokyo Night Light";
    bat = "OneHalfLight";
    batBuiltin = true;
  };

  terminal = {
    foreground = "#3760bf";
    background = "#e1e2e7";
    cursor = "#3760bf";
    selection_fg = "#3760bf";
    selection_bg = "#b6bfe2";

    color0  = "#e9e9ed";
    color1  = "#f52a65";
    color2  = "#587539";
    color3  = "#8c6c3e";
    color4  = "#2e7de9";
    color5  = "#9854f1";
    color6  = "#007197";
    color7  = "#6172b0";

    color8  = "#a1a6c5";
    color9  = "#f52a65";
    color10 = "#587539";
    color11 = "#8c6c3e";
    color12 = "#2e7de9";
    color13 = "#9854f1";
    color14 = "#007197";
    color15 = "#3760bf";
  };

  palette = {
    bg         = "#e1e2e7";
    bg_dark    = "#d0d5e3";
    bg_light   = "#c4c8da";
    bg2        = "#d4d6e4";
    bg3        = "#c4c8da";
    bg4        = "#b6bfe2";
    fg         = "#3760bf";
    fg_dim     = "#a1a6c5";
    accent     = "#2e7de9";
    cyan       = "#007197";
    red        = "#f52a65";
    red_bright = "#f52a65";
    green      = "#587539";
    green_bright = "#587539";
    yellow     = "#8c6c3e";
    orange     = "#b15c00";
    magenta    = "#9854f1";
    purple     = "#7847bd";
    blue       = "#2e7de9";
    white      = "#3760bf";
    selection   = "#b6bfe2";
    cursor      = "#3760bf";
    line        = "#c4c8da";
    current     = "#d0d5e3";
    current_nr  = "#3760bf";
  };

  starship = {
    background        = "#e1e2e7";
    dark_background   = "#d0d5e3";
    second_background = "#d4d6e4";
    third_background  = "#c4c8da";
    fourth_background = "#b6bfe2";
    foreground        = "#3760bf";
    current           = "#d0d5e3";
    selection         = "#b6bfe2";
    cursor            = "#3760bf";
    line              = "#c4c8da";
    current_number    = "#3760bf";
    cyan              = "#007197";
    gray              = "#a1a6c5";
    red               = "#f52a65";
    error_red         = "#f52a65";
    green             = "#587539";
    lime              = "#587539";
    blue              = "#2e7de9";
    orange            = "#b15c00";
    magenta           = "#9854f1";
    white             = "#3760bf";
    bright            = "#a1a6c5";
    purple            = "#7847bd";
    yellow            = "#8c6c3e";
  };
}
