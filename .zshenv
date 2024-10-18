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

# go lang
export GOPATH=$HOME/go

# add CPPFlags for java 21
export CPPFLAGS="-I/opt/homebrew/opt/openjdk@21/include"

# jenv
export PATH="$HOME/.jenv/bin:$PATH"

# java lang
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH" # add java 17 to path
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH" # add java 21 to path

# path
export PATH=$PATH:$GOPATH/bin # add go path to system path
export PATH=$PATH:/opt/homebrew/bin # add homebrew to system path

# include secret env's, things like keys for openai, etc
source "$DOTS_HOME/.zshenv_secrets"
