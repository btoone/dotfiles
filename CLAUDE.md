# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles for configuring developer environments on macOS and Linux. Files are named without the leading dot - the setup script creates symlinks with proper dotted names in `$HOME`.

## Setup Commands

```bash
# Fresh machine (run from ~/dotfiles)
script/bootstrap    # install Homebrew packages + mise runtimes
script/setup        # symlink dotfiles, deploy tools, copy templates

# After pulling changes
script/setup        # fast, idempotent, no network

# Install vim plugins (from within vim)
:PlugInstall

# Install tmux plugins (from within tmux)
prefix + I
```

## Architecture

### File Installation Flow

1. `MANIFEST` lists all config files to symlink as `~/.<filename>`
2. `script/setup` creates the symlinks, deploys tools, and copies templates
3. `templates/` files are **copied** (not symlinked) to allow machine-specific customization
4. Each main config sources its `.local` variant if present (e.g., `~/.zshrc` sources `~/.zshrc.local`)

### Key Directories

- `script/` - Repo bootstrap (`script/setup`). Follows the [GitHub "Scripts to Rule Them All"](https://github.com/github/scripts-to-rule-them-all) convention
- `tools/` - User tool scripts, symlinked into `~/.local/bin` during setup
- `prototypes/` - Experimental scripts and reference implementations (not symlinked or deployed)
- `templates/` - Machine-specific config seeds (copied once, then customized per machine). Follows the [thoughtbot dotfiles](https://github.com/thoughtbot/dotfiles) `.local` override pattern
- `git/` - Git ignore and attributes, symlinked into `~/.config/git/` (XDG standard location)
- `claude/` - Claude Code config (settings, statusline, project-templates), symlinked into `~/.claude-personal` and/or `~/.claude-work` profile dirs
- `vim/` - Vim configuration with vim-plug managed plugins (symlinked as `~/.vim`)
- `tmux/` - Tmux config and plugins: tpm, catppuccin, resurrect (symlinked as `~/.tmux`)

### Conventions

- **Dotfile configs** listed in `MANIFEST` are symlinked as `~/.<filename>` — editing the symlinked file in `$HOME` modifies the repo copy directly
- **Tool scripts** in `tools/` are symlinked into `~/.local/bin` (on PATH via `zshrc`) — same edit-in-place behavior
- **Templates** in `templates/` are copied, not symlinked — edits stay local to the machine
- **`~/.local/bin`** is the standard (XDG) location for user scripts. Do NOT add `~/bin` or `~/dotfiles/tools` to PATH

### Plugin Management

- **Vim**: vim-plug - plugins defined in `vim/vimrc` between `plug#begin()` and `plug#end()`
- **Tmux**: TPM (Tmux Plugin Manager) - plugins defined at bottom of `tmux.conf`

### Runtime Management

Uses `mise` (asdf replacement) with versions specified in `mise.toml`. Activated in `zshrc` via `eval "$(mise activate zsh)"`.

### M1/Intel Compatibility

Homebrew prefix detection in `zshenv`:
- M1: `/opt/homebrew`
- Intel: `/usr/local`

## Key Scripts

### script/bootstrap
Installs system dependencies: runs `brew bundle --global` and `mise install`. Run once on a fresh machine or after adding new dependencies.

### script/setup
Configures the local environment: symlinks dotfiles from MANIFEST, copies templates, symlinks tool scripts into `~/.local/bin`, deploys Claude Code config, installs tpm. Fast, idempotent, no network needed.

### prototypes/prodcon
Production Rails console launcher prototype. Creates isolated tmux session with separate socket (`~/.tmux-prod.sock`), checks out production branch, includes safety prompts. Serves as a reference for building similar tools.

### tools/claude-tmux-sync
Claude Code hook script that syncs the session title to the tmux window name. Runs on PostToolUse (mid-session), UserPromptSubmit (after /rename), and Stop (on exit).

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
3. Run `ln -s ~/dotfiles/<file> ~/.<file>` or re-run `script/setup`

### Adding New Tool Scripts
1. Add the script to `tools/` (make it executable)
2. Run `ln -s ~/dotfiles/tools/<script> ~/.local/bin/<script>` or re-run `script/setup`
