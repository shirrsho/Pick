"""Generates app icon, adaptive foreground, and splash assets for Chord Practice.

Run from the project root:  python3 tool/generate_icons.py
"""
import os
from PIL import Image, ImageDraw

OUT = "assets/icon"
os.makedirs(OUT, exist_ok=True)

SS = 4  # supersample factor for smooth, anti-aliased edges
SIZE = 1024


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vertical_gradient(size, top, bottom):
    grad = Image.new("RGB", (1, size))
    for y in range(size):
        grad.putpixel((0, y), lerp(top, bottom, y / (size - 1)))
    return grad.resize((size, size))


def draw_fretboard(draw, box, line_color, dot_color, lw):
    """Draws a stylised chord diagram (5 strings, 4 frets, 3 finger dots)."""
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    nstr, nfret = 5, 4
    colgap = w / (nstr - 1)
    rowgap = h / nfret

    # strings (vertical)
    for s in range(nstr):
        x = x0 + s * colgap
        draw.line([(x, y0), (x, y1)], fill=line_color, width=lw)

    # frets (horizontal); the top one is the thick nut
    for f in range(nfret + 1):
        y = y0 + f * rowgap
        thick = int(lw * 3.2) if f == 0 else lw
        draw.line([(x0 - lw, y), (x1 + lw, y)], fill=line_color, width=thick)

    # finger dots: (string index from left, fret number)
    dots = [(1, 1), (3, 1), (2, 2)]
    r = colgap * 0.32
    for s, f in dots:
        cx = x0 + s * colgap
        cy = y0 + (f - 0.5) * rowgap
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=dot_color)


def rounded_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return mask


def build_icon():
    s = SIZE * SS
    # Warm orange gradient background, rounded corners (transparent outside).
    bg = vertical_gradient(s, (0xFF, 0xB2, 0x59), (0xF2, 0x68, 0x2A)).convert("RGBA")
    mask = rounded_mask(s, int(s * 0.22))
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    img.paste(bg, (0, 0), mask)

    draw = ImageDraw.Draw(img)
    m = s * 0.26  # margin around the motif
    box = (m, s * 0.22, s - m, s * 0.86)
    white = (255, 255, 255, 240)
    draw_fretboard(draw, box, white, (255, 255, 255, 255), lw=int(s * 0.018))

    img.resize((SIZE, SIZE), Image.LANCZOS).save(f"{OUT}/icon.png")


def build_foreground():
    """Transparent foreground for Android adaptive icons (motif only, padded)."""
    s = SIZE * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Keep within the adaptive-icon safe zone (~62% center).
    m = s * 0.34
    box = (m, s * 0.30, s - m, s * 0.74)
    white = (255, 255, 255, 245)
    draw_fretboard(draw, box, white, (255, 255, 255, 255), lw=int(s * 0.020))
    img.resize((SIZE, SIZE), Image.LANCZOS).save(f"{OUT}/foreground.png")


build_icon()
build_foreground()
print("Wrote", f"{OUT}/icon.png", "and", f"{OUT}/foreground.png")
