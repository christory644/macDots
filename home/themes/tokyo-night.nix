{
  name = "tokyo-night";
  slug = "tokyo_night";

  apps = {
    nvim = "tokyonight";
    nvimPlugin = "tokyonight-nvim";
    nvimSetup = ''require("tokyonight").setup({ style = "night" })'';
    lualine = "tokyonight";
    vscode = "Tokyo Night";
    bat = "TwoDark";   # closest built-in; or use tokyonight custom
    batBuiltin = true;
  };

  terminal = {
    foreground = "#c0caf5";
    background = "#1a1b26";
    cursor = "#c0caf5";
    selection_fg = "#c0caf5";
    selection_bg = "#33467c";

    color0  = "#15161e";
    color1  = "#f7768e";
    color2  = "#9ece6a";
    color3  = "#e0af68";
    color4  = "#7aa2f7";
    color5  = "#bb9af7";
    color6  = "#7dcfff";
    color7  = "#a9b1d6";

    color8  = "#414868";
    color9  = "#f7768e";
    color10 = "#9ece6a";
    color11 = "#e0af68";
    color12 = "#7aa2f7";
    color13 = "#bb9af7";
    color14 = "#7dcfff";
    color15 = "#c0caf5";
  };

  palette = {
    bg        = "#1a1b26";
    bg_dark   = "#16161e";
    bg_light  = "#292e42";
    bg2       = "#1f2335";
    bg3       = "#292e42";
    bg4       = "#3b4261";
    fg        = "#c0caf5";
    fg_dim    = "#565f89";
    accent    = "#7aa2f7";
    cyan      = "#7dcfff";
    red       = "#f7768e";
    red_bright = "#f7768e";
    green     = "#9ece6a";
    green_bright = "#9ece6a";
    yellow    = "#e0af68";
    orange    = "#ff9e64";
    magenta   = "#bb9af7";
    purple    = "#9d7cd8";
    blue      = "#7aa2f7";
    white     = "#c0caf5";
    selection  = "#33467c";
    cursor     = "#c0caf5";
    line       = "#3b4261";
    current    = "#16161e";
    current_nr = "#c0caf5";
  };

  starship = {
    background       = "#1a1b26";
    dark_background  = "#16161e";
    second_background = "#1f2335";
    third_background = "#292e42";
    fourth_background = "#3b4261";
    foreground       = "#c0caf5";
    current          = "#16161e";
    selection        = "#33467c";
    cursor           = "#c0caf5";
    line             = "#3b4261";
    current_number   = "#c0caf5";
    cyan             = "#7dcfff";
    gray             = "#565f89";
    red              = "#f7768e";
    error_red        = "#f7768e";
    green            = "#9ece6a";
    lime             = "#9ece6a";
    blue             = "#7aa2f7";
    orange           = "#ff9e64";
    magenta          = "#bb9af7";
    white            = "#c0caf5";
    bright           = "#414868";
    purple           = "#9d7cd8";
    yellow           = "#e0af68";
  };
}
