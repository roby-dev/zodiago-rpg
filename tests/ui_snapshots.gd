extends SceneTree
## Renders UI states to PNG files for visual review (needs a window, NOT --headless):
##   godot --path . -s tests/ui_snapshots.gd
## Output: user://snapshots/*.png

const OUT_DIR := "user://snapshots"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var world: Node = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	world.get_node("Player").position = Vector2(272, 272)
	await _frames(10)

	var dialogue: Node = world.get_node("DialogueBox")
	# Real altar flow: takes the first piece and opens the dialogue.
	world.get_node("AltarBracers").call("interact", world.get_node("Player"))
	await _frames(240)  # let the typewriter finish
	await _save("dialogue_altar")
	dialogue.call("_advance")
	await _frames(240)
	await _save("dialogue_lore")
	dialogue.call("_close")

	var menu: Node = world.get_node("GameMenu")
	menu.call("open")
	await _frames(5)
	await _save("menu_equipment")
	menu.call("_move", 1)
	menu.call("_accept")
	await _frames(5)
	await _save("menu_bag")
	menu.call("_back")  # leave the bag list
	menu.call("_move", 1)
	await _frames(5)
	await _save("menu_status")
	menu.call("close")

	var battle: Node = world.get_node("BattleScreen")
	var enemies: Array[Combatant] = [EnemyCatalog.create("sand_scorpion"), EnemyCatalog.create("harpy")]
	battle.call("start", enemies)
	await _frames(40)
	await _save("battle_intro")
	battle.call("_accept")  # second intro line
	battle.call("_accept")  # -> commands
	await _frames(5)
	await _save("battle_commands")
	battle.call("_move", 1)
	battle.call("_accept")  # Técnica
	await _frames(5)
	await _save("battle_techniques")
	battle.call("_back")
	battle.call("_accept")  # Atacar -> choose target
	await _frames(5)
	await _save("battle_target")
	battle.call("_accept")  # attack the scorpion
	await _frames(5)
	await _save("battle_round")
	quit()


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [OUT_DIR, file_name]
	root.get_texture().get_image().save_png(path)
	print("saved ", ProjectSettings.globalize_path(path))
	# The read-back can land a frame late: settle before the caller changes the UI.
	await _frames(3)
