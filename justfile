# List available recipes
default:
    @just --list

# Fresh machine: install Homebrew packages + mise runtimes
bootstrap:
    script/bootstrap

# After pulling changes: install new packages, symlink dotfiles, deploy tools
setup:
    brew bundle --global
    script/setup

# Pull latest changes and run setup
update:
    git pull
    just setup

# Fresh machine: full install (bootstrap + setup)
install: bootstrap setup
