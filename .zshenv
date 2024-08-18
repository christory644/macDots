#!/bin/env zsh

# XDG
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$XDG_CONFIG_HOME/local/share"
export XDG_CACHE_HOME="$XDG_CONFIG_HOME/cache"

# editor
export EDITOR="nvim"
export VISUAL="nvim"

# useful directories
export REPOS_HOME="$HOME/repos"
export DOTS_HOME="$REPOS_HOME/macDots"

# zsh
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# history
export HISTFILE="$ZDOTDIR/.zhistory"	# History filepath
export HISTSIZE=10000			# Maximum events for internal history
export HISTDUP=erase
export SAVEHIST=10000			# Maximum events in history file

# other software
export NVM_DIR="$HOME/.nvm"
export VIMCONFIG="$XDG_CONFIG_HOME/nvim"
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
export BAT_THEME="night-owl"

# path
export PATH=/opt/homebrew/bin:$PATH
