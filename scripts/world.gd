extends Node2D
## Starting village of Astelia, in the desert. Paints the tile map from an
## ASCII layout and wires scene-to-scene communication (anything in the
## "talker" group -> dialogue box), so those scenes never know about each other.
## Puzzle objects (boulder, plate, gate, altar) are scene instances in world.tscn.

const T := AreaTileset.Tile
const ATLAS: Texture2D = preload("res://assets/tiles/desert.png")

## Legend: . sand  , road  * shrub  ~ water  T olive tree  R roof  H wall  D door
## The fenced area at the top right holds the first altar; its gap is the gate.
const MAP: Array[String] = [
	"TTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
	"T............................T",
	"T..RRRRR.........TTTTTTTTT...T",
	"T..RRRRR.........T.......T...T",
	"T..RRRRR.........T.......T.*.T",
	"T..HHDHH.........T.......T...T",
	"T....,...........T.......T...T",
	"T....,,,,,,,,....TTTT.TTTT...T",
	"T.*.........,........,.......T",
	"T...........,,,,,,,,,,.......T",
	"T..~~~......,................T",
	"T..~~~......,.....*..........T",
	"T...........,................T",
	"T....*......,......TT........T",
	"T.......RRRRR,...............T",
	"T.......RRRRR,...............T",
	"T.......RRRRR,...*...........T",
	"T.......HHDHH,...............T",
	"T.........,,,,...........*...T",
	"TTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
]

## Ground layer: what is under everything (default: sand).
const GROUND := {",": T.PATH, "*": T.DECOR, "~": T.WATER}
## Objects layer: things drawn on top of the ground.
const OBJECTS := {"T": T.TREE, "R": T.ROOF, "H": T.WALL, "D": T.DOOR}

@onready var _ground: TileMapLayer = $Ground
@onready var _objects: TileMapLayer = $Objects
@onready var _player: Player = $Player
@onready var _dialogue: DialogueBox = $DialogueBox


func _ready() -> void:
	var tile_set := AreaTileset.build(ATLAS)
	_ground.tile_set = tile_set
	_objects.tile_set = tile_set
	_paint_map()
	_player.set_camera_limits(get_map_rect())
	for talker in get_tree().get_nodes_in_group("talker"):
		talker.talk_requested.connect(_dialogue.open)


func _paint_map() -> void:
	for y in MAP.size():
		var row := MAP[y]
		assert(row.length() == MAP[0].length(), "MAP row %d has a different width" % y)
		for x in row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			var ground: int = GROUND.get(ch, T.GROUND)
			_ground.set_cell(cell, AreaTileset.SOURCE_ID, AreaTileset.coords(ground))
			if OBJECTS.has(ch):
				_objects.set_cell(cell, AreaTileset.SOURCE_ID, AreaTileset.coords(OBJECTS[ch]))


## Map size in pixels, used to clamp the camera.
func get_map_rect() -> Rect2i:
	var size := Vector2i(MAP[0].length(), MAP.size()) * AreaTileset.TILE_SIZE
	return Rect2i(Vector2i.ZERO, size)
