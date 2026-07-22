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

## Architecture

### File Installation Flow

1. `MANIFEST` lists all config files to symlink as `~/.<filename>`
2. `script/setup` creates the symlinks, deploys tools, and copies templates
3. `templates/` files are **copied** (not symlinked) to allow machine-specific customization
4. Each main config sources its `.local` variant if present (e.g., `~/.zshrc` sources `~/.zshrc.local`)

### Key Directories

- `script/` - Repo bootstrap (`script/bootstrap`, `script/setup`, `script/update`). Follows the [GitHub "Scripts to Rule Them All"](https://github.com/github/scripts-to-rule-them-all) convention
- `tools/` - User tool scripts, symlinked into `~/.local/bin` during setup
- `prototypes/` - Experimental scripts and reference implementations (not symlinked or deployed)
- `templates/` - Machine-specific config seeds (copied once, then customized per machine). Follows the [thoughtbot dotfiles](https://github.com/thoughtbot/dotfiles) `.local` override pattern
- `git/` - Git ignore and attributes, symlinked into `~/.config/git/` (XDG standard location)
- `claude/` - Claude Code config (settings, statusline, project-templates, user-level `CLAUDE.md`), symlinked into `~/.claude-personal` and/or `~/.claude-work` profile dirs
- `my-plugin/` - Claude Code personal plugin providing the `my:` namespace (skills and commands)
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
- **Claude Code**: Personal plugin at `my-plugin/`, installed per-profile via the CLI:
  ```bash
  claude plugins marketplace add ~/dotfiles/my-plugin
  claude plugins install my
  ```
  Provides the `my:` namespace — skills in `my-plugin/skills/`, commands in `my-plugin/commands/`

### Runtime Management

Uses `mise` (asdf replacement) with versions specified in `mise.toml`. Activated in `zshrc` via `eval "$(mise activate zsh)"`.

### M1/Intel Compatibility

Homebrew prefix detection in `zshenv`:
- M1: `/opt/homebrew`
- Intel: `/usr/local`

## Key Scripts

### script/bootstrap
Installs the prerequisites that install everything else: checks for Homebrew, installs mise, runs `mise install`. Run once on a fresh machine. Deliberately does **not** run `brew bundle` — that belongs to `script/update`, which runs after `script/setup` has created the `~/.Brewfile` symlink `brew bundle --global` depends on.

### script/setup
Configures the local environment: symlinks dotfiles from MANIFEST, copies templates, symlinks tool scripts into `~/.local/bin`, deploys Claude Code config, installs tpm. Fast, idempotent, no network needed.

### script/update
Brings installed dependencies in line with the current checkout: `brew bundle --global`, vim plugins (`PlugInstall --sync` + `PlugClean!`), tmux plugins (tpm `install_plugins`). Needs network. Run after pulling changes — `just setup` runs it after `script/setup`, so a pull that adds a Brewfile entry or a `Plug` line lands without any manual follow-up.

On macOS 13 and older, Homebrew no longer ships bottles, so every formula would compile from source (and the pinned `llvm` blocks the Rust-based ones outright). There, brew is **report-only**: `brew bundle check` names any drift instead of installing it, and nothing is upgraded. Those machines stay deliberately frozen — install a new formula by hand, knowing it builds from source. Vim and tmux plugins still install normally.

### prototypes/prodcon
Production Rails console launcher prototype. Creates isolated tmux session with separate socket (`~/.tmux-prod.sock`), checks out production branch, includes safety prompts. Serves as a reference for building similar tools.

### tools/tmux-help
Keybinding help popup bound to `prefix + ?`. Self-maintaining: parses `bind` lines from `~/.tmux.conf` (and `.local`) and uses the comment above each as its description — so every new binding needs a comment line directly above it to show up properly.

### tools/agent-board-hook + tools/agent-board
Status board for Claude Code sessions across tmux (named generically so the tool can grow beyond Claude later). The hook (UserPromptSubmit, PreToolUse, PostToolUse, Notification, Stop, SessionEnd) also syncs the session title to the tmux window name (it absorbed the former claude-tmux-sync), and writes one state file per session to `~/.local/state/agent-board/` and sets a `@agent_glyph` window option that catppuccin renders in the status bar (🔄 working, 💬 needs answer, 🔐 needs permission, ✅ done, 🧊 on ice; the glyph is per-window, so with several sessions split in one window it shows the most urgent one). `agent-board` is the fzf popup TUI bound to `prefix + B` in tmux.conf: sessions grouped under colored lane headers, a preview pane showing the session's last assistant message, enter jumps to the session's pane, ctrl-s sends a prompt into it, ctrl-n edits a per-session 📌 note (rendered as an indented second line of the entry via fzf multi-line items, plus in the preview; persists across agent activity until cleared), ctrl-t toggles on-ice. `agent-board --note <text>` from any pane attaches a note to the agent session in that tmux window (empty text clears). Open boards live-reload: each instance registers `.port.<pid>` in the state dir, and the hook (and board-side edits) POST a reload to every registered fzf `--listen` port, pruning dead ones — so a long-lived CLI board and popups all stay in sync. Blocked sessions (Notification events) also raise a `terminal-notifier` banner whose click jumps to the session (`agent-board --jump`); outside tmux the banner still fires, just without the jump. Completed turns get no banner — the ✅ glyph and board cover that. Banners are deliberately not suppressed for visible panes: an active pane doesn't mean the user is at the keyboard. The lane/glyph mapping lives in `agent-board` only; the hook delegates glyph updates via `agent-board --window-glyph`.

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
