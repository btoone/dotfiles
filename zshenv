# Values set here will be available for all shells (including scripts and
# system processes). But be cautious: ~/.zshenv is sourced by all Zsh instances
export DOTFILES="~/code/dotfiles"

# Detect architecture and set Homebrew prefix
# arm64 = Apple Silicon (M1/M2), x86_64 = Intel
if [[ "$(uname -m)" == "arm64" ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
else
  export HOMEBREW_PREFIX="/usr/local"
fi

## ZSH
# export ZDOTDIR="$DOTFILES/zsh"

## PATH
export PATH="./bin:$PATH"                                                       # project binstubs
export PATH="/Applications/MacVim.app/Contents/bin:$PATH"                       # enable mvim from terminal

## Editor
export EDITOR=$(which vim)
export VISUAL="$EDITOR"
export BUNDLE_EDITOR="$EDITOR"
export VIMRC="$HOME/.vim/vimrc"

## Pager
export PAGER='less -SIRMX'

## History
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000

## Directory listing colors
export CLICOLOR=1
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx    # dark backgrounds
# export LSCOLORS=ExFxCxDxBxegedabagacad    # light backgrounds

## OpenSSL (for compiling native extensions)
export LIBRARY_PATH=$LIBRARY_PATH:$HOMEBREW_PREFIX/opt/openssl@3/lib/

# Character encoding
export LC_CTYPE=UTF-8

# Fix some rails env issues that may occur
export DISABLE_SPRING=true
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# Enable ripgrep config
export RIPGREP_CONFIG_PATH=$HOME/.ripgreprc

# FZF
export FZF_DEFAULT_OPTS_FILE=~/.fzfrc

# Gum
# auto, dark, dracula, light, notty, pink, tokyo-night
export GUM_FORMAT_THEME="dark"
