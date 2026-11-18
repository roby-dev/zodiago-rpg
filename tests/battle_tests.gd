extends RefCounted
## Battle, hero progression and encounter tests. Called from tests/run_tests.gd.

const GameStateScript := preload("res://scripts/game_state.gd")

var _check: Callable


func run(check: Callable) -> void:
	_check = check
	_test_combatant_damage_clamps()
	_test_damage_formula()
	_test_attack_until_victory()
	_test_technique_spends_cosmos()
	_test_technique_without_cosmos()
	_test_technique_hits_all()
	_test_defeat()
	_test_flee()
	_test_cosmos_regen_and_cards()
	_test_hero_starts_level_one()
	_test_level_up_and_techniques()
	_test_armor_bonus_and_set_regen()
	_test_hero_hp_persists()
	_test_encounter_counter()
	_test_enemy_catalog()


func _hero(stats := {}) -> Combatant:
	var base := {"max_hp": 30, "max_cosmos": 12, "attack": 8, "defense": 4, "speed": 6}
	base.merge(stats, true)
	return Combatant.new("Aspirante", base)


func _enemy(stats := {}) -> Combatant:
	var base := {"max_hp": 10, "max_cosmos": 0, "attack": 5, "defense": 2, "speed": 3, "exp": 5}
	base.merge(stats, true)
	return Combatant.new("Escorpión", base)


