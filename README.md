Dotfiles
========

Personal dotfiles for macOS developer environments.

Conventions
-----------

All files are named without the "dot". The install will symlink with the proper
dotted name.

Several configurations borrowed from https://github.com/thoughtbot/dotfiles.

Getting Started
---------------

Clone the repo into your home directory.

    git clone git@github.com:<username>/dotfiles.git ~/dotfiles

Install Homebrew packages (includes mise for runtime management):

    brew bundle --global

Run the setup script:

    cd ~/dotfiles
    bin/setup

The setup script will:

1. Create symlinks for each file in `MANIFEST`
2. Copy local config templates (only if they don't exist)
3. Install `tpm` for tmux
4. Run `mise install` for runtime versions

After setup, start a new terminal session or run `exec zsh`.

Features
--------

### Git

* Configuration
* Aliases

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

* Vi mode keybindings
* Git-aware prompt with compact path display
* Useful aliases
* Local config support (`~/.zshrc.local`)

### Mise

Runtime version management (Ruby, Node, Python, etc.) via [mise](https://mise.jdx.dev/).
Versions defined in `mise.toml`.

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

