---
name: annotate-screenshot
description: Annotate a screenshot to point out an issue or explain a surface — crop to the subject, dim everything else, ring the exact elements, link the ones that belong together, and set the explanation in a white card — from a JSON spec, deterministically, with PIL. Use whenever the user shares a screenshot with "annotate this", "mark up this screenshot", "point out …", "call out …", "highlight the rows/fields that …", or wants an image to drop in a ticket, PR, Slack thread or bug report that makes a problem obvious at a glance. Not for video walkthroughs (that is annotated-demo-video) or for screenshots the user only wants captured.
---

# Annotate a screenshot

The output is a PNG someone else reads in two seconds in a ticket or thread: the subject large, the rest
dimmed, the exact elements ringed, and a short white card saying what they are looking at. Everything is
drawn by `scripts/annotate.py` from a JSON spec, so a change is an edit to the spec and a re-run, never a
re-draw.

## Workflow

1. **Find the file.** macOS screenshot names carry a narrow no-break space before `AM`/`PM`; a literal path
   fails with "not a valid file". The script globs around it, and so should any `ls`:
   `ls "$HOME/Documents/screenshots/Screenshot 2026-10-30 at 9.46.23"*`.
2. **Read the image** with the Read tool. It is shown downscaled and the caption gives the factor
   ("original 5344x2892, displayed at 2000x1082, multiply by 2.67"). Measure in the displayed frame, multiply,
   and write **source pixels** into the spec. Row centres, column edges and text extents are enough; rings
   are pills, so a few pixels of slack is fine.
3. **Write the spec** (format below) to the scratchpad, run
   `python3 -I <skill>/scripts/annotate.py spec.json`, then **Read the output PNG**. Check for: a badge or
   card clipped by the crop edge, a link crossing text, a glyph box where a font lacked a character, and
   anything that could pass for the app's own UI. Fix the spec and re-run until it is clean.
4. **Reply with the absolute output path** and a one-line description of what is marked. Offer to add a
   second finding as another card if the user listed more than one issue.

## Spec

```json
{
  "source": "Screenshot 2026-10-30 at 9.46.23 AM.png",
  "output": "settlement-transactions-annotated.png",
  "tone": "problem",                       // "neutral" (default) or "problem"
  "crop": [553, 401, 5232, 2498],          // source px; omit for the whole image
  "spotlight": [[652, 703, 5125, 1197]],   // regions left undimmed, thin slate edge
  "dim": 118,                              // overlay alpha, 0–255
  "rings": {"sale-1": [3201, 724, 3399, 799], "sale-2": [3201, 975, 3399, 1050]},
  "links": [{"tag": "A", "rings": ["sale-1", "sale-2"], "side": "left", "offset": 18, "label_at": 0.24}],
  "badges": [{"tag": "1", "at": [900, 1200]}],
  "card": {
    "at": [652, 1918], "width": 880,
    "title": "Some transactions show twice",
    "items": [{"tag": "A", "text": "Sale $39,796.76 on Amex 1004, rows 1 and 3"}],
    "note": "Each pair matches on date, card and amount, but every row carries its own ARN."
  }
}
```

Sizes other than coordinates (`offset`, `width`, strokes, type) are in units of a 2000px-wide image and
scale with the source, so Retina and 1x captures come out alike. A link draws a spine beside its rings on
`side` at `offset`, with a lead to each ring; `label_at` places the tag along the spine (0 = top). Links are
drawn in spec order and each later one gets a white halo so it reads as passing in front where two cross,
so list the link that should sit on top last. `examples/duplicate-rows.json` is a complete spec.

## Design rules, and why

These came out of a session of rejected drafts; each one is a rejection avoided.

- **Crop to the subject.** Browser chrome, sidebar and empty page make the rows that matter a thin band
  in the middle. Keep only what gives context (the filter chips, the table header) and the table itself.
- **Dim, don't box.** A dark overlay with the subject cut out is what makes the image unmistakably
  annotated, and it does it without a single stroke on the page. Boxing each row of interest reads as a
  wiring diagram and, at thin weights, can pass for the app's own selection state.
- **Ring the exact thing, and link what belongs together.** When the point is "these two are the same",
  a line joining the two rings says it before a word is read. Ring the cell that carries the evidence (the
  amount), not the whole row. Put spines in a column that is empty, so no lead crosses text.
- **One card, in the dimmed space, next to the evidence.** White, shadowed, bold title, one line per item
  with the same tag badge used on the links, and an explanation in muted type underneath. Nothing in the app
  looks like a shadowed card floating over a dimmed page, so it needs no marker-pen styling to be read as a
  note. A card pushed into a margin outside the frame makes the eye travel; a sticky note reads as campy;
  marker strokes with white halos lose legibility fast when everything is the same colour.
- **One accent colour, chosen by tone.** `neutral` is a slate indigo that is not read as a status; it is
  the default for explaining a surface. `problem` is red, for a defect. Green means "good" in most apps, so
  it is wrong for pointing out a problem, and two pair colours plus tints plus outlines is too many
  systems at once; letters do the distinguishing. Even in `problem`, keep the red for the finding (rings,
  links, tag badges); the spotlight edge stays slate so the frame is not a red box.
- **Type is Helvetica Neue**, with Arial as the fallback; the rounded and felt-tip faces lack `·`, `−` and
  similar glyphs and print boxes in their place. If a glyph box appears, change the character, not the font.

## Files

| Path | What it is |
|---|---|
| `scripts/annotate.py` | The renderer. Python 3 + Pillow, nothing else. |
| `examples/duplicate-rows.json` | The spec for a settlement-table finding: four rows, two pairs, a card. |
