{ pkgs, lib, config, ... }:

{
  programs.zsh = {
    enable = true;
    # dotDir omitted — zsh files live in $HOME (default, avoids sourcing chain issues)
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      size = 10000;
      save = 10000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      ignoreAllDups = true;
      share = true;
      append = true;
    };

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      REPOS_HOME = "$HOME/repos";
      DOTS_HOME = "$HOME/repos/macDots";
      VIMCONFIG = "$HOME/.config/nvim";
      BAT_THEME = "night-owl";
      GOPATH = "$HOME/go";
      KEYTIMEOUT = "1";
    };

    shellAliases = {
      # ls → eza
      ls = "eza";
      l = "ls -lha";
      la = "ls -a";
      lla = "ls -la";
      lt = "ls --tree";
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
      gc = "git commit";
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

      # bat
      cat = "bat";
      batl = "bat --paging=never -l log";

      # shell
      resource_zsh = "source $HOME/.zshrc";

      # claude code — separate personal/work configs
      claude-personal = "CLAUDE_CONFIG_DIR=~/.claude-personal command claude";
      claude-work = "CLAUDE_CONFIG_DIR=~/.claude-work command claude";
      claude = "claude-work";

      # nix-darwin rebuild
      rebuild = "sudo darwin-rebuild switch --flake ~/repos/macDots#macbook";

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
}
