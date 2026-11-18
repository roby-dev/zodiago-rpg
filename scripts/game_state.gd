extends Node
## Global game progress (autoload "GameState"): armor, bag and hero level.
## The hero earns armor pieces in a FIXED order; the armor stage is the number
## of pieces owned (0 = no armor, FULL_SET = complete set) and selects the
## hero spritesheet (assets/characters/hero_stage<N>.png).

signal armor_changed(stage: int)
## Emitted once, when the last piece completes the set.
signal set_completed
signal inventory_changed

## Order in which the pieces are obtained (= order in assets/ui/armor_icons.png).
enum Piece { BRACERS, BOOTS, CHEST, SHOULDERS, TIARA }

## Each piece is a relic of a constellation; its myth explains its shape.
const PIECE_NAMES: Array[String] = [
	"Brazaletes de Hércules",
	"Botas de Perseo",
	"Pechera de Orión",
	"Manto de Casiopea",
	"Tiara de Áquila",
]
const PIECE_LORE: Array[String] = [
	"Guardan la fuerza del héroe de los doce trabajos.",
	"Ligeras como las sandalias aladas que Hermes le dio a Perseo.",
	"Las tres estrellas del cinturón del cazador brillan en su hebilla.",
	"El manto de la reina que gira eternamente alrededor del polo.",
	"Las alas del águila de Zeus coronan a quien completa el camino.",
]
const FULL_SET := 5
const ICONS: Texture2D = preload("res://assets/ui/armor_icons.png")
const ICON_SIZE := 32

## Item catalog: id -> data shown in the bag.
const ITEMS := {
	"ambrosia": {
		"name": "Ambrosía menor",
		"description": "Unas gotas del alimento de los dioses. Repone 10 de cosmos.",
		"effect": {"cosmos": 10},
	},
	"nectar": {
		"name": "Néctar",
		"description": "La bebida de los dioses cierra las heridas. Repone 15 PS.",
		"effect": {"hp": 15},
	},
}
const STARTING_ITEMS := {"ambrosia": 2, "nectar": 3}

const HERO_NAME := "Aspirante"
## Level 1 stats; each level adds HERO_GROWTH.
const HERO_BASE := {"max_hp": 30, "max_cosmos": 12, "attack": 8, "defense": 4, "speed": 6}
const HERO_GROWTH := {"max_hp": 6, "max_cosmos": 3, "attack": 2, "defense": 1, "speed": 1}
## Bonus per armor piece, and cosmos regenerated per round with the full set.
const ARMOR_DEFENSE := 2
const ARMOR_COSMOS := 2
const SET_COSMOS_REGEN := 2

var level := 1
## Experience gathered toward the next level.
var experience := 0
## Damage and spent cosmos are stored (not current values), so a level-up
## that raises the maximums keeps the hero just as hurt as before.
var _hp_lost := 0
var _cosmos_spent := 0

var armor_stage := 0
## Bag contents: item id -> count (only ids with count > 0).
var _bag: Dictionary[String, int] = {}


func _init() -> void:
	for id: String in STARTING_ITEMS:
		_bag[id] = STARTING_ITEMS[id]


## The piece the hero must obtain next, or -1 when the set is complete.
func next_piece() -> int:
	return armor_stage if armor_stage < FULL_SET else -1


func is_set_complete() -> bool:
	return armor_stage >= FULL_SET


## Takes a piece. Only the next piece in order is accepted.
func obtain(piece: Piece) -> bool:
	if piece != next_piece():
		return false
	armor_stage += 1
	armor_changed.emit(armor_stage)
	if is_set_complete():
		set_completed.emit()
	return true


func piece_icon(piece: Piece) -> AtlasTexture:
	var icon := AtlasTexture.new()
	icon.atlas = ICONS
	icon.region = Rect2(piece * ICON_SIZE, 0, ICON_SIZE, ICON_SIZE)
	return icon


## Pieces owned so far, in the order they were obtained.
func owned_pieces() -> Array[int]:
	var pieces: Array[int] = []
	pieces.assign(range(armor_stage))
	return pieces


## Item ids in the bag, in the order they were first added.
func bag_items() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_bag.keys())
	return ids


func item_count(id: String) -> int:
	return _bag.get(id, 0)


func add_item(id: String, count := 1) -> void:
	assert(ITEMS.has(id), "Unknown item: %s" % id)
	_bag[id] = item_count(id) + count
	inventory_changed.emit()


## Removes items; fails (and changes nothing) if there are not enough.
func remove_item(id: String, count := 1) -> bool:
	if item_count(id) < count:
		return false
	_bag[id] -= count
	if _bag[id] == 0:
		_bag.erase(id)
	inventory_changed.emit()
	return true


## Experience needed to reach the next level.
func exp_to_next() -> int:
	return 10 * level


## Adds experience and returns the level-up / new technique messages.
func gain_exp(amount: int) -> Array[String]:
	var messages: Array[String] = []
	experience += amount
	while experience >= exp_to_next():
		experience -= exp_to_next()
		level += 1
		messages.append("¡Subiste al nivel %d!" % level)
		for id in Techniques.learned_at(level):
			messages.append("Aprendiste %s." % Techniques.ALL[id]["name"])
	return messages


func known_techniques() -> Array[String]:
	return Techniques.known_at(level)


func cosmos_regen() -> int:
	return SET_COSMOS_REGEN if is_set_complete() else 0


## Current hero stats: base + level growth + armor pieces.
func hero_stats() -> Dictionary:
	var stats := {}
	for key: String in HERO_BASE:
		stats[key] = HERO_BASE[key] + HERO_GROWTH[key] * (level - 1)
	stats["defense"] += ARMOR_DEFENSE * armor_stage
	stats["max_cosmos"] += ARMOR_COSMOS * armor_stage
	return stats


## A fresh Combatant for a battle, with the hero's current HP and cosmos.
func hero_combatant() -> Combatant:
	var stats := hero_stats()
	stats["hp"] = maxi(1, stats["max_hp"] - _hp_lost)
	stats["cosmos"] = maxi(0, stats["max_cosmos"] - _cosmos_spent)
	return Combatant.new(HERO_NAME, stats)


## Saves HP and cosmos after a battle.
func store_hero(hero: Combatant) -> void:
	_hp_lost = hero.max_hp - hero.hp
	_cosmos_spent = hero.max_cosmos - hero.cosmos


func restore_hero() -> void:
	_hp_lost = 0
	_cosmos_spent = 0
