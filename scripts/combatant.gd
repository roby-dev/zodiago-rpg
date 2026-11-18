class_name Combatant
extends RefCounted
## One fighter in a battle (the hero or an enemy): stats plus current HP/cosmos.

var display_name: String
## Catalog id for enemies ("" for the hero).
var enemy_id := ""
var max_hp: int
var hp: int
var max_cosmos: int
var cosmos: int
var attack: int
var defense: int
var speed: int
## Experience given to the hero when this enemy is defeated.
var exp_reward: int
## Optional enemy special move: {"name": String, "power": float}.
var special: Dictionary = {}


func _init(name: String, stats: Dictionary) -> void:
	display_name = name
	max_hp = stats["max_hp"]
	hp = stats.get("hp", max_hp)
	max_cosmos = stats.get("max_cosmos", 0)
	cosmos = stats.get("cosmos", max_cosmos)
	attack = stats["attack"]
	defense = stats["defense"]
	speed = stats["speed"]
	exp_reward = stats.get("exp", 0)
	special = stats.get("special", {})


func is_alive() -> bool:
	return hp > 0


## Returns the damage actually taken (HP never goes below 0).
func take_damage(amount: int) -> int:
	var taken := mini(amount, hp)
	hp -= taken
	return taken


## Returns the cosmos actually restored (never above max_cosmos).
func restore_cosmos(amount: int) -> int:
	var restored := mini(amount, max_cosmos - cosmos)
	cosmos += restored
	return restored


## Returns the HP actually restored (never above max_hp).
func heal(amount: int) -> int:
	var healed := mini(amount, max_hp - hp)
	hp += healed
	return healed
