# prototypes

Experimental scripts and reference implementations. Nothing here is symlinked or
deployed by `script/setup` — these are scratchpads you run by path.

- **`prodcon`** — production Rails console launcher (isolated tmux session + socket).
- **`repo-heatmap`** — "where is work happening" heatmap for any git repo (below).

---

## repo-heatmap

A tracer-bullet visualization that answers **"where is work happening right now?"**
for a git repo — built because AI-paced, siloed development makes it hard to see
where attention is actually going.

### What it does

Reads `git log --numstat` (one cheap call, no gems, no services) and renders a
self-contained HTML **treemap** you open in a browser:

- **Size** of each tile = total churn (lines changed) over the window.
- **Color** = recency-weighted heat (`weight = 0.5 ^ (age / half_life)`), so recent
  work glows and old work fades. This is the point — it shows "where is work
  happening *now*," not all-time churn (which just surfaces lockfiles).
- **Blue corner triangle** = AI-authored share, an independent channel. Opacity
  scales with AI %. Detected via `Co-Authored-By: Claude` commit trailers.
- **Toggle** (`recency` / `AI %`) recolors the whole map so color only ever shows
  one variable at a time.

### Usage

```bash
prototypes/repo-heatmap                      # current directory
prototypes/repo-heatmap ~/code/some-app      # any repo (path arg)

# Env knobs (stack on front):
HALF_LIFE_DAYS=7 SINCE="3 months ago" prototypes/repo-heatmap ~/code/some-app
```

| Env | Default | Meaning |
|-----|---------|---------|
| `HALF_LIFE_DAYS` | `14` | Decay half-life in days. Smaller = more "now." |
| `SINCE` | `6 months ago` | `git log --since` window. Shrink it on big repos. |
| `OUT` | temp file | Output HTML path. Auto-opened on macOS. |

Only maps files that currently exist (`git ls-files`), so deleted/renamed paths
drop out and the map reflects the live tree.

### How to read it

Two encodings that can disagree — that's the whole trick:

- **Big + bright** → under heavy work right now.
- **Big + dark** → churned a lot historically, dormant now.
- **Small + bright** → small but freshly touched.
- **Corner triangle** → how much of it is AI-authored (read independently of color).

### Where I left off / next steps

Status: **base heatmap works.** Deliberately kept simple.

- **Validate the base signal first.** Only run on the solo dotfiles repo so far,
  where silo/coupling signal is meaningless. Next step is to point it at a real
  multi-dev repo and see if "where is work happening" reads true before adding
  anything.
- **AI detection caveat.** Keys off `Co-Authored-By: Claude` trailers. Other teams
  may stamp commits differently (Copilot, "Generated with", a different name) —
  if AI corners read zero on a real repo, adjust the `--grep` in the script.
- **Deferred: change-coupling pass.** Files that change together across different
  directories = hidden cross-team entanglement. Genuinely useful, but it answers a
  *different* question (what's entangled) than this tool (where's work). Only worth
  building if the "Team A breaks Team B" pain shows up. Not there yet — parked on
  purpose.
- **Other ideas floated:** acceleration ("what *just got* hot" vs what's hot).
