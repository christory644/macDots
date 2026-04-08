{
  pkgs,
  lib,
  config,
  theme,
  ...
}:

{
  programs.zsh = {
    enable = true;
    # dotDir omitted — zsh files live in $HOME (default, avoids sourcing chain issues)
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    historySubstringSearch = {
      enable = true;
      # Up/Down arrows search history matching current input
      searchUpKey = [ "^[[A" ];
      searchDownKey = [ "^[[B" ];
    };

    history = {
      size = 10000;
      save = 10000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      ignoreAllDups = true;
      share = true;
      append = true;
    };

    envExtra = ''
      # Clear stale ZDOTDIR from old macOS session cache
      # (old config set ZDOTDIR=~/.config/zsh, macOS persists env across logins)
      unset ZDOTDIR
    '';

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      REPOS_HOME = "$HOME/repos";
      DOTS_HOME = "$HOME/repos/macDots";
      VIMCONFIG = "$HOME/.config/nvim";
      BAT_THEME = theme.apps.bat;
      GOPATH = "$HOME/go";
      KEYTIMEOUT = "1";

      # Ollama — tuned for M3 18GB (bump NUM_PARALLEL and MAX_LOADED_MODELS on bigger machine)
      OLLAMA_FLASH_ATTENTION = "1"; # faster inference on Apple Silicon
      OLLAMA_KV_CACHE_TYPE = "q8_0"; # halves KV cache memory
      OLLAMA_KEEP_ALIVE = "10m"; # shorter keepalive to free RAM faster
      OLLAMA_NUM_PARALLEL = "1"; # single request at a time (RAM limited)
      OLLAMA_MAX_LOADED_MODELS = "1"; # only one model loaded at a time
    };

    shellAliases = {
      # ls shortcuts (eza is on PATH, no alias needed)
      l = "eza -lha";
      la = "eza -a";
      lla = "eza -la";
      lt = "eza --tree";
      t = "tree";
      t1 = "tree -L 1";
      t2 = "tree -L 2";
      t3 = "tree -L 3";

      # safe file operations
      cp = "cp -iv";
      mv = "mv -iv";
      rm = "rm -iv";

      # neovim
      nv = "nvim";
      vim = "nvim";
      vi = "nvim";
      nvimd = "nvim --noplugin -u NONE";
      nvimlog = "nvim -w $VIMCONFIG/vimlog";
      nvimnowrap = ''nvim -c "set nowrap|syntax off"'';

      # git
      gs = "git status";
      gss = "git status -s";
      ga = "git add";
      gp = "git push";
      gpraise = "git blame";
      gpo = "git push origin";
      gplo = "git pull origin";
      gb = "git branch";
      gcm = "git commit"; # renamed from gc to avoid shadowing Gas City CLI
      gd = "git diff";
      gco = "git checkout";
      gl = "git log --oneline";
      gr = "git remote";
      grs = "git remote show";
      glol = "git log --graph --abbrev-commit --oneline --decorate";
      gclean = "git branch --merged | grep -v '\\*\\|master\\|develop\\|main' | xargs -n 1 git branch -d";
      dif = "git diff --no-index";

      # tmux
      tmuxk = "tmux kill-session -t";
      tmuxattach = "tmux attach -t";
      tmuxl = "tmux list-sessions";

      # bat (no cat alias — breaks scripts)
      batl = "bat --paging=never -l log";

      # shell
      resource_zsh = "source $HOME/.zshrc";

      # claude code — separate personal/work configs
      claude-personal = "CLAUDE_CONFIG_DIR=~/.claude-personal command claude --enable-auto-mode --allow-dangerously-skip-permissions";
      claude-work = "CLAUDE_CONFIG_DIR=~/.claude-work command claude --enable-auto-mode --allow-dangerously-skip-permissions";
      claude = "claude-work";

      # gastown and gas city — functions are in initContent (need tmux logic)
      gt = "gt-work";
      gc = "gc-work";

      # local services (docker)
      chat = "open http://chat.local:4080";
      chat-up = "docker compose -f ~/repos/macDots/docker/docker-compose.yml up -d";
      chat-down = "docker compose -f ~/repos/macDots/docker/docker-compose.yml down";
      chat-logs = "docker compose -f ~/repos/macDots/docker/docker-compose.yml logs -f";

      # nix-darwin rebuild (nh gives colorized diffs + better progress)
      rebuild = "nh darwin switch ~/repos/macDots -H macbook";

      # update all flake inputs (nixpkgs, home-manager, nixvim, etc.) then rebuild
      update = "nix flake update --flake ~/repos/macDots && nh darwin switch ~/repos/macDots -H macbook";

      # system info (run manually, not on startup)
      neofetch = "fastfetch";
    };

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # Source secrets (API keys, tokens, etc.)
        [ -f "$HOME/repos/macDots/.zshenv_secrets" ] && source "$HOME/repos/macDots/.zshenv_secrets"

        # Cargo/Rust
        [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
      '')
      ''
        # -- Completion configuration --
        zmodload zsh/complist

        # hjkl in menu selection
        bindkey -M menuselect 'h' vi-backward-char
        bindkey -M menuselect 'j' vi-down-line-or-history
        bindkey -M menuselect 'k' vi-up-line-or-history
        bindkey -M menuselect 'l' vi-forward-char
        bindkey -M menuselect '^xg' clear-screen
        bindkey -M menuselect '^xi' vi-insert
        bindkey -M menuselect '^xh' accept-and-hold
        bindkey -M menuselect '^xn' accept-and-infer-next-history
        bindkey -M menuselect '^xu' undo

        _comp_options+=(globdots)

        setopt MENU_COMPLETE AUTO_LIST COMPLETE_IN_WORD

        # zstyle completions
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path "$HOME/.config/cache/zsh/.zcompcache"
        zstyle ':completion:*' complete true
        zle -C alias-expansion complete-word _generic
        bindkey '^a' alias-expansion
        zstyle ':completion:alias-expansion:*' completer _expand_alias
        zstyle ':completion:*' menu select
        zstyle ':completion:*' complete-options true
        zstyle ':completion:*' file-sort modification
        zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
        zstyle ':completion:*:*:*:*:descriptions' format '%F{blue}-- %D %d --%f'
        zstyle ':completion:*:*:*:*:messages' format ' %F{purple} -- %d --%f'
        zstyle ':completion:*:*:*:*:warnings' format ' %F{red}-- no matches found --%f'
        zstyle ':completion:*:*:*:*:default' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
        zstyle ':completion:*' group-name '''
        zstyle ':completion:*:*:-command-:*:*' group-order aliases builtins functions commands
        zstyle ':completion:*' matcher-list ''' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
        zstyle ':completion:*' keep-prefix true

        # -- Directory stack --
        setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT

        # Directory stack navigation aliases
        alias d='dirs -v'
        for index ({1..9}) alias "$index"="cd +''${index}"; unset index

        # -- Vi mode --
        bindkey -v

        # Cursor shape: beam for insert, block for normal
        cursor_mode() {
          cursor_block='\e[2 q'
          cursor_beam='\e[6 q'
          function zle-keymap-select {
            if [[ ''${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
              echo -ne $cursor_block
            elif [[ ''${KEYMAP} == main ]] || [[ ''${KEYMAP} == viins ]] || [[ ''${KEYMAP} = ''' ]] || [[ $1 = 'beam' ]]; then
              echo -ne $cursor_beam
            fi
          }
          zle-line-init() { echo -ne $cursor_beam }
          zle -N zle-keymap-select
          zle -N zle-line-init
        }
        cursor_mode

        # Edit command line in $VISUAL
        autoload -Uz edit-command-line
        zle -N edit-command-line
        bindkey -M vicmd v edit-command-line

        # Text objects (da", ci(, etc.)
        autoload -Uz select-bracketed select-quoted
        zle -N select-quoted
        zle -N select-bracketed
        for km in viopp visual; do
          bindkey -M $km -- '-' vi-up-line-or-history
          for c in {a,i}''${(s..)^:-\'\"\`\|,./:;=+@}; do
            bindkey -M $km $c select-quoted
          done
          for c in {a,i}''${(s..)^:-'()[]{}<>bB'}; do
            bindkey -M $km $c select-bracketed
          done
        done

        # Surround functionality (like vim-surround)
        autoload -Uz surround
        zle -N delete-surround surround
        zle -N add-surround surround
        zle -N change-surround surround
        bindkey -M vicmd cs change-surround
        bindkey -M vicmd ds delete-surround
        bindkey -M vicmd yw add-surround
        bindkey -M visual S add-surround

        # -- Tool integrations --
        # Google Cloud SDK
        [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ] && source "$HOME/google-cloud-sdk/path.zsh.inc"
        [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ] && source "$HOME/google-cloud-sdk/completion.zsh.inc"

        # NVM (if still needed alongside Nix nodejs)
        [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && source "/opt/homebrew/opt/nvm/nvm.sh"

        # JEnv
        if command -v jenv &> /dev/null; then
          eval "$(jenv init -)"
        fi

        # PATH additions
        export PATH="$HOME/go/bin:$HOME/.jenv/bin:$PATH"
        export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"

        # Yazi: cd to directory when exiting with q (wrapper function)
        function y() {
          local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
          yazi "$@" --cwd-file="$tmp"
          if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            builtin cd -- "$cwd"
          fi
          rm -f -- "$tmp"
        }

        # Gastown / Gas City — ensure tmux session for multi-agent views
        # If already in tmux, run directly. Otherwise, attach to existing
        # session (sending the command as keys) or create a new one.
        function _ensure_tmux() {
          local session_name="$1"; shift
          if [ -n "$TMUX" ]; then
            "$@"
          elif tmux has-session -t "$session_name" 2>/dev/null; then
            tmux send-keys -t "$session_name" "$*" Enter
            tmux attach -t "$session_name"
          else
            tmux new-session -s "$session_name" "$@"
          fi
        }

        function gt-work()     { _ensure_tmux gt-work GT_TOWN_ROOT=~/.gt-work CLAUDE_CONFIG_DIR=~/.claude-work command gt "$@"; }
        function gt-personal() { _ensure_tmux gt-personal GT_TOWN_ROOT=~/.gt-personal CLAUDE_CONFIG_DIR=~/.claude-personal command gt "$@"; }
        function gc-work()     { _ensure_tmux gc-work CLAUDE_CONFIG_DIR=~/.claude-work command gc --city ~/.gc-work "$@"; }
        function gc-personal() { _ensure_tmux gc-personal CLAUDE_CONFIG_DIR=~/.claude-personal command gc --city ~/.gc-personal "$@"; }

        # Ensure Nix paths take priority over Homebrew (brew shellenv runs in /etc/zshrc)
        export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH"
      ''
    ];
  };

  # Zoxide (smart cd)
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # FZF (fuzzy finder)
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # Direnv (per-directory environment variables)
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true; # faster nix integration
  };

  # Atuin (better shell history — replaces ctrl+r)
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      style = "compact";
      inline_height = 20;
      show_preview = true;
      enter_accept = true;
    };
  };
}
