Dotfiles
========

Collection of personal dotfiles to configure developer environments.

Conventions
-----------

All files are named without the "dot". The install will symlink with the proper
dotted name.

Several configurations borrowed from https://github.com/thoughtbot/dotfiles.

Getting Started
---------------

Clone the repo into your home directory.

    git clone git@github.com:btoone/dotfiles.git ~/dotfiles

Change into the project directory and run the setup. The setup script will do 
the following:

1. Checkout the correct branch for mac or linux installs
2. Create a symlink for each file listed in `MANIFEST` 
3. Setup local configs
4. Install `tpm` for TMUX
5. Install Vim plugins to `~/.vim/pack/*`

```
cd dotfiles
bin/setup

# After successful setup, reload your shell env
source ~/.zshrc
```

Features
--------

### Git

* Configuration
* Aliases
* Completion

### Vim

* Configuration
* Plugins

#### Plugin Management

Plugins are managed using [vim-plug](https://github.com/junegunn/vim-plug).

To install plugins, open vim and run `:PlugInstall`.

Plugins are defined in `vim/vimrc` within the `plug#begin()` and `plug#end()` block.

### Tmux

* Configuration
* Catppuccin theme (requires Nerd Font for icons)

### ZSH

* Useful aliases

Contributing (optional for OSS)
-------------------------------

Pull requests are welcome.

License
-------

This project is licensed under the terms specified in the [`LICENSE.txt`] file.

[`LICENSE.txt`]: /LICENSE.txt

About
-----

This README was crafted with love and inspired by the README best practices of
https://github.com/jehna/readme-best-practices

