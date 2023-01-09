export DOTFILES="~/code/dotfiles"

## ZSH
# export ZDOTDIR="$DOTFILES/zsh"

## PATH
export PATH="$HOME/bin:$PATH"                                                   # personal tools
export PATH="./bin:$PATH"                                                       # project binstubs

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
export LIBRARY_PATH=$LIBRARY_PATH:/opt/homebrew/opt/openssl@1.1/lib/

# Intel
# export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/opt/openssl/lib/