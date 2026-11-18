# Art prompts

Prompts for the sprite-generation agent. The game grid is **32x32 px** (`Grid.TILE`).
Generated images go to `art_source/` and are converted with `tools/process_sheet.py`.

## Character spritesheet (32x48 frames)

Replace the `CHARACTER` block with the new character's description.

```text
Create a pixel-art character spritesheet for a top-down 2D RPG
(overworld style like 16-bit / GBA era RPGs).

=== STRICT TECHNICAL FORMAT (most important) ===
- Each frame: exactly 32 px wide x 48 px tall.
- Sheet layout: 3 columns x 4 rows = 96 x 192 px total.
  - Rows (top to bottom): 1 = facing DOWN, 2 = facing LEFT, 3 = facing RIGHT, 4 = facing UP.
  - Columns (left to right): 1 = standing, 2 = walking (left foot forward), 3 = walking (right foot forward).
- Character's feet touch the bottom edge of each frame; centered horizontally.
- Same size, proportions and position across all frames (no jitter between frames).
- True pixel art: hard pixel edges, NO anti-aliasing, NO blur, NO gradients, NO dithering noise.
- 1 px dark outline (very dark navy, not pure black) around the character.
- Max ~32 colors. Flat colors with 1-2 shades + 1 highlight per material.
- Fully transparent background (PNG with alpha). No shadow under the feet.
- If you cannot output at native size, keep the exact 1:2 sheet ratio and the 3x4 grid;
  it will be downscaled with nearest-neighbor.

=== ART STYLE ===
Mythic Greek + zodiac fantasy, 90s anime-inspired, under a starry night palette:
deep blues and violets, polished silver metal with bright highlights, gold trims.
ORIGINAL designs only: do not copy or reference characters, armor designs or logos
from any existing anime, manga or game.

=== CHARACTER ===
<describe the character here: role, hair, armor/clothes, colors, accessories>
```

## Hero armor stages (32x48 frames)

The hero gains armor piece by piece, in a fixed order. `assets/characters/hero.png`
is the final stage (full set). Attach `art_source/characters/hero_source.png` to the
agent as the reference image. Save the results as
`art_source/characters/hero_stage0_source.png` ... `hero_stage4_source.png`.

| Stage | Wears |
|---|---|
| 0 | No armor: plain blue bodysuit only |
| 1 | + silver forearm guards with gold bracers |
| 2 | + silver armored boots |
| 3 | + silver chest plate with gold belt |
| 4 | + large silver shoulder pads and the violet cape |
| 5 | + gold winged tiara (= current hero.png, full set) |

```text
I attach the spritesheet of a character in FULL ARMOR. Create 5 new spritesheets of
the EXACT SAME character, removing armor pieces, one file per stage:

- stage0: NO armor at all. Same spiky dark hair, same face, same body, wearing only
  the plain deep-blue bodysuit (add simple dark-blue cloth shoes). No cape, no tiara,
  no belt, no bracers.
- stage1: stage0 + the silver forearm guards with gold bracers.
- stage2: stage1 + the silver armored boots.
- stage3: stage2 + the silver chest plate with the gold belt.
- stage4: stage3 + the large silver shoulder pads and the violet cape.
  (Only the gold winged tiara is missing compared to the attached image.)

CRITICAL - consistency between stages:
- Identical layout to the attached sheet: 3 columns x 4 rows, same frame size,
  rows = down, left, right, up; columns = standing, walk left foot, walk right foot.
- Same pose, same body position and same pixels in every frame of every stage;
  ONLY the listed armor pieces change. The character must not move, resize or
  change proportions between stages.
- Each piece must look exactly like it does in the attached full-armor sheet.
- True pixel art, hard edges, no anti-aliasing, fully transparent background,
  same 1 px dark navy outline and same palette as the attached image.
```

## Armor piece icons (32x32)

For the inventory and the "piece obtained" message. Save as
`art_source/ui/armor_icons_source.png`.

```text
Create 5 pixel-art item ICONS for an RPG inventory, matching the attached hero's armor.

Layout: ONE row of 5 icons, each exactly 32x32 px (160 x 32 px total), in this order:
  1. silver forearm guards with gold bracers (a pair)
  2. silver armored boots (a pair)
  3. silver chest plate with gold belt
  4. large silver shoulder pads with a folded violet cape
  5. gold circlet/tiara with small silver wings

Each icon centered in its cell, seen from the front, slightly 3/4.
True pixel art, hard edges, no anti-aliasing, 1 px dark navy outline,
transparent background, no text, no frames, no gaps.
If you cannot output at native size, keep the exact 5:1 ratio.
```

## Puzzle props (32x32 tiles)

Objects for the first exploration puzzles. Save as `art_source/tiles/puzzle_source.png`.

