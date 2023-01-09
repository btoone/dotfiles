
# Login configuration

## Git completion support
# See https://github.com/git/git/blob/master/contrib/completion/git-completion.zsh
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
fpath=(~/.zsh $fpath)
autoload -Uz compinit && compinit

## Enable vi mode for better command-line navigation
set -o vi 

## Enable ASDF
# . $HOME/.asdf/asdf.sh
# . $HOME/.asdf/completions/asdf.bash

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Include aliases
[[ -f ~/.aliases ]] && source ~/.aliases

# Set PATH, MANPATH, etc., for Homebrew.
eval "$(/opt/homebrew/bin/brew shellenv)"

# Set env for rbenv
eval "$(rbenv init - zsh)"

# Set env for nodenv
eval "$(nodenv init -)"
