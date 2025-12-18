# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles for configuring developer environments on macOS and Linux. Files are named without the leading dot - the setup script creates symlinks with proper dotted names in `$HOME`.

## Setup Commands

```bash
# Fresh install (run from ~/dotfiles)
bin/setup

# Install Homebrew packages
brew bundle --global

# Install vim plugins (from within vim)
:PlugInstall

# Install tmux plugins (from within tmux)
prefix + I
```

## Architecture

### File Installation Flow

1. `MANIFEST` lists all config files to symlink
2. `bin/setup` creates `~/.<filename>` symlinks pointing to repo files
3. `local/` directory files are **copied** (not symlinked) to allow machine-specific customization
4. Each main config sources its `.local` variant if present (e.g., `~/.zshrc` sources `~/.zshrc.local`)

### Key Directories

- `bin/` - Executable scripts (setup, prodcon, eval_gist.rb)
- `vim/` - Vim configuration with vim-plug managed plugins
- `tmux/` - Tmux config and plugins (tpm, catppuccin, resurrect)
- `bash/` - Bash-specific configs (env, functions, prompt, completion)
- `local/` - Machine-specific override templates

### Plugin Management

- **Vim**: vim-plug - plugins defined in `vim/vimrc` between `plug#begin()` and `plug#end()`
- **Tmux**: TPM (Tmux Plugin Manager) - plugins defined at bottom of `tmux.conf`

### Runtime Management

Uses `mise` (asdf replacement) with versions specified in `tool-versions`. Activated in `zshrc` via `eval "$(mise activate zsh)"`.

### M1/Intel Compatibility

Homebrew prefix detection in `zshenv`:
- M1: `/opt/homebrew`
- Intel: `/usr/local`

## Key Scripts

### bin/setup
Main installation script. Prompts for mac/linux, creates symlinks from MANIFEST, copies local configs, installs tpm, and runs mise install.

### bin/prodcon
Production Rails console launcher. Creates isolated tmux session with separate socket (`~/.tmux-prod.sock`), checks out production branch, includes safety prompts.

## Configuration Patterns

### Local Overrides
All major configs support `.local` variants for machine-specific settings:
- `~/.zshrc.local` - Zsh customizations
- `~/.vimrc.local` - Vim customizations
- `~/.tmux.conf.local` - Tmux customizations
- `~/.aliases.local` - Custom aliases

### Adding New Dotfiles
1. Add the file to the repo (without leading dot)
2. Add filename to `MANIFEST`
3. Run `ln -s ~/dotfiles/<file> ~/.<file>` or re-run setup
