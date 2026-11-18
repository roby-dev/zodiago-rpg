extends Node
## Global game progress (autoload "GameState"): armor and bag.
## The hero earns armor pieces in a FIXED order; the armor stage is the number
## of pieces owned (0 = no armor, FULL_SET = complete set) and selects the
## hero spritesheet (assets/characters/hero_stage<N>.png).

signal armor_changed(stage: int)
## Emitted once, when the last piece completes the set.
signal set_completed
signal inventory_changed

## Order in which the pieces are obtained (= order in assets/ui/armor_icons.png).
enum Piece { BRACERS, BOOTS, CHEST, SHOULDERS, TIARA }

const PIECE_NAMES: Array[String] = [
	"Brazaletes de plata",
	"Botas de plata",
	"Pechera de plata",
	"Hombreras y capa",
	"Tiara alada",
]
const FULL_SET := 5
const ICONS: Texture2D = preload("res://assets/ui/armor_icons.png")
const ICON_SIZE := 32

## Item catalog: id -> data shown in the bag.
const ITEMS := {
	"fig_bread": {
		"name": "Pan de higo",
		"description": "Pan dulce del desierto. Repone un poco de energía.",
	},
}
const STARTING_ITEMS := {"fig_bread": 2}

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
