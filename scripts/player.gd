class_name Player
extends CharacterBody2D
## Grid-based player: moves exactly one tile per step in 4 directions.
## Collision is checked BEFORE moving with test_move(), so the player never
## ends up between tiles. Pressing "action" interacts with whatever is in
## front (any body that has an `interact(by)` method).

const TILE := Grid.TILE

## One spritesheet per armor stage (index = GameState.armor_stage).
const SHEETS: Array[Texture2D] = [
	preload("res://assets/characters/hero_stage0.png"),
	preload("res://assets/characters/hero_stage1.png"),
	preload("res://assets/characters/hero_stage2.png"),
	preload("res://assets/characters/hero_stage3.png"),
	preload("res://assets/characters/hero_stage4.png"),
	preload("res://assets/characters/hero_stage5.png"),
]

## Seconds it takes to walk one tile.
@export var step_time := 0.2

var facing := Vector2i.DOWN
var _moving := false
## Alternates between the two walking frames on each step.
var _left_foot := true

@onready var _sprite: CharacterSprite = $Sprite
@onready var _camera: Camera2D = $Camera2D
@onready var _aura: Sprite2D = $Aura


func _ready() -> void:
	GameState.armor_changed.connect(_apply_armor)
	_apply_armor(GameState.armor_stage)
	# Full-set aura: a slow golden pulse (only visible with the complete set).
	var pulse := create_tween().set_loops()
	pulse.tween_property(_aura, "modulate:a", 0.35, 0.8)
	pulse.tween_property(_aura, "modulate:a", 1.0, 0.8)


func _physics_process(_delta: float) -> void:
	if _moving:
		return
	var dir := _read_direction()
	if dir == Vector2i.ZERO:
		return
	_face(dir)
	var motion := Vector2(dir * TILE)
	var hit := move_and_collide(motion, true)  # test only, does not move
	if hit:
		# Blocked: turn in place, and push the obstacle if it can be pushed.
		var obstacle := hit.get_collider()
		if obstacle.has_method("push"):
			obstacle.call("push", dir)
		return
	_moving = true
	# Walking frame for the first half of the step, standing frame after.
	_sprite.step_frame = 1 if _left_foot else 2
	_left_foot = not _left_foot
	var tween := create_tween()
	tween.tween_property(self, "position", position + motion, step_time)
	tween.parallel().tween_callback(func() -> void: _sprite.step_frame = 0).set_delay(step_time * 0.5)
	tween.finished.connect(func() -> void: _moving = false)


func _unhandled_input(event: InputEvent) -> void:
	if _moving or not event.is_action_pressed("action"):
		return
	var target := _find_interactable()
	if target:
		get_viewport().set_input_as_handled()
		target.call("interact", self)


func _apply_armor(stage: int) -> void:
	_sprite.texture = SHEETS[stage]
	_sprite.refresh()
	_aura.visible = stage >= GameState.FULL_SET


## Limits the camera so it never shows outside the map.
func set_camera_limits(rect: Rect2i) -> void:
	_camera.limit_left = rect.position.x
	_camera.limit_top = rect.position.y
	_camera.limit_right = rect.end.x
	_camera.limit_bottom = rect.end.y


func _read_direction() -> Vector2i:
	# Fixed priority instead of Input.get_vector() to avoid diagonals.
	if Input.is_action_pressed("move_up"):
		return Vector2i.UP
	if Input.is_action_pressed("move_down"):
		return Vector2i.DOWN
	if Input.is_action_pressed("move_left"):
		return Vector2i.LEFT
	if Input.is_action_pressed("move_right"):
		return Vector2i.RIGHT
	return Vector2i.ZERO


func _face(dir: Vector2i) -> void:
	facing = dir
	_sprite.facing = dir


func _find_interactable() -> Node:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_position + Vector2(facing * TILE)
	query.exclude = [get_rid()]
	for hit in get_world_2d().direct_space_state.intersect_point(query):
		var collider: Object = hit["collider"]
		if collider.has_method("interact"):
			return collider as Node
	return null
