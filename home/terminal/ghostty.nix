{ ... }:

{
  # Ghostty config — also read by cmux (which is built on libghostty)
  xdg.configFile."ghostty/config".text = ''
    # Font
    font-family = "Operator Mono Lig"
    font-size = 13
    font-thicken = true

    # Night Owl color scheme
    background = 011627
    foreground = d6deeb
    cursor-color = 80a4c2
    selection-background = 1d3b53
    selection-foreground = d6deeb

    # Normal colors (0-7)
    palette = 0=#011627
    palette = 1=#ef5350
    palette = 2=#22da6e
    palette = 3=#ecc48d
    palette = 4=#82aaff
    palette = 5=#c792ea
    palette = 6=#7fdbca
    palette = 7=#d6deeb

    # Bright colors (8-15)
    palette = 8=#637777
    palette = 9=#ff6363
    palette = 10=#addb67
    palette = 11=#f78c6c
    palette = 12=#82aaff
    palette = 13=#c792ea
    palette = 14=#7fdbca
    palette = 15=#ffffff

    # Window
    background-opacity = 0.85
    background-blur = true
    window-decoration = false
    window-padding-x = 4
    window-padding-y = 4

    # Scrollback
    scrollback-limit = 10000

    # macOS specific
    macos-option-as-alt = true
    macos-titlebar-style = hidden

    # Behavior
    copy-on-select = clipboard
    confirm-close-surface = false
    mouse-hide-while-typing = true
  '';
}
