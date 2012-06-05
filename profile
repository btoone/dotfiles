if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi

# enable shims and autocomplete for rbenv
# eval "$(rbenv init -)"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*