# Armor progression + desert start

Objective: hero starts without armor in a desert village and earns armor pieces one by one by solving puzzles; the full set grants special effects.
Branch: none (project is not a git repository; no work-unit commits). Delivery: n/a. Test runner: headless Godot script `tests/run_tests.gd` + runtime checks via godot-mcp.

## Specs

- **S1** — "el inicio debe ser sin nada de armadura, y se va obteniendo poco a poco. cada pieza por pieza, al completar da efectos esepciales"
  - Hero starts at stage 0 (no armor). Each piece raises the stage by one and swaps the hero sprite.
  - Pieces in fixed order (user: "si seria asi" to fixed order): bracers -> boots -> chest plate -> shoulder pads + cape -> winged tiara.
  - Completing the set (stage 5) triggers a special effect. Assumption: a visible aura now; gameplay bonuses come with the combat system.
- **S2** — "con un mapa explorarble, para obtner cada pieza, con distintsos puzzles"
  - Each piece is obtained from an altar after solving a puzzle. This delivery: the first puzzle (push a boulder onto a pressure plate to open a gate guarding the altar with the first piece).
  - Obtaining a piece shows a message with the piece icon.
- **S3** — "el inicio tieneq ue ser sin tanto pasto, cn mas tierra desierto, asi deberia inciari el pj"
  - The game starts in a desert village using the desert tileset.
- **S4** — Assets reviewed in this session must be processed into `assets/` with reproducible scripts in `tools/` (desert atlas, hero stages 0-4, armor icons, puzzle props with plate background removed and per-object bbox).

## Tasks

| ID | Specs | Route | Status | Evidence |
|---|---|---|---|---|
| T1 | S4 | inline | done | assets/tiles/{desert,puzzle}.png, assets/ui/armor_icons.png, hero_stage0-5.png; visual check at 32px |
| T2 | S3 | inline | done | AreaTileset(atlas); RED->GREEN tests/run_tests.gd (collision per tile); world uses desert atlas |
| T3 | S1 | inline | done | GameState autoload; RED->GREEN 37 checks; runtime: stage 1 sprite after altar, stage 5 shows cape+tiara+aura |
| T4 | S1, S2 | inline | done | runtime: dialogue shows bracers icon + "¡Obtuviste: Brazaletes de plata!" |
| T5 | S2 | inline | done | runtime: player push moves boulder; boulder on plate -> pressed=true, gate is_open=true, stays open after boulder leaves |
| T6 | S2, S3 | inline | done | runtime: desert start map renders, tree borders block the player, altar gives the first piece |

- T1: process assets (desert atlas, hero stages, icons, puzzle props).
- T2: generalize the tileset to load any area atlas; world uses the desert atlas.
- T3: `GameState` autoload with armor stage + set-complete signal; hero sprite follows the stage; aura at full set.
- T4: "piece obtained" message with icon (dialogue box supports an icon).
- T5: puzzle pieces: Boulder (grid push), PressurePlate, Gate, Altar.
- T6: desert start map with the first puzzle and the first piece; elder hint.

Route evidence: no Writer trigger (single sequential feature, no parallel units, context well below backstop) -> all inline.

## Log

- L1 (2026-11-18, user): "esta bien PERO, el inicio debe ser sin nada de armadura, y se va obteniendo poco a poco. cada pieza por pieza, al completar da efectos esepciales. no se porque arrancamos con toda la armadura de una"
- L2 (2026-11-18, user): "si seria asi, con un mapa explorarble, para obtner cada pieza, con distintsos puzzles. que png neceistas para esto?"
- L3 (2026-11-18, user): "y sabes el inicio tieneq ue ser sin tanto pasto, cn mas tierra desierto, asi deberia inciari el pj"
- L4 (2026-11-18, user): "si dale.!" — authorizes processing the reviewed assets and implementing the armor system, desert start and first puzzle.
- L5: assets reviewed: desert approved; hero stages approved (frames match within 1 px); icons approved (fit by bbox); puzzle props usable after removing the plate background and per-object bbox extraction.
- L6: all tasks done. Tests: `godot --headless --path . -s tests/run_tests.gd` -> 37 checks, 0 failures. Known limits: the boulder can be pushed into a corner (no reset yet); holding a direction keeps pushing.
- L7 (2026-11-18, user): "con godot no puedes crear el tileset? o como veo lo qe creas en godot?"
