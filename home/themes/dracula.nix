{
  name = "dracula";
  slug = "dracula";

  apps = {
    nvim = "dracula";
    nvimPlugin = "dracula-nvim";
    nvimSetup = ''require("dracula").setup({})'';
    lualine = "dracula";
    vscode = "Dracula";
    bat = "Dracula";
    batBuiltin = true;
  };

  terminal = {
    foreground = "#f8f8f2";
    background = "#282a36";
    cursor = "#f8f8f2";
    selection_fg = "#f8f8f2";
    selection_bg = "#44475a";

    color0  = "#21222c";
    color1  = "#ff5555";
    color2  = "#50fa7b";
    color3  = "#f1fa8c";
    color4  = "#bd93f9";
    color5  = "#ff79c6";
    color6  = "#8be9fd";
    color7  = "#f8f8f2";

    color8  = "#6272a4";
    color9  = "#ff6e6e";
    color10 = "#69ff94";
    color11 = "#ffffa5";
    color12 = "#d6acff";
    color13 = "#ff92df";
    color14 = "#a4ffff";
    color15 = "#ffffff";
  };

  palette = {
    bg         = "#282a36";
    bg_dark    = "#21222c";
    bg_light   = "#343746";
    bg2        = "#2c2e3b";
    bg3        = "#343746";
    bg4        = "#44475a";
    fg         = "#f8f8f2";
    fg_dim     = "#6272a4";
    accent     = "#bd93f9";
    cyan       = "#8be9fd";
    red        = "#ff5555";
    red_bright = "#ff6e6e";
    green      = "#50fa7b";
    green_bright = "#69ff94";
    yellow     = "#f1fa8c";
    orange     = "#ffb86c";
    magenta    = "#ff79c6";
    purple     = "#bd93f9";
    blue       = "#bd93f9";
    white      = "#f8f8f2";
    selection   = "#44475a";
    cursor      = "#f8f8f2";
    line        = "#44475a";
    current     = "#21222c";
    current_nr  = "#f8f8f2";
  };

  starship = {
    background        = "#282a36";
    dark_background   = "#21222c";
    second_background = "#2c2e3b";
    third_background  = "#343746";
    fourth_background = "#44475a";
    foreground        = "#f8f8f2";
    current           = "#21222c";
    selection         = "#44475a";
    cursor            = "#f8f8f2";
    line              = "#44475a";
    current_number    = "#f8f8f2";
    cyan              = "#8be9fd";
    gray              = "#6272a4";
    red               = "#ff5555";
    error_red         = "#ff5555";
    green             = "#50fa7b";
    lime              = "#69ff94";
    blue              = "#bd93f9";
    orange            = "#ffb86c";
    magenta           = "#ff79c6";
    white             = "#f8f8f2";
    bright            = "#6272a4";
    purple            = "#bd93f9";
    yellow            = "#f1fa8c";
  };
}