```text
Create pixel-art PUZZLE OBJECTS for a top-down 2D RPG, same style as the attached village tileset.

Layout: ONE row of 8 tiles, each exactly 32x32 px (256 x 32 px total), in this order:
  1. BOULDER        - round grey stone the player can push, fills most of the tile.
  2. PLATE_UP       - stone pressure plate on the floor, raised.
  3. PLATE_DOWN     - the same plate, pressed down (slightly darker, sunken).
  4. GATE_CLOSED    - iron bars gate in a stone frame, closed.
  5. GATE_OPEN      - the same gate, open (bars raised, passable).
  6. LEVER_OFF      - small lever on a stone base, tilted left.
  7. LEVER_ON       - the same lever tilted right, with a small glowing blue gem.
  8. ALTAR          - small Greek marble pedestal with zodiac carvings, empty on top
                      (the armor piece will be drawn on top of it).

Tiles 1, 4, 5, 6, 7, 8 on a TRANSPARENT background (drawn over the floor);
tiles 2 and 3 opaque floor tiles matching the village path.
True pixel art, hard edges, no anti-aliasing, 1 px dark outline on objects.
Greek myth + zodiac style. If you cannot output at native size, keep the exact 8:1 ratio.
```

## Battle enemies (48x48)

Replace the placeholders in `assets/enemies/` (made by `tools/make_enemy_placeholders.py`).
Save as `art_source/enemies/enemies_source.png`.

```text
Create pixel-art BATTLE SPRITES of 3 monsters for a turn-based RPG (16-bit / GBA era),
shown from the front, facing the player, like classic first-person RPG battles.

=== STRICT TECHNICAL FORMAT (most important) ===
- Layout: ONE row of 3 sprites, each exactly 48 x 48 px (144 x 48 px total), in this order:
  1. SAND SCORPION - a giant desert scorpion, ochre and rust colors, raised claws,
                     curled tail with a golden stinger.
  2. WILD SATYR    - a wild creature of Greek myth: goat legs, human torso, curved horns,
                     holding a wooden club, angry expression.
  3. HARPY         - a harpy of Greek myth: woman's face and torso, large violet feathered
                     wings, golden talons.
- Each monster centered, standing on the bottom edge of its cell, filling most of it.
- Fully TRANSPARENT background. No shadows, no ground, no text, no gaps.
- True pixel art: hard pixel edges, NO anti-aliasing, NO blur, NO gradients.
- 1 px dark navy outline. Max ~24 colors per sprite. Light from the top-left.
- If you cannot output at native size, keep the exact 3:1 ratio and square cells.

=== ART STYLE ===
Greek myth and zodiac fantasy, 90s anime-inspired, threatening but readable.
ORIGINAL designs: no references to existing games, anime or manga.
```

## Greek props (32x32 tiles)

Decoration that gives the village its Greek identity. Save as
`art_source/tiles/greek_props_source.png`. Attach `art_source/tiles/desert_source.png`
as the style reference.

```text
Create pixel-art DECORATION OBJECTS for a top-down 2D RPG (16-bit / GBA era style),
for a small village of ANCIENT GREECE in an arid Aegean land. Match the style and
palette of the attached desert tileset.

=== STRICT TECHNICAL FORMAT (most important) ===
- Layout: ONE row of 8 tiles, each exactly 32 x 32 px (256 x 32 px total), in this order:
  1. COLUMN        - one intact white marble Doric column with fluting, seen from a
                     slight top-down view, base at the bottom of the tile.
  2. RUINED_COLUMN - the same column broken in half, with a few fallen stone chunks.
  3. AMPHORA       - a terracotta amphora with black-figure decoration (simple
                     geometric bands and a meander stripe), standing.
  4. BRAZIER       - a bronze tripod brazier with a bright burning fire.
  5. STATUE        - a small marble statue of a warrior holding a spear and a round
                     shield, on a square plinth. Generic and ORIGINAL (no known character).
  6. MARBLE_FLOOR  - white marble floor slabs with thin grey seams, seamless on all
                     4 sides, NO border (opaque tile).
  7. STAIRS        - wide white marble steps going up (toward the top of the tile),
                     seamless left/right (opaque tile).
  8. BLUE_DOOR     - the village whitewashed wall (same as the attached WALL tile) with
                     an Aegean-blue wooden door and a small blue window shutter
                     (opaque tile, matches WALL at its left/right edges).
- Tiles 1-5 on a TRANSPARENT background (drawn over the ground); tiles 6-8 opaque.
- True pixel art: hard pixel edges, NO anti-aliasing, NO blur, NO gradients.
- 1 px dark outline on objects (1-5). Light from the top-left, strong midday sun.
- Max ~32 colors: marble whites and greys, terracotta, bronze, Aegean blue, gold accents.
- No grid lines, labels or gaps. If you cannot output at native size, keep the exact
  8:1 ratio and make every tile a perfect square.

=== ART STYLE ===
Ancient Greece, myth and zodiac. ORIGINAL art, no references to existing games or anime.
```

