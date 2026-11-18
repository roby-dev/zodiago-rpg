class_name EncounterCounter
extends RefCounted
## Decides when a random battle starts. Each wild step counts down; when the
## counter reaches 0 a battle starts and a new random count is drawn.
## Safe steps (roads) never count, so the player can choose to avoid fights.

var min_steps: int
var max_steps: int

var _rng: RandomNumberGenerator
var _remaining: int


func _init(min_count: int, max_count: int, rng := RandomNumberGenerator.new()) -> void:
	min_steps = min_count
	max_steps = max_count
	_rng = rng
	_reset()


## Returns true when this step starts a battle.
func step(is_safe: bool) -> bool:
	if is_safe:
		return false
	_remaining -= 1
	if _remaining > 0:
		return false
	_reset()
	return true


func _reset() -> void:
	_remaining = _rng.randi_range(min_steps, max_steps)
