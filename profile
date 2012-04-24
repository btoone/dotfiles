if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi

# enable shims and autocomplete for rbenv
eval "$(rbenv init -)"