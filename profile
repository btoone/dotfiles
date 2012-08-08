if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi

# enable shims and autocomplete for rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*