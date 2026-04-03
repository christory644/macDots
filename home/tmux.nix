{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    baseIndex = 1;
    historyLimit = 5000;
    mouse = false;
    keyMode = "vi";
    terminal = "tmux-256color";
    escapeTime = 0;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      {
        plugin = resurrect;
        extraConfig = "set -g @resurrect-capture-pane-contents 'on'";
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];

    extraConfig = ''
      # True color support
      set -ga terminal-overrides ",*256col*:Tc"
      set -g focus-events on

      # Pane numbering consistent with windows
      setw -g pane-base-index 1
      setw -g automatic-rename on
      set -g renumber-windows on
      set -g set-titles on
      set -g display-panes-time 800
      set -g display-time 1000
      set -g status-interval 10

      # -- Navigation --
      bind C-c new-session
      bind C-f command-prompt -p find-session 'switch-client -t %%'

      # Pane navigation (hjkl)
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Splits
      unbind %
      bind H split-window -h
      unbind '"'
      bind V split-window -v

      # Edit and reload config
      bind e new-window -n "tmux.conf" "nvim ~/.config/tmux/tmux.conf && tmux source ~/.config/tmux/tmux.conf && tmux display 'tmux.conf sourced'"
      bind r source-file ~/.config/tmux/tmux.conf \; display 'tmux.conf sourced'

      # -- Night Owl Color Scheme --
      BG1="#011627"
      BG2="#82aaff"
      BG3="#112630"
      FG1="#d6deeb"
      FG2="#637777"

      set-option -g status "on"
      set -g status-bg $BG3
      set -g status-fg $FG1

      set-window-option -g window-status-style bg=$BG1,fg=$BG3
      set-window-option -g window-status-activity-style bg=$BG2,fg=colour248
      set-window-option -g window-status-current-style fg=$BG1,bg=$BG2

      set-option -g pane-active-border-style fg=$FG2
      set-option -g pane-border-style fg=$FG2
      set-option -g message-style bg=$BG1,fg=$BG2
      set-option -g message-command-style bg=$BG1,fg=$FG1
      set-option -g display-panes-active-colour colour250
      set-option -g display-panes-colour colour237
      set-window-option -g clock-mode-colour colour24
      set-window-option -g window-status-bell-style fg=colour229,bg=colour88

      set-option -g status-justify "left"
      set-option -g status-left-length "80"
      set-option -g status-right-length "80"
      set-window-option -g window-status-separator ""

      set-option -g status-left ""
      set-option -g status-right "#[fg=$BG1, bg=$BG2] #S #[fg=$FG1,bg=$BG3] %Y-%m-%d %H:%M #[fg=$BG1, bg=$BG2] #h "
      set-window-option -g window-status-current-format "#[fg=$BG1, bg=$BG2] #I:#[fg=$BG1, bg=$BG2, bold] #W "
      set-window-option -g window-status-format "#[fg=$FG1,bg=$BG3] #I: #W "
    '';
  };
}
