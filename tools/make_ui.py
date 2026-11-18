"""Generate Greek-styled UI textures (pixel art, nearest-neighbor friendly).

  assets/ui/greek_frame.png  - 9-slice panel frame with a gold meander (Greek key)
                               band; used by assets/ui/greek_frame.tres.
  assets/ui/star.png         - small four-point gold star (cursor / "next" marker).

Usage:
    python tools/make_ui.py
"""

from PIL import Image

S = 3  # pixel scale of the motif

GOLD = (242, 204, 89, 255)
GOLD_DARK = (150, 108, 38, 255)
BAND = (10, 12, 30, 255)
FILL = (15, 18, 41, 248)
CLEAR = (0, 0, 0, 0)

# One meander unit (6x6), a square spiral hooked to a continuous baseline.
MEANDER = [
    "#####.",
    "#...#.",
    "#.#.#.",
    "#.###.",
    "#.....",
    "######",
]
UNIT = len(MEANDER[0]) * S       # 18 px
BORDER = 8 * S                   # top line + gap + motif = 24 px
# Fill-colored gap between the band and the center. The 9-slice margin
# includes it, so when Godot tiles the center it never samples the gold band
# (otherwise thin gold lines appear inside panels of arbitrary sizes).
GAP = S
MARGIN = BORDER + GAP
UNITS_PER_EDGE = 4
SIZE = MARGIN * 2 + UNIT * UNITS_PER_EDGE

STAR = [
    "....#....",
    "....#....",
    "...###...",
    "..#####..",
    "#########",
    "..#####..",
    "...###...",
    "....#....",
    "....#....",
]


def put(img: Image.Image, x: int, y: int, color) -> None:
    """Paint one motif pixel (S x S block)."""
    for dy in range(S):
        for dx in range(S):
            img.putpixel((x * S + dx, y * S + dy), color)


def horizontal_band(length_units: int) -> Image.Image:
    """Band for the TOP edge: outer gold line, gap, meander pointing inward."""
    width = length_units * len(MEANDER[0])
    band = Image.new("RGBA", (width * S, BORDER), BAND)
    for x in range(width):
        put(band, x, 0, GOLD)              # outer line
        put(band, x, 1, GOLD_DARK)         # shadow under the line
    for u in range(length_units):
        for y, row in enumerate(MEANDER):
            for x, ch in enumerate(row):
                if ch == "#":
                    put(band, u * len(row) + x, 2 + y, GOLD)
    return band


def frame() -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE), FILL)
    top = horizontal_band(UNITS_PER_EDGE)
    img.paste(top, (MARGIN, 0))
    img.paste(top.rotate(180), (MARGIN, SIZE - BORDER))
    img.paste(top.rotate(90, expand=True), (0, MARGIN))
    img.paste(top.rotate(-90, expand=True), (SIZE - BORDER, MARGIN))
    # Corners (MARGIN x MARGIN): band color with outer gold lines and a gold
    # square "rosette"; the inner GAP row/column stays fill color.
    corner = Image.new("RGBA", (MARGIN, MARGIN), FILL)
    corner.paste(Image.new("RGBA", (MARGIN, BORDER), BAND), (0, 0))
    corner.paste(Image.new("RGBA", (BORDER, MARGIN), BAND), (0, 0))
    for i in range(MARGIN // S):
        put(corner, i, 0, GOLD)
        put(corner, 0, i, GOLD)
        put(corner, i, 1, GOLD_DARK) if i > 0 else None
        put(corner, 1, i, GOLD_DARK) if i > 0 else None
    for y in range(3, 6):
        for x in range(3, 6):
            put(corner, x, y, GOLD)
    put(corner, 4, 4, GOLD_DARK)
    img.paste(corner, (0, 0))
    img.paste(corner.rotate(-90), (SIZE - MARGIN, 0))
    img.paste(corner.rotate(180), (SIZE - MARGIN, SIZE - MARGIN))
    img.paste(corner.rotate(90), (0, SIZE - MARGIN))
    return img


def star() -> Image.Image:
    img = Image.new("RGBA", (len(STAR[0]) * 2, len(STAR) * 2), CLEAR)
    for y, row in enumerate(STAR):
        for x, ch in enumerate(row):
            if ch == "#":
                color = (255, 240, 170, 255) if (x, y) == (4, 4) else GOLD
                for dy in range(2):
                    for dx in range(2):
                        img.putpixel((x * 2 + dx, y * 2 + dy), color)
    return img


def main() -> None:
    frame().save("assets/ui/greek_frame.png")
    star().save("assets/ui/star.png")
    print(f"assets/ui/greek_frame.png: {SIZE}x{SIZE}, 9-slice margin {MARGIN}px, unit {UNIT}px")
    print("assets/ui/star.png: 18x18")


if __name__ == "__main__":
    main()
