---
description: Open a note in Obsidian without typing a path
---

# Open Note

Find a note in an Obsidian vault and open it, so getting to a note never requires knowing its path or the vault's registered name.

The opening itself belongs to `tools/obsidian-open`, which resolves the vault by its Obsidian ID rather than its name. Never hand-build an `obsidian://` URI here — the name/path/symlink resolution is exactly the fiddly part the script exists to own.

## Configuration

- **Vaults root:** `~/Vaults/`

### Vault Resolution (in priority order)

1. **Explicit argument** — if the first argument matches a vault name (case-insensitive against `ls ~/Vaults/`), use it and consume the argument
2. **Current working directory** — if `pwd` is inside `~/Vaults/<something>/`, use that vault
3. **`$OBSIDIAN_DEFAULT_VAULT`** env var (`echo $OBSIDIAN_DEFAULT_VAULT`)
4. **Fallback** — first directory found in `~/Vaults/`

## Finding the Note

Arguments after the vault are a search query.

**No query** — open the most recently modified `.md` file in the vault. This is the common case right after `/my:vault`, so make it fast: one `find`, no vault scan.

```bash
find -L <vault> -type f -name '*.md' \
  -not -path '*/.obsidian/*' \
  -not -name 'index.md' -not -name 'log.md' -not -name '_Schema.md' \
  -exec stat -f '%m %N' {} + | sort -rn | head -5
```

Two details in that command are load-bearing:

- **`-L`** — vault entries under `~/Vaults/` are often symlinks to the real directory. Without `-L`, `find` stops at the symlink and returns nothing at all.
- **Excluding `index.md`, `log.md`, `_Schema.md`** — brain maintenance rewrites the index and log *after* writing the note, so they always win a plain recency sort. They're vault machinery, never what someone means by "the note I just made".

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
