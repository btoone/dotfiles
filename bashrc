source ~/.bash/env
source ~/.bash/config
source ~/.bash/functions
source ~/.bash/cdhistory
source ~/.bash/prompt

# Local config
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local

# Include aliases
[[ -f ~/.aliases ]] && source ~/.aliases
