export DOTFILES="~/code/dotfiles"

## ZSH
# export ZDOTDIR="$DOTFILES/zsh"

## PATH
export PATH="$HOME/bin:$PATH"                                                   # personal tools
export PATH="./bin:$PATH"                                                       # project binstubs
export PATH="/Applications/MacVim.app/Contents/bin:$PATH"                       # enable mvim from terminal

## Editor
export EDITOR=$(which vim)
export VISUAL="$EDITOR"
export BUNDLE_EDITOR="$EDITOR"
export VIMRC="$HOME/.vim/vimrc"

## Pager
export PAGER='less -RM'

## History
export HISTSIZE=10000
export HISTTIMEFORMAT='%F %T '
export HISTCONTROL=ignoredups
export HISTIGNORE="ls:ls -l:ls -al:ls -altr:ll:c:cls:cdd:pwd:gls:gss:reload:vi"

## Directory listing colors
export CLICOLOR=1
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx    # dark backgrounds
# export LSCOLORS=ExFxCxDxBxegedabagacad    # light backgrounds

## MySQL

# ARM64 (M1)
export LIBRARY_PATH=$LIBRARY_PATH:/opt/homebrew/opt/openssl@3/lib/

# Intel
# export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/opt/openssl/lib/

# Character encoding
export LC_CTYPE=UTF-8

# Fix some rails env issues that may occur
export DISABLE_SPRING=true
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
