{
  name = "gruvbox-light";
  slug = "gruvbox_light";

  apps = {
    nvim = "gruvbox-material";
    nvimPlugin = "gruvbox-material";
    nvimSetup = ''vim.g.gruvbox_material_background = "hard"; vim.g.gruvbox_material_foreground = "material"; vim.o.background = "light"'';
    lualine = "gruvbox-material";
    vscode = "Gruvbox Material Light";
    bat = "gruvbox-light";
    batBuiltin = true;
  };

  terminal = {
    foreground = "#654735";
    background = "#f9f5d7";
    cursor = "#654735";
    selection_fg = "#654735";
    selection_bg = "#e0cfa9";

    color0  = "#654735";
    color1  = "#c14a4a";
    color2  = "#6c782e";
    color3  = "#b47109";
    color4  = "#45707a";
    color5  = "#945e80";
    color6  = "#4c7a5d";
    color7  = "#eee0b7";

    color8  = "#a89984";
    color9  = "#c14a4a";
    color10 = "#6c782e";
    color11 = "#b47109";
    color12 = "#45707a";
    color13 = "#945e80";
    color14 = "#4c7a5d";
    color15 = "#f9f5d7";
  };

  palette = {
    bg         = "#f9f5d7";
    bg_dark    = "#f2e5bc";
    bg_light   = "#ebdbb2";
    bg2        = "#f2e5bc";
    bg3        = "#ebdbb2";
    bg4        = "#e0cfa9";
    fg         = "#654735";
    fg_dim     = "#a89984";
    accent     = "#45707a";
    cyan       = "#4c7a5d";
    red        = "#c14a4a";
    red_bright = "#c14a4a";
    green      = "#6c782e";
    green_bright = "#6c782e";
    yellow     = "#b47109";
    orange     = "#c35e0a";
    magenta    = "#945e80";
    purple     = "#945e80";
    blue       = "#45707a";
    white      = "#654735";
    selection   = "#e0cfa9";
    cursor      = "#654735";
    line        = "#e0cfa9";
    current     = "#f2e5bc";
    current_nr  = "#654735";
  };

  starship = {
    background        = "#f9f5d7";
    dark_background   = "#f2e5bc";
    second_background = "#f2e5bc";
    third_background  = "#ebdbb2";
    fourth_background = "#e0cfa9";
    foreground        = "#654735";
    current           = "#f2e5bc";
    selection         = "#e0cfa9";
    cursor            = "#654735";
    line              = "#e0cfa9";
    current_number    = "#654735";
    cyan              = "#4c7a5d";
    gray              = "#a89984";
    red               = "#c14a4a";
    error_red         = "#c14a4a";
    green             = "#6c782e";
    lime              = "#6c782e";
    blue              = "#45707a";
    orange            = "#c35e0a";
    magenta           = "#945e80";
    white             = "#654735";
    bright            = "#a89984";
    purple            = "#945e80";
    yellow            = "#b47109";
  };
}
