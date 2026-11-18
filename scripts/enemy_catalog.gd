class_name EnemyCatalog
extends RefCounted
## Original enemies of the desert of Astelia (creatures of Greek myth).

const DESERT: Array[String] = ["sand_scorpion", "wild_satyr", "harpy"]

const ALL := {
	"sand_scorpion": {
		"name": "Escorpión de arena",
		"max_hp": 14, "attack": 7, "defense": 4, "speed": 4, "exp": 6,
		"special": {"name": "Aguijón", "power": 1.4},
	},
	"wild_satyr": {
		"name": "Sátiro salvaje",
		"max_hp": 18, "attack": 8, "defense": 2, "speed": 6, "exp": 8,
		"special": {"name": "Embestida", "power": 1.5},
	},
	"harpy": {
		"name": "Harpía",
		"max_hp": 11, "attack": 6, "defense": 2, "speed": 9, "exp": 7,
	},
}


static func create(id: String) -> Combatant:
	var data: Dictionary = ALL[id]
	var enemy := Combatant.new(data["name"], data)
	enemy.enemy_id = id
	return enemy


## 1-2 random enemies from the pool; duplicates get " A" / " B" suffixes.
static func random_group(pool: Array[String], rng: RandomNumberGenerator) -> Array[Combatant]:
	var group: Array[Combatant] = []
	for i in rng.randi_range(1, 2):
		group.append(create(pool[rng.randi_range(0, pool.size() - 1)]))
	if group.size() == 2 and group[0].enemy_id == group[1].enemy_id:
		group[0].display_name += " A"
		group[1].display_name += " B"
	return group
