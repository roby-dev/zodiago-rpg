"""Build tile/icon atlases from AI-generated source strips.

Each source is a horizontal strip of N cells (any size). Every cell is cut out,
fitted to TILE x TILE, cleaned (binary alpha, shared palette) and placed in the
atlas in the order the game expects (see ATLASES below).

Fit modes:
  crop    - centered square of the cell (no distortion; seamless textures in
            non-square cells, e.g. grass/water).
  squash  - scale the whole cell (near-square cells).
  object  - isolate the object: flood-remove an opaque background from the cell
            borders, drop tiny pixel islands (bleed from neighbor cells, loose
            pebbles), then fit the object's bounding box keeping its aspect.
            Variants: "object" (centered) and "object-bottom" (sits on the ground).

Usage:
    python tools/process_tiles.py            # build every atlas
    python tools/process_tiles.py desert     # build one atlas
"""

import sys
from collections import deque

from PIL import Image

TILE = 32
COLORS = 64

GROUND = "art_source/tiles/town_ground_source.png"
TOWN = "art_source/tiles/town_source.png"
DESERT = "art_source/tiles/desert_source.png"
PUZZLE = "art_source/tiles/puzzle_source.png"
ICONS = "art_source/ui/armor_icons_source.png"

# name -> (output path, [(source, cells_in_source, index, fit), ...])
# Area atlases MUST follow AreaTileset.Tile order:
#   GROUND, PATH, DECOR, WATER, TREE, ROOF, WALL, DOOR
ATLASES = {
    "town": ("assets/tiles/town.png", [
        (GROUND, 4, 0, "crop"), (GROUND, 4, 1, "crop"), (GROUND, 4, 2, "crop"),
        (GROUND, 4, 3, "crop"), (TOWN, 8, 4, "squash"), (TOWN, 8, 5, "squash"),
        (TOWN, 8, 6, "squash"), (TOWN, 8, 7, "squash"),
    ]),
    "desert": ("assets/tiles/desert.png", [(DESERT, 8, i, "squash") for i in range(8)]),
    # Order: BOULDER, PLATE_UP, PLATE_DOWN, GATE_CLOSED, GATE_OPEN, LEVER_OFF, LEVER_ON, ALTAR
    "puzzle": ("assets/tiles/puzzle.png", [
        (PUZZLE, 8, 0, "object-bottom"), (PUZZLE, 8, 1, "object"), (PUZZLE, 8, 2, "object"),
        (PUZZLE, 8, 3, "object-bottom"), (PUZZLE, 8, 4, "object-bottom"),
        (PUZZLE, 8, 5, "object-bottom"), (PUZZLE, 8, 6, "object-bottom"),
        (PUZZLE, 8, 7, "object-bottom"),
    ]),
    # Order: bracers, boots, chest plate, shoulder pads + cape, tiara
    "armor_icons": ("assets/ui/armor_icons.png", [(ICONS, 5, i, "object") for i in range(5)]),
}

BG_TOLERANCE = 60       # max RGB distance to the corner color to count as background
MIN_ISLAND = 0.03       # islands smaller than 3% of the object's pixels are dropped


def load_strip(path: str) -> Image.Image:
    """Load a strip and trim the transparent padding around it."""
    img = Image.open(path).convert("RGBA")
    alpha = img.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
    return img.crop(alpha.getbbox())


def cut(strip: Image.Image, count: int, index: int, fit: str) -> Image.Image:
    width = strip.width / count
    cell = strip.crop((round(index * width), 0, round((index + 1) * width), strip.height))
    if fit.startswith("object"):
        return fit_object(isolate(cell), bottom=fit.endswith("bottom"))
    if fit == "crop":
        side = min(cell.size)
        left, top = (cell.width - side) // 2, (cell.height - side) // 2
        cell = cell.crop((left, top, left + side, top + side))
    return cell.resize((TILE, TILE), Image.Resampling.BOX)


def isolate(cell: Image.Image) -> Image.Image:
    """Remove an opaque background reachable from the borders and tiny islands."""
    cell = cell.copy()
    w, h = cell.size
    px = cell.load()
    solid = [[px[x, y][3] >= 128 for x in range(w)] for y in range(h)]

    # 1) Opaque background: flood from the border over pixels close to the corner color.
    corner = px[0, 0]
    if corner[3] >= 128:
        def is_bg(p):
            return p[3] >= 128 and sum((p[i] - corner[i]) ** 2 for i in range(3)) <= BG_TOLERANCE ** 2
        seen = [[False] * w for _ in range(h)]
        queue = deque((x, y) for x in range(w) for y in (0, h - 1))
        queue.extend((x, y) for y in range(h) for x in (0, w - 1))
        while queue:
            x, y = queue.popleft()
            if not (0 <= x < w and 0 <= y < h) or seen[y][x] or not is_bg(px[x, y]):
                continue
            seen[y][x] = True
            solid[y][x] = False
            queue.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))

    # 2) Drop tiny islands of solid pixels (neighbor bleed, loose pebbles).
    label = [[0] * w for _ in range(h)]
    islands: list[list[tuple[int, int]]] = []
    for sy in range(h):
        for sx in range(w):
            if not solid[sy][sx] or label[sy][sx]:
                continue
            island, queue = [], deque([(sx, sy)])
            label[sy][sx] = len(islands) + 1
            while queue:
                x, y = queue.popleft()
                island.append((x, y))
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and solid[ny][nx] and not label[ny][nx]:
                        label[ny][nx] = label[sy][sx]
                        queue.append((nx, ny))
            islands.append(island)
    total = sum(len(i) for i in islands) or 1
    for y in range(h):
        for x in range(w):
            if not solid[y][x] or len(islands[label[y][x] - 1]) < total * MIN_ISLAND:
                r, g, b, _ = px[x, y]
                px[x, y] = (r, g, b, 0)
    return cell


def fit_object(obj: Image.Image, bottom: bool) -> Image.Image:
    """Scale the object's bounding box into the tile, keeping its aspect ratio."""
    alpha = obj.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
    obj = obj.crop(alpha.getbbox())
    k = min(TILE / obj.width, TILE / obj.height)
    size = (max(1, round(obj.width * k)), max(1, round(obj.height * k)))
    obj = obj.resize(size, Image.Resampling.BOX)
    tile = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    y = TILE - size[1] if bottom else (TILE - size[1]) // 2
    tile.alpha_composite(obj, ((TILE - size[0]) // 2, y))
    return tile


def clean(img: Image.Image) -> Image.Image:
    """Binary alpha + one shared palette for the whole atlas."""
    alpha = img.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
    rgb = Image.new("RGB", img.size, (0, 0, 0))
    rgb.paste(img.convert("RGB"), mask=alpha)
    reduced = rgb.quantize(colors=COLORS, method=Image.Quantize.MEDIANCUT).convert("RGBA")
    reduced.putalpha(alpha)
    return reduced


def build(name: str) -> None:
    output, layout = ATLASES[name]
    strips: dict[str, Image.Image] = {}
    atlas = Image.new("RGBA", (TILE * len(layout), TILE), (0, 0, 0, 0))
    for i, (source, count, index, fit) in enumerate(layout):
        if source not in strips:
            strips[source] = load_strip(source)
        atlas.alpha_composite(cut(strips[source], count, index, fit), (i * TILE, 0))
    clean(atlas).save(output)
    print(f"{output}: {atlas.width}x{atlas.height} ({len(layout)} tiles of {TILE}px)")


def main() -> None:
    names = sys.argv[1:] or list(ATLASES)
    for name in names:
        build(name)


if __name__ == "__main__":
    main()