func _rng(seed_value := 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _test_combatant_damage_clamps() -> void:
	var c := _enemy()
	_check.call(c.take_damage(4) == 4 and c.hp == 6, "take_damage subtracts HP")
	_check.call(c.take_damage(50) == 6 and c.hp == 0, "damage never takes HP below 0")
	_check.call(not c.is_alive(), "a combatant at 0 HP is defeated")


func _test_damage_formula() -> void:
	var weak := Battle.damage(_hero(), _enemy({"defense": 999}), 1.0, _rng())
	_check.call(weak == 1, "damage is at least 1, got %d" % weak)
	var normal := Battle.damage(_hero(), _enemy(), 1.0, _rng(7))
	var strong := Battle.damage(_hero(), _enemy(), 2.0, _rng(7))
	_check.call(strong > normal, "a stronger technique deals more damage (%d > %d)" % [strong, normal])


func _test_attack_until_victory() -> void:
	var enemy := _enemy({"max_hp": 4})
	var battle := Battle.new(_hero(), [enemy], _rng())
	var log := battle.play_round({"type": "attack", "target": 0})
	_check.call(not enemy.is_alive(), "a strong attack defeats a weak enemy")
	_check.call(battle.outcome == Battle.Outcome.VICTORY, "victory when every enemy is defeated")
	_check.call(battle.exp_reward() == 5, "victory gives the enemies' experience")
	_check.call(log.size() >= 2, "the round reports the attack and the defeat: %s" % [log])


func _test_technique_spends_cosmos() -> void:
	var hero := _hero()
	var enemy := _enemy({"max_hp": 200})
	var battle := Battle.new(hero, [enemy], _rng())
	battle.play_round({"type": "technique", "id": "hercules_fist", "target": 0})
	var cost: int = Techniques.ALL["hercules_fist"]["cost"]
	_check.call(hero.cosmos == 12 - cost, "a technique spends its cosmos cost")
	_check.call(enemy.hp < 200, "a technique damages the target")


func _test_technique_without_cosmos() -> void:
	var hero := _hero({"max_cosmos": 1})
	var enemy := _enemy({"max_hp": 200, "attack": 0})
	var battle := Battle.new(hero, [enemy], _rng())
	var log := battle.play_round({"type": "technique", "id": "hercules_fist", "target": 0})
	_check.call(enemy.hp == 200 and hero.cosmos == 1, "without enough cosmos the technique fails and costs nothing")
	_check.call(log.any(func(line: String) -> bool: return "cosmos" in line), "the log explains the missing cosmos")


func _test_technique_hits_all() -> void:
	var enemies: Array[Combatant] = [_enemy({"max_hp": 200}), _enemy({"max_hp": 200})]
	var battle := Battle.new(_hero({"max_cosmos": 30}), enemies, _rng())
	battle.play_round({"type": "technique", "id": "orion_bow", "target": 0})
	_check.call(enemies.all(func(e: Combatant) -> bool: return e.hp < 200), "an all-target technique hits every enemy")


func _test_defeat() -> void:
	var hero := _hero({"max_hp": 1, "speed": 1})
	var battle := Battle.new(hero, [_enemy({"max_hp": 200, "attack": 50, "speed": 9})], _rng())
	battle.play_round({"type": "attack", "target": 0})
	_check.call(battle.outcome == Battle.Outcome.DEFEAT, "defeat when the hero falls")


func _test_flee() -> void:
	var fast := Battle.new(_hero({"speed": 20}), [_enemy()], _rng())
	_check.call(is_equal_approx(fast.flee_chance(), 1.0), "a much faster hero always flees")
	fast.play_round({"type": "flee"})
	_check.call(fast.outcome == Battle.Outcome.FLED, "fleeing ends the battle")
	var slow := Battle.new(_hero({"speed": 1}), [_enemy({"speed": 30})], _rng())
	_check.call(is_equal_approx(slow.flee_chance(), 0.2), "flee chance never drops below 20%")


func _test_cosmos_regen_and_cards() -> void:
	var hero := _hero()
	hero.cosmos = 2
	var battle := Battle.new(hero, [_enemy({"max_hp": 200, "attack": 0})], _rng())
	battle.hero_cosmos_regen = 3
	battle.play_round({"type": "card", "name": "Ambrosía menor", "effect": {"cosmos": 5}})
	_check.call(hero.cosmos == 10, "card restores cosmos and the round regenerates it, got %d" % hero.cosmos)
	battle.play_round({"type": "card", "name": "Ambrosía menor", "effect": {"cosmos": 50}})
	_check.call(hero.cosmos == hero.max_cosmos, "cosmos never exceeds its maximum")


func _test_hero_starts_level_one() -> void:
	var state: Node = GameStateScript.new()
	_check.call(state.level == 1 and state.experience == 0, "hero starts at level 1")
	var hero: Combatant = state.hero_combatant()
	_check.call(hero.max_hp == GameStateScript.HERO_BASE["max_hp"], "level 1 uses the base stats")
	_check.call(state.known_techniques() == ["hercules_fist"], "hero starts with Puño de Hércules")
	state.free()


func _test_level_up_and_techniques() -> void:
	var state: Node = GameStateScript.new()
	var messages: Array[String] = state.gain_exp(state.exp_to_next())
	_check.call(state.level == 2, "enough experience raises the level")
	_check.call(messages.any(func(m: String) -> bool: return "nivel 2" in m), "level-up is announced: %s" % [messages])
	_check.call(state.hero_combatant().max_hp > GameStateScript.HERO_BASE["max_hp"], "level-up raises stats")
	messages = state.gain_exp(state.exp_to_next())
	_check.call(state.level == 3 and "orion_bow" in state.known_techniques(), "level 3 teaches Arco de Orión")
	_check.call(messages.any(func(m: String) -> bool: return "Arco de Orión" in m), "the new technique is announced")
	state.free()


func _test_armor_bonus_and_set_regen() -> void:
	var state: Node = GameStateScript.new()
	var before: Combatant = state.hero_combatant()
	state.obtain(GameStateScript.Piece.BRACERS)
	var after: Combatant = state.hero_combatant()
	_check.call(after.defense == before.defense + 2, "each armor piece adds 2 defense")
	_check.call(after.max_cosmos == before.max_cosmos + 2, "each armor piece adds 2 max cosmos")
	_check.call(state.cosmos_regen() == 0, "no cosmos regeneration without the full set")
	for piece in range(1, GameStateScript.FULL_SET):
		state.obtain(piece)
	_check.call(state.cosmos_regen() == 2, "the full set regenerates cosmos each round")
	state.free()


func _test_hero_hp_persists() -> void:
	var state: Node = GameStateScript.new()
	var hero: Combatant = state.hero_combatant()
	hero.take_damage(5)
	hero.cosmos -= 3
	state.store_hero(hero)
	var again: Combatant = state.hero_combatant()
	_check.call(again.hp == again.max_hp - 5 and again.cosmos == again.max_cosmos - 3, "HP and cosmos persist between battles")
	state.restore_hero()
	again = state.hero_combatant()
	_check.call(again.hp == again.max_hp and again.cosmos == again.max_cosmos, "restore_hero heals fully")
	state.free()


func _test_encounter_counter() -> void:
	var counter := EncounterCounter.new(10, 22, _rng(3))
	var safe_triggered := false
	for i in 100:
		safe_triggered = safe_triggered or counter.step(true)
	_check.call(not safe_triggered, "steps on safe tiles never start a battle")
	for round_index in 5:
		var steps := 0
		var triggered := false
		while not triggered and steps < 100:
			steps += 1
			triggered = counter.step(false)
		_check.call(steps >= 10 and steps <= 22, "a battle starts after 10-22 wild steps, got %d" % steps)


func _test_enemy_catalog() -> void:
	var scorpion := EnemyCatalog.create("sand_scorpion")
	_check.call(scorpion.display_name == "Escorpión de arena" and scorpion.hp == scorpion.max_hp, "catalog builds enemies")
	var rng := _rng(5)
	for i in 20:
		var group := EnemyCatalog.random_group(EnemyCatalog.DESERT, rng)
		_check.call(group.size() >= 1 and group.size() <= 2, "groups have 1-2 enemies")
		if group.size() == 2 and group[0].enemy_id == group[1].enemy_id:
			_check.call(group[0].display_name.ends_with(" A") and group[1].display_name.ends_with(" B"), "duplicate enemies get A/B suffixes")
