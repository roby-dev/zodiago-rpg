class_name PressurePlate
extends Area2D
## Floor plate pressed by a boulder resting on it (the player is too light).

signal toggled(pressed: bool)

const FRAME_UP := 1
const FRAME_DOWN := 2

var pressed := false

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body.bind(true))
	body_exited.connect(_on_body.bind(false))


func _on_body(body: Node2D, entering: bool) -> void:
	if body.is_in_group("boulder"):
		_set_pressed(entering)


func _set_pressed(value: bool) -> void:
	if value == pressed:
		return
	pressed = value
	_sprite.frame = FRAME_DOWN if pressed else FRAME_UP
	toggled.emit(pressed)
