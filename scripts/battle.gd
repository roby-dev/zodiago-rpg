class_name Battle
extends RefCounted
## Turn-based battle rules, independent from the UI (so they can be tested).
## Each round, every living fighter acts once, fastest first; the hero uses
## the action chosen by the player. play_round() returns the messages to show.

enum Outcome { ONGOING, VICTORY, DEFEAT, FLED }

const MIN_FLEE := 0.2

var hero: Combatant
var enemies: Array[Combatant]
var outcome := Outcome.ONGOING
## Cosmos the hero recovers at the end of each round (full armor set bonus).
var hero_cosmos_regen := 0

var _rng: RandomNumberGenerator


func _init(hero_fighter: Combatant, enemy_fighters: Array[Combatant], rng := RandomNumberGenerator.new()) -> void:
	hero = hero_fighter
	enemies = enemy_fighters
	_rng = rng


static func damage(attacker: Combatant, defender: Combatant, power: float, rng: RandomNumberGenerator) -> int:
	var raw := attacker.attack * power - defender.defense * 0.5
	return maxi(1, roundi(raw * rng.randf_range(0.85, 1.0)))


func living_enemies() -> Array[Combatant]:
	var alive: Array[Combatant] = []
	alive.assign(enemies.filter(func(e: Combatant) -> bool: return e.is_alive()))
	return alive


## 20%..100%: being faster than the fastest enemy makes escaping easier.
func flee_chance() -> float:
	var fastest := 0
	for enemy in living_enemies():
		fastest = maxi(fastest, enemy.speed)
	return clampf(0.5 + 0.1 * (hero.speed - fastest), MIN_FLEE, 1.0)


func exp_reward() -> int:
	var total := 0
	for enemy in enemies:
		total += enemy.exp_reward
	return total


## action: {"type": "attack", "target": i}
##         {"type": "technique", "id": String, "target": i}
##         {"type": "card", "name": String, "effect": {"cosmos": n, "hp": n}}
##         {"type": "flee"}
func play_round(action: Dictionary) -> Array[String]:
	var log: Array[String] = []
	var order: Array[Combatant] = [hero]
	order.append_array(living_enemies())
	# Stable sort: on equal speed the hero (first in the list) acts first.
	order.sort_custom(func(a: Combatant, b: Combatant) -> bool: return a.speed > b.speed)
	for fighter in order:
		if outcome != Outcome.ONGOING or not fighter.is_alive():
			continue
		if fighter == hero:
			_hero_turn(action, log)
		else:
			_enemy_turn(fighter, log)
		_update_outcome()
	if outcome == Outcome.ONGOING and hero_cosmos_regen > 0:
		var regen := hero.restore_cosmos(hero_cosmos_regen)
		if regen > 0:
			log.append("Tu armadura completa vibra: +%d de cosmos." % regen)
	return log


func _hero_turn(action: Dictionary, log: Array[String]) -> void:
	match action["type"]:
		"attack":
			_strike(hero, _target(action), 1.0, "%s ataca." % hero.display_name, log)
		"technique":
			var tech: Dictionary = Techniques.ALL[action["id"]]
			if hero.cosmos < tech["cost"]:
				log.append("No tienes suficiente cosmos para %s." % tech["name"])
				return
			hero.cosmos -= tech["cost"]
			log.append("¡%s usa %s!" % [hero.display_name, tech["name"]])
			var targets: Array[Combatant] = living_enemies()
			if not tech["all"]:
				targets = [_target(action)]
			for target in targets:
				_strike(hero, target, tech["power"], "", log)
		"card":
			log.append("%s usa %s." % [hero.display_name, action["name"]])
			var effect: Dictionary = action["effect"]
			if effect.has("cosmos"):
				log.append("Recupera %d de cosmos." % hero.restore_cosmos(effect["cosmos"]))
			if effect.has("hp"):
				log.append("Recupera %d PS." % hero.heal(effect["hp"]))
		"flee":
			if _rng.randf() < flee_chance():
				log.append("¡Escapaste!")
				outcome = Outcome.FLED
			else:
				log.append("¡No pudiste escapar!")


func _enemy_turn(enemy: Combatant, log: Array[String]) -> void:
	if not enemy.special.is_empty() and _rng.randf() < 0.3:
		var intro := "¡%s usa %s!" % [enemy.display_name, enemy.special["name"]]
		_strike(enemy, hero, enemy.special["power"], intro, log)
	else:
		_strike(enemy, hero, 1.0, "%s ataca." % enemy.display_name, log)


## The target of a single-target action (falls back to the first living enemy).
func _target(action: Dictionary) -> Combatant:
	var index: int = action.get("target", 0)
	if index >= 0 and index < enemies.size() and enemies[index].is_alive():
		return enemies[index]
	return living_enemies()[0]


func _strike(attacker: Combatant, defender: Combatant, power: float, intro: String, log: Array[String]) -> void:
	if not intro.is_empty():
		log.append(intro)
	var dealt := defender.take_damage(damage(attacker, defender, power, _rng))
	log.append("%s recibe %d de daño." % [defender.display_name, dealt])
	if not defender.is_alive():
		log.append("%s fue derrotado." % defender.display_name)


func _update_outcome() -> void:
	if outcome != Outcome.ONGOING:
		return
	if not hero.is_alive():
		outcome = Outcome.DEFEAT
	elif living_enemies().is_empty():
		outcome = Outcome.VICTORY
