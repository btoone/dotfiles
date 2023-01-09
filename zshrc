
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

# case insensitive path-completion 
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 

# partial completion suggestions
zstyle ':completion:*' list-suffixes zstyle ':completion:*' expand prefix suffix 

# git prompt
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
setopt prompt_subst
RPROMPT=\$vcs_info_msg_0_
zstyle ':vcs_info:git:*' formats '%F{240}(%b) %r%f'
zstyle ':vcs_info:*' enable git
