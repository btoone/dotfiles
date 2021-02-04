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

Clone the directory.

    git clone git@github.com:caspyin/dotfiles.git

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
source ~/.bashrc
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

Plugins (or packages) are installed using the built-in package support that
comes with Vim 8. 

Which means they are installed to `~/.vim/pack/`.

Anything in an `opt/` dir can be loaded manually using `:packadd! packagename`.

See `:help package` for more info.

### Tmux

* Configuration

### Bash

* Useful aliases

Contributing (optional for OSS)
-------------------------------

Pull requests are welcome.

### Publishing Local Changes

You can make changes to, and publish from, the `local` branch that was created 
during setup. Use the following command:

git push origin local:master

License
-------

This project is licensed under the terms specified in the [`LICENSE.txt`] file.

[`LICENSE.txt`]: /LICENSE.txt

About
-----

This README was crafted with love and inspired by the README best practices of
https://github.com/jehna/readme-best-practices

