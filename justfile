# List available recipes
default:
    @just --list

# Run the test suite
test:
    bats test/

# Fresh machine: install prerequisites (Homebrew check + mise runtimes)
bootstrap:
    script/bootstrap

# After pulling changes: symlink dotfiles, deploy tools, install new packages and plugins
setup:
    script/setup
    script/update

# Pull latest changes and run setup
update:
    git pull
    just setup

# Fresh machine: full install (bootstrap + setup)
install: bootstrap setup
