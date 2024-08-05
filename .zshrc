autoload bashcompinit && bashcompinit

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
alias ls=eza
alias resource="source ~/.zshrc"
