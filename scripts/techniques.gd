class_name Techniques
extends RefCounted
## Hero techniques: they spend cosmos and are learned by level.
## Named after the constellation relics of the armor.

const ALL := {
	"hercules_fist": {
		"name": "Puño de Hércules",
		"cost": 4,
		"power": 1.8,
		"all": false,
		"level": 1,
		"description": "Un golpe con la fuerza del héroe de los doce trabajos.",
	},
	"orion_bow": {
		"name": "Arco de Orión",
		"cost": 7,
		"power": 1.2,
		"all": true,
		"level": 3,
		"description": "Flechas de estrellas que alcanzan a todos los enemigos.",
	},
	"aquila_wind": {
		"name": "Viento de Áquila",
		"cost": 10,
		"power": 2.6,
		"all": false,
		"level": 5,
		"description": "El águila de Zeus cae en picada sobre un enemigo.",
	},
}


## Technique ids known at a level, in learning order.
static func known_at(level: int) -> Array[String]:
	var ids: Array[String] = []
	for id: String in ALL:
		if ALL[id]["level"] <= level:
			ids.append(id)
	return ids


## Techniques learned exactly at this level.
static func learned_at(level: int) -> Array[String]:
	var ids: Array[String] = []
	for id: String in ALL:
		if ALL[id]["level"] == level:
			ids.append(id)
	return ids
