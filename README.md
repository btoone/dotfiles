
# Overview #

My dotfiles to configure OS X

# Installation #

    mkdir ~/Code
    cd !$
    git clone git@github.com:btoone/dotfiles.git
    cd dotfiles
    rake

The rake task will create symlinks in your home directory (~) for the dotfiles
and back up any existing files with the same name.

# TODO #

* set dir_color based on the unix env you're installing to in aliases
* fix vcprompt when on linux
* create a linux branch or a linux specific repo
