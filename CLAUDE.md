# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles for configuring developer environments on macOS and Linux. Files are named without the leading dot - the setup script creates symlinks with proper dotted names in `$HOME`.

## Setup Commands

```bash
# Fresh machine (run from ~/dotfiles)
just install        # bootstrap + setup, in the right order
script/bootstrap    # prerequisites only: Homebrew check + mise runtimes
script/setup        # symlink dotfiles, deploy tools, copy templates

# After pulling changes
just setup          # script/setup + script/update
script/setup        # config only — fast, idempotent, no network
script/update       # deps only — brew bundle, vim plugins, tmux plugins

# Install personal Claude Code plugin (per-profile, once)
claude plugins marketplace add ~/dotfiles/my-plugin
claude plugins install my
```

## Verification

```bash
just test           # bats test/ — the gate; run before committing
```

Covers `tools/agent-board` + `tools/agent-board-hook` behavior and the routing
surface every skill's frontmatter declares. It does **not** cover `script/setup`
or `script/update`, symlink correctness, the shell configs (`zshrc`, `aliases`,
`tmux.conf`), or the other tools — `plan-gate`, `flip`, `obsidian-open`,
`tmux-help`, `eval_gist.rb`. Changes there need verifying by hand.

## Architecture

### File Installation Flow

1. `MANIFEST` lists all config files to symlink as `~/.<filename>`
2. `script/setup` creates the symlinks, deploys tools, and copies templates
3. `templates/` files are **copied** (not symlinked) to allow machine-specific customization
4. Each main config sources its `.local` variant if present (e.g., `~/.zshrc` sources `~/.zshrc.local`) — the same pattern covers zshrc, vimrc, tmux.conf, aliases, and gitconfig

### Key Directories

- `script/` - Repo bootstrap (`script/bootstrap`, `script/setup`, `script/update`). Follows the [GitHub "Scripts to Rule Them All"](https://github.com/github/scripts-to-rule-them-all) convention
- `tools/` - User tool scripts, symlinked into `~/.local/bin` during setup
- `prototypes/` - Experimental scripts and reference implementations (not symlinked or deployed)
- `templates/` - Machine-specific config seeds (copied once, then customized per machine). Follows the [thoughtbot dotfiles](https://github.com/thoughtbot/dotfiles) `.local` override pattern
- `git/` - Git ignore and attributes, symlinked into `~/.config/git/` (XDG standard location)
- `claude/` - Claude Code config (settings, statusline, user-level `CLAUDE.md`), symlinked into `~/.claude-personal` and/or `~/.claude-work` profile dirs
- `my-plugin/` - Claude Code personal plugin providing the `my:` namespace — skills in `my-plugin/skills/`, commands in `my-plugin/commands/`
- `vim/` - Vim configuration, plugins managed by vim-plug (`Plug` lines in `vim/vimrc`), symlinked as `~/.vim`
- `tmux/` - Tmux config, plugins managed by TPM (bottom of `tmux.conf`): catppuccin, resurrect. Symlinked as `~/.tmux`

### Conventions

- **Dotfile configs** listed in `MANIFEST` are symlinked as `~/.<filename>` — editing the symlinked file in `$HOME` modifies the repo copy directly
- **Tool scripts** in `tools/` are symlinked into `~/.local/bin` (on PATH via `zshrc`) — same edit-in-place behavior
- **Templates** in `templates/` are copied, not symlinked — edits stay local to the machine
- **`~/.local/bin`** is the standard (XDG) location for user scripts. Do NOT add `~/bin` or `~/dotfiles/tools` to PATH
- **Runtimes** are managed by `mise` (asdf replacement), versions in `mise.toml`, activated in `zshrc`
- **Homebrew prefix** is detected in `zshenv` (`/opt/homebrew` on Apple silicon, `/usr/local` on Intel)

## Key Scripts

### script/bootstrap
Installs the prerequisites that install everything else: checks for Homebrew, installs mise, runs `mise install`. Run once on a fresh machine. Deliberately does **not** run `brew bundle` — that belongs to `script/update`, which runs after `script/setup` has created the `~/.Brewfile` symlink `brew bundle --global` depends on.

### script/setup
Configures the local environment: symlinks dotfiles from MANIFEST, copies templates, symlinks tool scripts into `~/.local/bin`, arms the `plan-gate` pre-push hook, deploys Claude Code config, installs tpm. Fast, idempotent, no network needed.

### script/update
Brings installed dependencies in line with the current checkout: `brew bundle --global`, vim plugins (`PlugInstall --sync` + `PlugClean!`), tmux plugins (tpm `install_plugins`). Needs network. Run after pulling changes — `just setup` runs it after `script/setup`, so a pull that adds a Brewfile entry or a `Plug` line lands without any manual follow-up. On macOS 13 and older, brew is report-only — the script's comments explain why.

### tools/tmux-help
Keybinding help popup (`prefix + ?`), self-maintaining from `bind` lines — so every new binding in `tmux.conf` needs a comment line directly above it to show up properly.

### tools/agent-board-hook + tools/agent-board
Status board for Claude Code sessions across tmux: hook events drive per-session state files, a catppuccin status-bar glyph, and an fzf popup TUI (`prefix + B`). Read `.claude/agent-board.md` before changing either tool — it documents the moving parts (lanes, glyphs, live-reload ports, notification banners).

## Configuration Patterns

### Adding New Dotfiles
1. Add the file to the repo (without leading dot)
2. Add filename to `MANIFEST`
3. Run `ln -s ~/dotfiles/<file> ~/.<file>` or re-run `script/setup`

### Adding New Tool Scripts
1. Add the script to `tools/` (make it executable)
2. Run `ln -s ~/dotfiles/tools/<script> ~/.local/bin/<script>` or re-run `script/setup`
