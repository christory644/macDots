#!/bin/env zsh

# XDG
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$XDG_CONFIG_HOME/local/share"
export XDG_CACHE_HOME="$XDG_CONFIG_HOME/cache"

# editor
export EDITOR="nvim"
export VISUAL="nvim"

export REPOS_HOME="$HOME/repos"
export DOTS_HOME="$REPOS_HOME/macDots"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export HISTFILE="$ZDOTDIR/.zhistory"	# History filepath
export HISTSIZE=10000			# Maximum events for internal history
export SAVEHIST=10000			# Maximum events in history file

export NVM_DIR="$HOME/.nvm"

export PATH=/opt/homebrew/bin:$PATH
