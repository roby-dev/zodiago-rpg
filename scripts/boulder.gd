class_name Boulder
extends CharacterBody2D
## Heavy stone that moves one tile when the player walks into it.
## Collision is checked BEFORE moving, like the player, so it never
## ends up between tiles or inside a wall.

const TILE := Grid.TILE

@export var step_time := 0.25

var _moving := false


## Called by the player. Returns true if the boulder moved.
func push(dir: Vector2i) -> bool:
	if _moving:
		return false
	var motion := Vector2(dir * TILE)
	if move_and_collide(motion, true):  # test only
		return false
	_moving = true
	var tween := create_tween()
	tween.tween_property(self, "position", position + motion, step_time)
	tween.finished.connect(func() -> void: _moving = false)
	return true
