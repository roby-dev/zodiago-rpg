"""PLACEHOLDER battle sprites (48x48) until the real art exists.

Simple silhouettes so each enemy is recognizable in battle. Replace them by
processing the sprite agent's art into assets/enemies/<id>.png.

Usage:
    python tools/make_enemy_placeholders.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 48
OUTLINE = (20, 22, 48, 255)
OUT = Path("assets/enemies")


def canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def scorpion() -> Image.Image:
    img, d = canvas()
    body, dark = (196, 120, 60, 255), (140, 78, 36, 255)
    d.ellipse((14, 26, 34, 40), fill=body, outline=OUTLINE)          # body
    for x in (12, 18, 24, 30):                                         # legs
        d.line((x, 36, x - 4, 44), fill=OUTLINE, width=2)
    d.ellipse((2, 22, 12, 30), fill=dark, outline=OUTLINE)            # claws
    d.ellipse((36, 22, 46, 30), fill=dark, outline=OUTLINE)
    d.line((8, 28, 16, 32), fill=OUTLINE, width=2)
    d.line((40, 28, 32, 32), fill=OUTLINE, width=2)
    d.line((24, 28, 26, 14), fill=body, width=5)                     # tail
    d.line((26, 14, 22, 6), fill=body, width=5)
    d.polygon([(20, 2), (26, 6), (20, 10)], fill=(240, 200, 90, 255), outline=OUTLINE)
    d.point([(20, 30), (27, 30)], fill=(250, 60, 60, 255))
    return img


def satyr() -> Image.Image:
    img, d = canvas()
    skin, fur = (214, 160, 120, 255), (110, 70, 40, 255)
    d.rectangle((16, 30, 32, 44), fill=fur, outline=OUTLINE)          # goat legs
    d.line((24, 32, 24, 44), fill=OUTLINE, width=1)
    d.rectangle((15, 16, 33, 31), fill=skin, outline=OUTLINE)         # torso
    d.ellipse((17, 4, 31, 18), fill=skin, outline=OUTLINE)            # head
    d.arc((10, 0, 22, 12), 180, 330, fill=(230, 220, 190, 255), width=3)  # horns
    d.arc((26, 0, 38, 12), 210, 360, fill=(230, 220, 190, 255), width=3)
    d.point([(21, 10), (27, 10)], fill=(250, 60, 60, 255))
    d.line((33, 20, 42, 12), fill=fur, width=3)                       # club arm
    d.ellipse((38, 6, 46, 14), fill=fur, outline=OUTLINE)
    return img


def harpy() -> Image.Image:
    img, d = canvas()
    wing, skin = (120, 96, 160, 255), (220, 180, 150, 255)
    d.polygon([(22, 18), (2, 6), (6, 30)], fill=wing, outline=OUTLINE)   # wings
    d.polygon([(26, 18), (46, 6), (42, 30)], fill=wing, outline=OUTLINE)
    d.ellipse((17, 16, 31, 36), fill=wing, outline=OUTLINE)              # body
    d.ellipse((18, 4, 30, 16), fill=skin, outline=OUTLINE)               # head
    d.rectangle((17, 3, 31, 7), fill=(60, 40, 90, 255))                  # hair
    d.point([(21, 10), (27, 10)], fill=(250, 220, 60, 255))
    d.line((20, 36, 18, 44), fill=(230, 190, 80, 255), width=2)          # talons
    d.line((28, 36, 30, 44), fill=(230, 190, 80, 255), width=2)
    return img


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, draw in {"sand_scorpion": scorpion, "wild_satyr": satyr, "harpy": harpy}.items():
        draw().save(OUT / f"{name}.png")
        print(f"{OUT / name}.png: {SIZE}x{SIZE} (placeholder)")


if __name__ == "__main__":
    main()
