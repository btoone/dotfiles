# Sourced by login shells AFTER /etc/zprofile, whose path_helper rebuilds PATH
# with system dirs first — demoting anything .zshenv prepended. Re-prepend mise
# shims here so GUI-launched login shells (desktop agents) resolve tools before
# /usr/bin. Interactive shells get the same result later via `mise activate`
# in .zshrc; this covers the non-interactive login case that never reaches it.
export PATH="$HOME/.local/share/mise/shims:$PATH"
