# Turn-based combat with cosmos

Objective: random turn-based battles inspired by the mechanics of the user's reference game (adapted, nothing copied), improved where its reviews complain.
Branch: main (uncommitted; commits only when the user asks). Test runner: `godot --headless --path . -s tests/run_tests.gd`; visuals via `godot --path . -s tests/ui_snapshots.gd`.

## Specs

- **S1** — Random encounters: "al azar". Improvement over the reference ("battles every two seconds"): roads are safe, and battles start only on sand after a random 10-22 steps.
- **S2** — Turn-based battle (brief: "combate por turnos con cosmos en vez de PP"): commands Atacar / Técnica / Bolsa / Huir; turn order by speed; 1-2 original desert enemies.
- **S3** — Cosmos replaces PP: techniques cost cosmos; techniques are learned by level and named after the constellation relics.
- **S4** — Stats and levels (brief: "stats y niveles"): HP, cosmos, attack, defense, speed; experience from victories; level-ups raise stats and teach techniques.
- **S5** — Armor ties in: each armor piece adds defense and max cosmos; the full set (S1 of armor-progression: "al completar da efectos esepciales") regenerates cosmos every round.
- **S6** — Outcomes: victory gives experience; defeat returns the hero to the village healed (no game over); fleeing can fail. Melina (oracle) heals the hero when talked to.
- **S7** — The menu shows a Status tab (level, experience, HP, cosmos, stats, techniques).
- Assumption: enemy art is placeholder until the user's sprite agent generates it (prompt in docs/art_prompts.md).

## Tasks

| ID | Specs | Route | Status | Evidence |
|---|---|---|---|---|
| T1 | S2, S3, S4, S5 | inline | done | RED (Combatant missing) -> GREEN 120 checks: damage, techniques, cosmos, flee, regen, cards, levels, armor bonus, HP persistence, encounters, catalog |
| T2 | S1 | inline | done | EncounterCounter tested (safe steps never trigger; 10-22 wild steps); runtime: walking on sand started a battle |
| T3 | S2, S6 | inline | done | snapshots: intro, commands, techniques (cost + description), target star, round; runtime: battle played to victory with Z, +6 exp |
| T4 | S6, S7 | inline | partial | Status tab snapshot OK; defeat respawn and Melina healing NOT verified at runtime |

- T1: battle logic (Combatant, Battle, Techniques, EnemyCatalog, hero stats/levels in GameState) with headless tests.
- T2: RandomEncounters (step counter, safe roads) + Player `stepped` signal.
- T3: BattleScreen UI (enemies, hero status, messages, command menu) + placeholder enemy sprites + art prompt.
- T4: wiring in World (encounter -> battle -> outcome), Melina heals, Status tab in the menu.

Route evidence: one sequential feature, units depend on each other (UI needs logic) -> no Writer trigger, all inline.

## Log

- L1 (2026-11-18, user): "mira explora en internet. Saint Seiya Paradise: Saikyou no Senshi-tachi ese es el que quiero qe te bases, no es que lo rehagas por el copuruytght es oslo para mi y mi sueño smierpe ha sido mejrorarlo"
- L2 (2026-11-18, user): "al azar" (answer to: random encounters vs visible enemies).
- L3: research: reference = Game Boy 1992 RPG; turn-based random battles, cosmos as MP, party of 4, level-based growth, cards as items; reviews criticize very frequent battles and linearity. Boundary: adapt mechanics only, no characters/art/music/levels.
- L4: implemented T1-T4. Fixes found by visual checks: battle sky was translucent (added opaque backdrop); 9-slice center tiling sampled the gold band (added a 3 px fill gap, margins 27). Known limits: enemy art is placeholder; items cannot be used from the menu outside battle; defeat/respawn and Melina healing untested at runtime.
