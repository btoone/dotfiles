Dotfiles
========

Personal dotfiles for macOS developer environments.

Conventions
-----------

All files are named without the "dot". The install will symlink with the proper
dotted name.

Several configurations borrowed from https://github.com/thoughtbot/dotfiles.

### Directory Structure

| Directory    | Purpose                                                     | Convention                  |
|-------------|-------------------------------------------------------------|-----------------------------|
| `script/`   | Repo bootstrap (`script/setup`)                             | [GitHub Scripts to Rule Them All](https://github.com/github/scripts-to-rule-them-all) |
| `tools/`    | User tool scripts → symlinked into `~/.local/bin`           | [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/latest/) |
| `templates/`| Machine-specific config seeds → copied once per machine      | [thoughtbot dotfiles](https://github.com/thoughtbot/dotfiles) |
| `claude/`   | Claude Code config → symlinked into profile dirs             | —                           |
| `vim/`      | Vim config → symlinked as `~/.vim`                           | —                           |
| `tmux/`     | Tmux config → symlinked as `~/.tmux`                         | —                           |

Getting Started
---------------

Clone the repo into your home directory.

    git clone git@github.com:<username>/dotfiles.git ~/dotfiles

Bootstrap dependencies and configure the environment:

    cd ~/dotfiles
    script/bootstrap    # install Homebrew packages + mise runtimes
    script/setup        # symlink dotfiles, deploy tools, copy templates

After pulling changes, just re-run setup (fast, idempotent, no network):

    script/setup

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

#### Creating Sessions

Two workflows for creating named sessions with working directories:

**Option 1: cd then tmux**

```bash
cd ~/code/myproject
tmux                    # creates session named "myproject"
```

**Option 2: tmn with path**

```bash
tmn myproject           # creates session "myproject" in ~/code/myproject
tmn ~/code/myproject    # creates session "myproject" in ~/code/myproject
tmn /absolute/path      # creates session "path" in /absolute/path
```

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
