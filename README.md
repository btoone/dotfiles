
# Overview #

My dotfiles to configure OS X

# Installation #

    mkdir ~/Code
    cd !$
    git clone git@github.com:btoone/dotfiles.git
    cd dotfiles
    rake

The rake task will create symlinks in your home directory (~) for the dotfiles, backing up any existing files with the same name.

# TODO #

* set dir_color based on the unix env you're installing to in aliases