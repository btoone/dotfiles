# Shell configuration
setopt HIST_IGNORE_ALL_DUPS
setopt INC_APPEND_HISTORY
setopt SH_WORD_SPLIT
setopt INTERACTIVE_COMMENTS    # allow `#` to comment out a line interactively

# Completions (Homebrew provides git completions via site-functions)
autoload -Uz compinit && compinit

## Enable vi mode for better command-line navigation
bindkey -v

# allow vv to edit the command line (standard behaviour)
# Copied from https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/vi-mode
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'vv' edit-command-line
bindkey -M viins '^P' up-history
bindkey -M viins '^N' down-history

# Mise (runtime version manager). Shims in .zshenv/.zprofile cover shells that
# never reach this file; activate is what loads mise.toml [env] into the shell,
# which shims cannot do — pbx relies on it for `_.path` binstubs.
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Include aliases
[[ -f ~/.aliases ]] && source ~/.aliases

# Set MANPATH, INFOPATH, HOMEBREW_* etc. for Homebrew. Its PATH entries are
# positioned by path_precedence below rather than by this prepend.
eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"

# One owner for PATH precedence, declared in priority order. Prepend order can't
# express this: macOS path_helper rewrites PATH after .zshenv, and mise's
# precmd/chpwd hooks rebuild it from an activation snapshot on every prompt and
# directory change — so any one-shot ordering here survives only until the next
# `cd`. Re-asserting from a hook registered after mise's makes it stick.
# Subtracting with :| keeps this idempotent and drops duplicates.
typeset -ga _path_priority=(
  $HOME/.local/share/mise/shims   # runtimes mise.toml pins beat everything else
  $HOME/.local/bin                # tool scripts deployed by script/setup
  $HOMEBREW_PREFIX/bin            # brew's tools beat the BSD ones (e.g. ctags)
  $HOMEBREW_PREFIX/sbin
)
path_precedence() { path=($_path_priority ${path:|_path_priority}) }
autoload -Uz add-zsh-hook
add-zsh-hook precmd path_precedence
path_precedence

# case insensitive path-completion
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'

# partial completion suggestions
zstyle ':completion:*' list-suffixes
zstyle ':completion:*' expand prefix suffix

# Prompt with git info
# Format: ~/d/v/pack [git:master] ❱
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
setopt prompt_subst
zstyle ':vcs_info:git:*' formats '[git:%b]'
zstyle ':vcs_info:*' enable git

# Compact path: ~/dotfiles/vim/pack -> ~/d/v/pack
compact_path() {
  local p="${PWD/#$HOME/~}"
  echo "$p" | awk -F/ '{
    result=""
    for (i=1; i<NF; i++) result=result substr($i, 1, 1) "/"
    result=result $NF
    print result
  }'
}

PROMPT='%F{green}$(compact_path)%f %F{yellow}${vcs_info_msg_0_}%f❱ '

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# pnpm
export PNPM_HOME="/Users/brandon/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
