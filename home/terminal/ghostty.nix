{ theme, ... }:

let
  t = theme.terminal;
  # Ghostty uses colors without the # prefix
  strip = s: builtins.substring 1 (builtins.stringLength s - 1) s;
in
{
  # Ghostty config — also read by cmux (which is built on libghostty)
  xdg.configFile."ghostty/config".text = ''
    # Font
    font-family = "Operator Mono Lig"
    font-size = 13
    font-thicken = true

    # ${theme.name} color scheme
    background = ${strip t.background}
    foreground = ${strip t.foreground}
    cursor-color = ${strip t.cursor}
    selection-background = ${strip t.selection_bg}
    selection-foreground = ${strip t.selection_fg}

    # Normal colors (0-7)
    palette = 0=${t.color0}
    palette = 1=${t.color1}
    palette = 2=${t.color2}
    palette = 3=${t.color3}
    palette = 4=${t.color4}
    palette = 5=${t.color5}
    palette = 6=${t.color6}
    palette = 7=${t.color7}

    # Bright colors (8-15)
    palette = 8=${t.color8}
    palette = 9=${t.color9}
    palette = 10=${t.color10}
    palette = 11=${t.color11}
    palette = 12=${t.color12}
    palette = 13=${t.color13}
    palette = 14=${t.color14}
    palette = 15=${t.color15}

    # Window
    background-opacity = 0.60
    background-blur = true
    window-decoration = false
    window-padding-x = 4
    window-padding-y = 4

    # Scrollback
    scrollback-limit = 524288000

    # macOS specific
    macos-option-as-alt = true
    macos-titlebar-style = hidden

    # Behavior
    copy-on-select = clipboard
    confirm-close-surface = false
    mouse-hide-while-typing = true
  '';
}
