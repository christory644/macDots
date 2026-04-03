{
  name = "gruvbox-dark";
  slug = "gruvbox_dark";

  apps = {
    nvim = "gruvbox-material";
    nvimPlugin = "gruvbox-material";
    nvimSetup = ''vim.g.gruvbox_material_background = "hard"; vim.g.gruvbox_material_foreground = "material"'';
    lualine = "gruvbox-material";
    vscode = "Gruvbox Material Dark";
    bat = "gruvbox-dark";
    batBuiltin = true;
  };

  terminal = {
    foreground = "#d4be98";
    background = "#1d2021";
    cursor = "#d4be98";
    selection_fg = "#d4be98";
    selection_bg = "#45403d";

    color0  = "#282828";
    color1  = "#ea6962";
    color2  = "#a9b665";
    color3  = "#d8a657";
    color4  = "#7daea3";
    color5  = "#d3869b";
    color6  = "#89b482";
    color7  = "#d4be98";

    color8  = "#928374";
    color9  = "#ea6962";
    color10 = "#a9b665";
    color11 = "#d8a657";
    color12 = "#7daea3";
    color13 = "#d3869b";
    color14 = "#89b482";
    color15 = "#d4be98";
  };

  palette = {
    bg         = "#1d2021";
    bg_dark    = "#141617";
    bg_light   = "#32302f";
    bg2        = "#282828";
    bg3        = "#32302f";
    bg4        = "#45403d";
    fg         = "#d4be98";
    fg_dim     = "#928374";
    accent     = "#d8a657";
    cyan       = "#89b482";
    red        = "#ea6962";
    red_bright = "#ea6962";
    green      = "#a9b665";
    green_bright = "#a9b665";
    yellow     = "#d8a657";
    orange     = "#e78a4e";
    magenta    = "#d3869b";
    purple     = "#d3869b";
    blue       = "#7daea3";
    white      = "#d4be98";
    selection   = "#45403d";
    cursor      = "#d4be98";
    line        = "#45403d";
    current     = "#141617";
    current_nr  = "#d4be98";
  };

  starship = {
    background        = "#1d2021";
    dark_background   = "#141617";
    second_background = "#282828";
    third_background  = "#32302f";
    fourth_background = "#45403d";
    foreground        = "#d4be98";
    current           = "#141617";
    selection         = "#45403d";
    cursor            = "#d4be98";
    line              = "#45403d";
    current_number    = "#d4be98";
    cyan              = "#89b482";
    gray              = "#928374";
    red               = "#ea6962";
    error_red         = "#ea6962";
    green             = "#a9b665";
    lime              = "#a9b665";
    blue              = "#7daea3";
    orange            = "#e78a4e";
    magenta           = "#d3869b";
    white             = "#d4be98";
    bright            = "#928374";
    purple            = "#d3869b";
    yellow            = "#d8a657";
  };
}
