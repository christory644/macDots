{
  name = "github-light";
  slug = "github_light";

  apps = {
    nvim = "github_light";
    nvimPlugin = "github-nvim-theme";
    nvimSetup = ''require("github-theme").setup({})'';
    lualine = "auto";
    vscode = "GitHub Light Default";
    bat = "GitHub";
    batBuiltin = true;
  };

  terminal = {
    foreground = "#24292f";
    background = "#ffffff";
    cursor = "#044289";
    selection_fg = "#24292f";
    selection_bg = "#dbe9f9";

    color0  = "#24292e";
    color1  = "#d73a49";
    color2  = "#28a745";
    color3  = "#dbab09";
    color4  = "#0366d6";
    color5  = "#5a32a3";
    color6  = "#0598bc";
    color7  = "#6a737d";

    color8  = "#959da5";
    color9  = "#cb2431";
    color10 = "#22863a";
    color11 = "#b08800";
    color12 = "#005cc5";
    color13 = "#5a32a3";
    color14 = "#3192aa";
    color15 = "#d1d5da";
  };

  palette = {
    bg         = "#ffffff";
    bg_dark    = "#f6f8fa";
    bg_light   = "#eaeef2";
    bg2        = "#f6f8fa";
    bg3        = "#eaeef2";
    bg4        = "#d0d7de";
    fg         = "#24292f";
    fg_dim     = "#6e7781";
    accent     = "#0366d6";
    cyan       = "#0598bc";
    red        = "#d73a49";
    red_bright = "#cb2431";
    green      = "#28a745";
    green_bright = "#22863a";
    yellow     = "#dbab09";
    orange     = "#d15704";
    magenta    = "#5a32a3";
    purple     = "#5a32a3";
    blue       = "#0366d6";
    white      = "#24292f";
    selection   = "#dbe9f9";
    cursor      = "#044289";
    line        = "#d0d7de";
    current     = "#f6f8fa";
    current_nr  = "#24292f";
  };

  starship = {
    background        = "#ffffff";
    dark_background   = "#f6f8fa";
    second_background = "#f6f8fa";
    third_background  = "#eaeef2";
    fourth_background = "#d0d7de";
    foreground        = "#24292f";
    current           = "#f6f8fa";
    selection         = "#dbe9f9";
    cursor            = "#044289";
    line              = "#d0d7de";
    current_number    = "#24292f";
    cyan              = "#0598bc";
    gray              = "#6e7781";
    red               = "#d73a49";
    error_red         = "#cb2431";
    green             = "#28a745";
    lime              = "#22863a";
    blue              = "#0366d6";
    orange            = "#d15704";
    magenta           = "#5a32a3";
    white             = "#24292f";
    bright            = "#959da5";
    purple            = "#5a32a3";
    yellow            = "#dbab09";
  };
}
