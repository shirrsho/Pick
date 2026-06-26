"""Generates the Pick app icon, adaptive foreground, and splash assets.

Run from the project root:  python3 tool/generate_icons.py

The logo is a clean white guitar pick on a warm orange gradient.
"""
import os
from PIL import Image, ImageDraw

OUT = "assets/icon"
os.makedirs(OUT, exist_ok=True)

SS = 4  # supersample for smooth, anti-aliased edges
SIZE = 1024


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vertical_gradient(size, top, bottom):
    grad = Image.new("RGB", (1, size))
    for y in range(size):
        grad.putpixel((0, y), lerp(top, bottom, y / (size - 1)))
    return grad.resize((size, size))


def rounded_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return mask


def draw_pick(draw, cx, cy, w, h, fill):
    """A rounded guitar pick (point down), centered at (cx, cy)."""
    r = w * 0.30  # corner rounding
    top_l = (cx - w / 2, cy - h / 2 + r)
    top_r = (cx + w / 2, cy - h / 2 + r)
    bottom = (cx, cy + h / 2)
    pts = [top_l, top_r, bottom]
    # corner discs
    for (x, y) in pts:
        draw.ellipse([x - r, y - r, x + r, y + r], fill=fill)
    # inner triangle + thick edges (rounds the silhouette)
    draw.polygon(pts, fill=fill)
    for a in range(3):
        x0, y0 = pts[a]
        x1, y1 = pts[(a + 1) % 3]
        draw.line([(x0, y0), (x1, y1)], fill=fill, width=int(r * 2))


def build_icon():
    s = SIZE * SS
    bg = vertical_gradient(s, (0xFF, 0xB2, 0x59), (0xF2, 0x68, 0x2A)).convert("RGBA")
    mask = rounded_mask(s, int(s * 0.22))
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    img.paste(bg, (0, 0), mask)

    draw = ImageDraw.Draw(img)
    draw_pick(draw, s * 0.5, s * 0.5, s * 0.46, s * 0.56, (255, 255, 255, 255))

    img.resize((SIZE, SIZE), Image.LANCZOS).save(f"{OUT}/icon.png")


def build_foreground():
    """Transparent foreground for Android adaptive icons (pick only, padded)."""
    s = SIZE * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Keep within the adaptive-icon safe zone (~60% center).
    draw_pick(draw, s * 0.5, s * 0.5, s * 0.36, s * 0.44, (255, 255, 255, 255))
    img.resize((SIZE, SIZE), Image.LANCZOS).save(f"{OUT}/foreground.png")


build_icon()
build_foreground()
print("Wrote", f"{OUT}/icon.png", "and", f"{OUT}/foreground.png")
