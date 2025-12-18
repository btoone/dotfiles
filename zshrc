# Shell configuration
setopt HIST_IGNORE_ALL_DUPS
setopt SH_WORD_SPLIT

# Completions (Homebrew provides git completions via site-functions)
autoload -Uz compinit && compinit

## Enable vi mode for better command-line navigation
bindkey -v

# allow vv to edit the command line (standard behaviour)
# Copied from https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/vi-mode
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'vv' edit-command-line

# Mise (runtime version manager)
export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate zsh)"

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Include aliases
[[ -f ~/.aliases ]] && source ~/.aliases

# Set PATH, MANPATH, etc., for Homebrew.
eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"


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

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
