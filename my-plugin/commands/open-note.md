---
description: Open a note in Obsidian without typing a path
---

# Open Note

Find a note in an Obsidian vault and open it, so getting to a note never requires knowing its path or the vault's registered name.

The opening itself belongs to `tools/obsidian-open`, which resolves the vault by its Obsidian ID rather than its name. Never hand-build an `obsidian://` URI here — the name/path/symlink resolution is exactly the fiddly part the script exists to own.

## Configuration

- **Vaults root:** `~/Vaults/`

### Vault Resolution (in priority order)

Resolve a vault only when there's a search query to scope, or an explicit vault argument. The no-query path below searches every vault at once — guessing a "default" vault there is both slower and wrong when the last save went elsewhere.

1. **Explicit argument** — if the first argument matches a vault name (case-insensitive against `ls ~/Vaults/`), use it and consume the argument
2. **Current working directory** — if `pwd` is inside `~/Vaults/<something>/`, use that vault
3. **`$OBSIDIAN_DEFAULT_VAULT`** env var (`echo $OBSIDIAN_DEFAULT_VAULT`)
4. **Fallback** — first directory found in `~/Vaults/`

## Finding the Note

Arguments after the vault are a search query.

**No query** — open the note the user most recently saved. This is the common case right after `/my:vault`, and it should feel instant: the whole path is **two shell commands** — this find, then `obsidian-open`. No vault resolution, no checking other vaults, no `date` conversions, no extra `stat`s.

```bash
find -L ~/Vaults -type f -name '*.md' \
  -not -path '*/.obsidian/*' \
  -not -name 'index.md' -not -name 'log.md' -not -name '_Schema.md' \
  -exec stat -f '%m %N' {} + | sort -rn | head -5
```

(Scope the find to one vault only when an explicit vault argument was given.)

Two details in that command are load-bearing:

- **`-L`** — vault entries under `~/Vaults/` are often symlinks to the real directory. Without `-L`, `find` stops at the symlink and returns nothing at all.
- **Excluding `index.md`, `log.md`, `_Schema.md`** — brain maintenance rewrites the index and log *after* writing the note, so they always win a plain recency sort. They're vault machinery, never what someone means by "the note I just made".

**Picking from the top 5.** Maintenance also edits *neighbor* notes — the ones it backlinks — seconds after the new note lands, and those edits rewrite the files outright, so mtime (and even birth time) can't tell the new note from a freshly-backlinked old one. The tell is the shape of the list:

- Top entries spread out in time → no maintenance ran; the top entry is the note. Open it.
- Top entries clustered within a minute or two → that's a maintenance pass. `tail -1` that vault's `log.md`: the last `[INGEST]` line names the vault-relative path of the note that just landed. Open that one. (This is the one case that earns a third command.)
- Cluster but no `log.md`, or its last line names none of them → fall back to the top entry and say so.

Say which note you picked and how recent it is, since "most recent" is a guess about intent.

**With a query** — match case-insensitively against note filenames first, then against paths. Prefer a title match over a path match; prefer an exact basename over a substring.

- **One match** — open it.
- **Several** — list them with their folders, most-recently-modified first, and ask which. Don't guess when the query is ambiguous; opening the wrong note is more annoying than a question.
- **None** — say so and show the closest few filenames. Do not fall back to opening something unrelated.

Search filenames before reading contents. Content search is a fallback for when a filename query finds nothing, and should be reported as such ("no title matched; this one mentions it").

## Opening

```bash
obsidian-open "<absolute path to note>"
```

Opens in the background without stealing focus. Useful flags:

- `--focus` — bring Obsidian to the front
- `--print` — print the `obsidian://` URI instead of opening, for when the user wants the link rather than the app

If the script reports the note isn't inside a registered vault, the vault has never been opened in Obsidian. Say that; don't work around it.

## Report

Name the note and its folder. Keep it to a line — the result is visible in Obsidian.

$ARGUMENTS
