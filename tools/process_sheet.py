"""Convert an AI-generated "pixel-art-looking" spritesheet into real pixel art.

The input is a 3 columns x 4 rows sheet of any size (rows: down, left, right, up;
columns: stand, walk A, walk B). Each cell is downscaled to an exact frame size,
alpha is made binary (fully opaque or fully transparent) and colors are reduced
to a small palette, so the result renders crisp with nearest-neighbor filtering.

Usage:
    python tools/process_sheet.py INPUT.png OUTPUT.png [--frame 16x24] [--colors 64]
"""

import argparse

from PIL import Image

COLS, ROWS = 3, 4


def process(src: Image.Image, frame_w: int, frame_h: int, colors: int) -> Image.Image:
    src = src.convert("RGBA")
    cell_w = src.width / COLS
    cell_h = src.height / ROWS
    out = Image.new("RGBA", (frame_w * COLS, frame_h * ROWS), (0, 0, 0, 0))
    for row in range(ROWS):
        for col in range(COLS):
            box = (round(col * cell_w), round(row * cell_h),
                   round((col + 1) * cell_w), round((row + 1) * cell_h))
            cell = src.crop(box).resize((frame_w, frame_h), Image.Resampling.BOX)
            out.paste(cell, (col * frame_w, row * frame_h))
    return _clean(out, colors)


def _clean(img: Image.Image, colors: int) -> Image.Image:
    """Binary alpha + shared palette for the whole sheet (consistent colors)."""
    alpha = img.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
    # Quantize only RGB, over a black matte, then restore the binary alpha.
    rgb = Image.new("RGB", img.size, (0, 0, 0))
    rgb.paste(img.convert("RGB"), mask=alpha)
    reduced = rgb.quantize(colors=colors, method=Image.Quantize.MEDIANCUT).convert("RGB")
    result = reduced.convert("RGBA")
    result.putalpha(alpha)
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("input")
    parser.add_argument("output")
    parser.add_argument("--frame", default="16x24", help="frame size WxH (default 16x24)")
    parser.add_argument("--colors", type=int, default=64, help="palette size (default 64)")
    args = parser.parse_args()
    frame_w, frame_h = (int(v) for v in args.frame.lower().split("x"))
    result = process(Image.open(args.input), frame_w, frame_h, args.colors)
    result.save(args.output)
    print(f"{args.output}: {result.width}x{result.height}, frame {frame_w}x{frame_h}")


if __name__ == "__main__":
    main()
