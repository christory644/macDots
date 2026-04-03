{
  name = "catppuccin-latte";
  slug = "catppuccin_latte";

  apps = {
    nvim = "catppuccin-latte";
    nvimPlugin = "catppuccin-nvim";
    nvimSetup = ''require("catppuccin").setup({ flavour = "latte" })'';
    lualine = "catppuccin";
    vscode = "Catppuccin Latte";
    bat = "Catppuccin Latte";
    batBuiltin = true;
  };

  terminal = {
    foreground = "#4c4f69";
    background = "#eff1f5";
    cursor = "#dc8a78";
    selection_fg = "#4c4f69";
    selection_bg = "#acb0be";

    color0  = "#5c5f77";
    color1  = "#d20f39";
    color2  = "#40a02b";
    color3  = "#df8e1d";
    color4  = "#1e66f5";
    color5  = "#ea76cb";
    color6  = "#179299";
    color7  = "#acb0be";

    color8  = "#6c6f85";
    color9  = "#d20f39";
    color10 = "#40a02b";
    color11 = "#df8e1d";
    color12 = "#1e66f5";
    color13 = "#ea76cb";
    color14 = "#179299";
    color15 = "#bcc0cc";
  };

  palette = {
    bg         = "#eff1f5";
    bg_dark    = "#e6e9ef";
    bg_light   = "#ccd0da";
    bg2        = "#dce0e8";
    bg3        = "#ccd0da";
    bg4        = "#bcc0cc";
    fg         = "#4c4f69";
    fg_dim     = "#6c6f85";
    accent     = "#1e66f5";
    cyan       = "#179299";
    red        = "#d20f39";
    red_bright = "#d20f39";
    green      = "#40a02b";
    green_bright = "#40a02b";
    yellow     = "#df8e1d";
    orange     = "#fe640b";
    magenta    = "#ea76cb";
    purple     = "#8839ef";
    blue       = "#1e66f5";
    white      = "#4c4f69";
    selection   = "#acb0be";
    cursor      = "#dc8a78";
    line        = "#bcc0cc";
    current     = "#e6e9ef";
    current_nr  = "#4c4f69";
  };

  starship = {
    background        = "#eff1f5";
    dark_background   = "#e6e9ef";
    second_background = "#dce0e8";
    third_background  = "#ccd0da";
    fourth_background = "#bcc0cc";
    foreground        = "#4c4f69";
    current           = "#e6e9ef";
    selection         = "#acb0be";
    cursor            = "#dc8a78";
    line              = "#bcc0cc";
    current_number    = "#4c4f69";
    cyan              = "#179299";
    gray              = "#6c6f85";
    red               = "#d20f39";
    error_red         = "#d20f39";
    green             = "#40a02b";
    lime              = "#40a02b";
    blue              = "#1e66f5";
    orange            = "#fe640b";
    magenta           = "#ea76cb";
    white             = "#4c4f69";
    bright            = "#9ca0b0";
    purple            = "#8839ef";
    yellow            = "#df8e1d";
  };
}
