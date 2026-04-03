{
  name = "catppuccin-mocha";
  slug = "catppuccin_mocha";

  apps = {
    nvim = "catppuccin";
    nvimPlugin = "catppuccin-nvim";
    nvimSetup = ''require("catppuccin").setup({ flavour = "mocha" })'';
    lualine = "catppuccin";
    vscode = "Catppuccin Mocha";
    bat = "Catppuccin Mocha";
    batBuiltin = true;  # catppuccin ships with bat
  };

  terminal = {
    foreground = "#cdd6f4";
    background = "#1e1e2e";
    cursor = "#f5e0dc";
    selection_fg = "#cdd6f4";
    selection_bg = "#45475a";

    color0  = "#45475a";  # surface1
    color1  = "#f38ba8";  # red
    color2  = "#a6e3a1";  # green
    color3  = "#f9e2af";  # yellow
    color4  = "#89b4fa";  # blue
    color5  = "#f5c2e7";  # pink
    color6  = "#94e2d5";  # teal
    color7  = "#bac2de";  # subtext1

    color8  = "#585b70";  # surface2
    color9  = "#f38ba8";  # red
    color10 = "#a6e3a1";  # green
    color11 = "#f9e2af";  # yellow
    color12 = "#89b4fa";  # blue
    color13 = "#f5c2e7";  # pink
    color14 = "#94e2d5";  # teal
    color15 = "#a6adc8";  # subtext0
  };

  palette = {
    bg        = "#1e1e2e";
    bg_dark   = "#181825";
    bg_light  = "#313244";
    bg2       = "#252536";
    bg3       = "#313244";
    bg4       = "#45475a";
    fg        = "#cdd6f4";
    fg_dim    = "#a6adc8";
    accent    = "#89b4fa";
    cyan      = "#94e2d5";
    red       = "#f38ba8";
    red_bright = "#f38ba8";
    green     = "#a6e3a1";
    green_bright = "#a6e3a1";
    yellow    = "#f9e2af";
    orange    = "#fab387";
    magenta   = "#f5c2e7";
    purple    = "#cba6f7";
    blue      = "#89b4fa";
    white     = "#cdd6f4";
    selection  = "#45475a";
    cursor     = "#f5e0dc";
    line       = "#585b70";
    current    = "#181825";
    current_nr = "#cdd6f4";
  };

  starship = {
    background       = "#1e1e2e";
    dark_background  = "#181825";
    second_background = "#252536";
    third_background = "#313244";
    fourth_background = "#45475a";
    foreground       = "#cdd6f4";
    current          = "#181825";
    selection        = "#45475a";
    cursor           = "#f5e0dc";
    line             = "#585b70";
    current_number   = "#cdd6f4";
    cyan             = "#94e2d5";
    gray             = "#6c7086";
    red              = "#f38ba8";
    error_red        = "#f38ba8";
    green            = "#a6e3a1";
    lime             = "#a6e3a1";
    blue             = "#89b4fa";
    orange           = "#fab387";
    magenta          = "#f5c2e7";
    white            = "#cdd6f4";
    bright           = "#585b70";
    purple           = "#cba6f7";
    yellow           = "#f9e2af";
  };
}
