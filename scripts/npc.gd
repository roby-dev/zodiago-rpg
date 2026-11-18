class_name Npc
extends StaticBody2D
## A character the player can talk to. It does NOT know about the dialogue
## box: it only emits `talk_requested`, and the world connects that signal.

signal talk_requested(speaker: String, lines: PackedStringArray)

@export var display_name := "Aldeano"
@export_multiline var lines: PackedStringArray = []
## 3x4 spritesheet of 32x48 frames (see CharacterSprite).
@export var sheet: Texture2D
## If true, talking to this NPC fully restores the hero's HP and cosmos.
@export var heals_hero := false

const HEAL_LINE := "(Tus heridas sanaron y tu cosmos se renovó.)"

@onready var _sprite: CharacterSprite = $Sprite


func _ready() -> void:
	if sheet:
		_sprite.texture = sheet
		_sprite.refresh()


## Called by the player when pressing "action" while facing this NPC.
func interact(by: Node2D) -> void:
	_sprite.facing = _direction_to(by.global_position)
	var said := lines.duplicate()
	if heals_hero:
		GameState.restore_hero()
		said.append(HEAL_LINE)
	talk_requested.emit(display_name, said)


func _direction_to(target: Vector2) -> Vector2i:
	var d := target - global_position
	if absf(d.x) > absf(d.y):
		return Vector2i.RIGHT if d.x > 0 else Vector2i.LEFT
	return Vector2i.DOWN if d.y > 0 else Vector2i.UP
