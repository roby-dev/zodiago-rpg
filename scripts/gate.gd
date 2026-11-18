class_name Gate
extends StaticBody2D
## Barred gate that opens when ALL its plates are pressed.

const FRAME_CLOSED := 3
const FRAME_OPEN := 4

@export var plates: Array[PressurePlate] = []
## If true, the gate stays open once solved even if a plate is released.
@export var stays_open := true

var is_open := false

@onready var _sprite: Sprite2D = $Sprite
@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	for plate in plates:
		plate.toggled.connect(func(_pressed: bool) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	if is_open and stays_open:
		return
	_set_open(not plates.is_empty() and plates.all(func(p: PressurePlate) -> bool: return p.pressed))


func _set_open(value: bool) -> void:
	is_open = value
	_sprite.frame = FRAME_OPEN if value else FRAME_CLOSED
	_shape.set_deferred("disabled", value)
