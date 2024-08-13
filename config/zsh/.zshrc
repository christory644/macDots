autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

export NVM_DIR="$HOME/.nvm"
    [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" # This loads nvm
    [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion
eval "$(zoxide init zsh)"
source <(fzf --zsh)

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/christory/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/christory/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/christory/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/christory/google-cloud-sdk/completion.zsh.inc'; fi

eval "$(starship init zsh)"
alias ls='eza'
alias l='ls -lha'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias t='tree'
alias t1='tree -L 1'
alias t2='tree -L 2'
alias t3='tree -L 3'
alias resource="source ~/.zshrc"
