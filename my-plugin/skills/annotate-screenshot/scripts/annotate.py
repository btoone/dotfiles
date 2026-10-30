#!/usr/bin/env python3
"""Annotate a screenshot from a JSON spec: crop, dim everything but the subject, ring the
elements that matter, link rings that belong together, and set the note in a white card.

    python3 -I annotate.py spec.json

All coordinates in the spec are pixels of the SOURCE image. Stroke widths and type sizes are
expressed for a 2000px-wide image and scaled, so a Retina capture and a plain one come out alike.
See ../SKILL.md for the spec format and the design rules behind the defaults.
"""
import glob
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

TONES = {
    "neutral": (63, 81, 181),    # slate indigo: reads as "annotation", not as a status
    "problem": (204, 36, 48),    # red: the thing ringed is wrong
}
INK, BODY, FRAME = (28, 30, 36), (82, 86, 96), (120, 126, 140)
FONT_CANDIDATES = [
    ("/System/Library/Fonts/HelveticaNeue.ttc", {"regular": 0, "bold": 1}),
    ("/System/Library/Fonts/Supplemental/Arial.ttf", None),
]


def resolve(path):
    """macOS screenshot names carry a narrow no-break space before AM/PM; a glob survives it."""
    if Path(path).exists():
        return path
    hits = glob.glob(path.replace(" AM", "*AM").replace(" PM", "*PM"))
    if not hits:
        sys.exit(f"source not found: {path}")
    return hits[0]


class Canvas:
    def __init__(self, spec):
        src = Image.open(resolve(spec["source"])).convert("RGBA")
        self.S = src.width / 2000
        self.crop = spec.get("crop", [0, 0, src.width, src.height])
        self.im = src.crop(tuple(int(v) for v in self.crop))
        self.accent = TONES[spec.get("tone", "neutral")]
        self.d = ImageDraw.Draw(self.im)

    def P(self, x, y):
        return ((x - self.crop[0]), (y - self.crop[1]))

    def px(self, n):
        return n * self.S

    def font(self, px, bold=False):
        size = int(self.px(px))
        for path, faces in FONT_CANDIDATES:
            try:
                if faces:
                    return ImageFont.truetype(path, size, index=faces["bold" if bold else "regular"])
                return ImageFont.truetype(path.replace(".ttf", " Bold.ttf") if bold else path, size)
            except OSError:
                continue
        return ImageFont.load_default()

    def rect(self, r):
        return [*self.P(r[0], r[1]), *self.P(r[2], r[3])]

    def dim(self, lit, alpha):
        layer = Image.new("RGBA", self.im.size, (14, 16, 22, alpha))
        cut = ImageDraw.Draw(layer)
        for r in lit:
            cut.rounded_rectangle(self.rect(r), radius=self.px(8), fill=(0, 0, 0, 0))
        self.im.alpha_composite(layer)
        self.d = ImageDraw.Draw(self.im)
        for r in lit:
            self.d.rounded_rectangle(self.rect(r), radius=self.px(8), outline=FRAME, width=int(self.px(2)))

    def badge(self, x, y, tag, r=13):
        self.d.ellipse([*self.P(x - r * self.S, y - r * self.S), *self.P(x + r * self.S, y + r * self.S)],
                       fill=self.accent, outline="white", width=int(self.px(2.5)))
        self.d.text(self.P(x, y + self.px(1)), tag, fill="white", font=self.font(15, True), anchor="mm")

    def ring(self, r):
        h = (r[3] - r[1]) / 2
        self.d.rounded_rectangle(self.rect(r), radius=h, outline=self.accent, width=int(self.px(2.5)))

    def link(self, rings, side, offset, label, label_at, in_front):
        """Join rings with an elbow line beside them. A later link drawn `in_front` gets a white
        halo on its spine so it reads as passing over the ones underneath."""
        w = int(self.px(3))
        ys = [(r[1] + r[3]) / 2 for r in rings]
        if side == "left":
            edge = min(r[0] for r in rings)
            spine = edge - self.px(offset)
            ends = [r[0] for r in rings]
        else:
            edge = max(r[2] for r in rings)
            spine = edge + self.px(offset)
            ends = [r[2] for r in rings]
        for y, end in zip(ys, ends):
            self.d.line([self.P(spine, y), self.P(end, y)], fill=self.accent, width=w)
        top, bottom = min(ys), max(ys)
        if in_front:
            self.d.line([self.P(spine, top), self.P(spine, bottom)], fill="white", width=w + int(self.px(5)))
        self.d.line([self.P(spine, top), self.P(spine, bottom)], fill=self.accent, width=w)
        if label:
            self.badge(spine, top + (bottom - top) * label_at, label)

    def card(self, c):
        x0, y0 = c["at"]
        width = self.px(c.get("width", 880))
        pad, line_h, item_h = self.px(30), self.px(36), self.px(36)
        height = pad + self.px(44) + item_h * len(c.get("items", [])) + (self.px(30) if c.get("note") else 0) + pad * 0.6
        box = [*self.P(x0, y0), *self.P(x0 + width, y0 + height)]
        shadow = Image.new("RGBA", self.im.size, (0, 0, 0, 0))
        ImageDraw.Draw(shadow).rounded_rectangle(
            [box[0], box[1] + self.px(8), box[2], box[3] + self.px(8)], radius=self.px(12), fill=(0, 0, 0, 140))
        self.im.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(self.px(14))))
        self.d = ImageDraw.Draw(self.im)
        self.d.rounded_rectangle(box, radius=self.px(12), fill="white")

        x, y = x0 + pad, y0 + pad * 0.8
        self.d.text(self.P(x, y), c["title"], fill=INK, font=self.font(24, True))
        y += self.px(44)
        for item in c.get("items", []):
            if item.get("tag"):
                self.badge(x + self.px(13), y + self.px(11), item["tag"], r=12)
                self.d.text(self.P(x + self.px(40), y + self.px(1)), item["text"], fill=INK, font=self.font(18))
            else:
                self.d.text(self.P(x, y + self.px(1)), item["text"], fill=INK, font=self.font(18))
            y += item_h
        if c.get("note"):
            self.d.text(self.P(x, y + self.px(4)), c["note"], fill=BODY, font=self.font(16))

    def save(self, path):
        self.im.convert("RGB").save(path)


def main(spec_path):
    spec = json.loads(Path(spec_path).read_text())
    c = Canvas(spec)
    if spec.get("spotlight"):
        c.dim(spec["spotlight"], spec.get("dim", 118))
    rings = spec.get("rings", {})
    for r in rings.values():
        c.ring(r)
    for i, link in enumerate(spec.get("links", [])):
        c.link([rings[k] for k in link["rings"]], link.get("side", "left"), link.get("offset", 40),
               link.get("tag"), link.get("label_at", 0.5), in_front=i > 0)
    for b in spec.get("badges", []):
        c.badge(b["at"][0], b["at"][1], b["tag"])
    if spec.get("card"):
        c.card(spec["card"])
    c.save(spec["output"])
    print(spec["output"])


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