## Desert starting village tileset (32x32 tiles)

Same 8 slots and order as the town tileset, so the same code can load it.
Save as `art_source/tiles/desert_source.png`.

```text
Create a pixel-art TILESET for the STARTING VILLAGE of a top-down 2D RPG
(16-bit / GBA era style): a small, poor village in an arid, desert-like land
of Greek myth (dry Mediterranean / Aegean desert, NOT Egyptian, NOT Arabian).

=== STRICT TECHNICAL FORMAT (most important) ===
- Each tile: exactly 32 x 32 px, top-down (slight 3/4) view.
- Layout: ONE row of 8 tiles = 256 x 32 px total, in EXACTLY this order (left to right):
  1. SAND    - warm sandy ground, seamless on all 4 sides. NO border, NO frame.
  2. ROAD    - packed dry earth road with a few small pebbles, filling the WHOLE tile,
               seamless on all 4 sides. NO sand edges, NO border.
  3. DECOR   - the SAND tile with a small dry shrub and 2 small rocks in the middle;
               edges identical to SAND.
  4. WATER   - small oasis/well water, turquoise, seamless on all 4 sides. NO border.
  5. TREE    - one old olive tree (twisted trunk, sparse grey-green leaves) seen from above,
               TRANSPARENT background, fills most of the tile.
  6. ROOF    - flat sun-bleached clay/terracotta roof, seamless on all 4 sides.
  7. WALL    - whitewashed adobe/stone wall with a small square window, simple eave on top
               and stone base at the bottom; seamless left/right.
  8. DOOR    - the same wall with a weathered wooden door; matches WALL at left/right edges.
- SEAMLESS means: no border, frame, outline or darker edge on tiles 1, 2, 3, 4 and 6;
  the left edge continues the right edge and the top edge continues the bottom edge.
- True pixel art: hard pixel edges, NO anti-aliasing, NO blur, NO gradients.
- Max ~32 colors. Light from the top-left, strong midday sun.
- All tiles opaque EXCEPT tile 5 (TREE), which has a transparent background.
- No grid lines, labels or gaps between tiles. If you cannot output at native size,
  keep the exact 8:1 ratio and make every tile a perfect square.

=== ART STYLE ===
Sun-baked ochres, sand yellows, dusty oranges and bleached whites, with a few
turquoise and olive-green accents. Must look coherent next to anime-style 32x48
character sprites with dark navy 1 px outlines. ORIGINAL art, no references to existing games.
```

## Town tileset (32x32 tiles)

The order MUST match `AreaTileset.Tile` in `scripts/area_tileset.gd` (GRASS=GROUND, FLOWER=DECOR).

```text
Create a pixel-art TILESET for a top-down 2D RPG village (16-bit / GBA era style),
to be used on a grid.

=== STRICT TECHNICAL FORMAT (most important) ===
- Each tile: exactly 32 x 32 px. Viewed from directly above / slight top-down (3/4) view.
- Layout: ONE row of 8 tiles = 256 x 32 px total, in EXACTLY this order (left to right):
  1. GRASS  - plain grass, seamless (tiles perfectly with itself on all 4 sides).
  2. PATH   - dirt path, seamless on all 4 sides.
  3. FLOWER - grass with 2-3 small flowers; edges identical to GRASS so they blend.
  4. WATER  - pond water with small ripples, seamless on all 4 sides.
  5. TREE   - one round bushy tree seen from above, trunk at the bottom,
              TRANSPARENT background (it is drawn on top of grass), fills most of the tile.
  6. ROOF   - red/terracotta roof tiles, seamless on all 4 sides.
  7. WALL   - cream plaster house wall with one small window centered,
              seamless left/right (repeats horizontally).
  8. DOOR   - the same wall with a wooden door instead of the window,
              matches WALL exactly at its left/right edges.
- True pixel art: hard pixel edges, NO anti-aliasing, NO blur, NO gradients.
- Max ~32 colors for the whole tileset. Consistent light source from the top-left.
- All tiles opaque EXCEPT tile 5 (TREE), which has a transparent background.
- No grid lines, no borders, no labels, no gaps between tiles.
- If you cannot output at native size, keep the exact 8:1 ratio (e.g. 2048 x 256);
  it will be downscaled with nearest-neighbor.

=== ART STYLE ===
Peaceful village in a world of Greek myth and zodiac constellations, night-sky
inspired palette but daytime lighting: lush greens, warm terracotta roofs, cream walls,
deep blue water. Must look coherent next to anime-style 32x48 character sprites with
dark navy 1 px outlines. ORIGINAL art, no references to existing games.
```
