# agent-board — how the pieces fit

Read this before changing `tools/agent-board` or `tools/agent-board-hook`.

Status board for Claude Code sessions across tmux (named generically so the tool can grow beyond Claude later). The hook (UserPromptSubmit, PreToolUse, PostToolUse, Notification, Stop, SessionEnd) also syncs the session title to the tmux window name (it absorbed the former claude-tmux-sync), and writes one state file per session to `~/.local/state/agent-board/` and sets a `@agent_glyph` window option that catppuccin renders in the status bar (🔄 working, 💬 needs answer, 🔐 needs permission, ✅ done, 🧊 on ice; the glyph is per-window, so with several sessions split in one window it shows the most urgent one).

`agent-board` is the fzf popup TUI bound to `prefix + B` in tmux.conf: sessions grouped under colored lane headers, a preview pane showing the session's last assistant message, enter jumps to the session's pane, ctrl-s sends a prompt into it, ctrl-n edits a per-session 📌 note (rendered as an indented second line of the entry via fzf multi-line items, plus in the preview; persists across agent activity until cleared), ctrl-t toggles on-ice. `agent-board --note <text>` from any pane attaches a note to the agent session in that tmux window (empty text clears).

Open boards live-reload: each instance registers `.port.<pid>` in the state dir, and the hook (and board-side edits) POST a reload to every registered fzf `--listen` port, pruning dead ones — so a long-lived CLI board and popups all stay in sync.

Blocked sessions (Notification events) also raise a `terminal-notifier` banner whose click jumps to the session (`agent-board --jump`); outside tmux the banner still fires, just without the jump. Completed turns get no banner — the ✅ glyph and board cover that. Banners are deliberately not suppressed for visible panes: an active pane doesn't mean the user is at the keyboard.

The lane/glyph mapping lives in `agent-board` only; the hook delegates glyph updates via `agent-board --window-glyph`.
