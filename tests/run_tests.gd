extends SceneTree
## Headless test runner:
##   godot --headless --path . -s tests/run_tests.gd
## Exits with code 1 if any check fails.

const GameStateScript := preload("res://scripts/game_state.gd")

var _failures := 0
var _checks := 0


func _initialize() -> void:
	_test_armor_starts_empty()
	_test_pieces_in_fixed_order()
	_test_set_completed_emitted_once()
	_test_piece_icons()
	_test_area_tileset_collisions()
	_test_bag_starts_with_items()
	_test_bag_add_and_remove()
	_test_owned_pieces()
	print("%d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: ", message)


func _new_state() -> Node:
	var state: Node = GameStateScript.new()
	return state


func _test_armor_starts_empty() -> void:
	var state := _new_state()
	_check(state.armor_stage == 0, "hero starts without armor (stage 0)")
	_check(state.next_piece() == GameStateScript.Piece.BRACERS, "first piece is the bracers")
	_check(not state.is_set_complete(), "set is not complete at start")
	state.free()


func _test_pieces_in_fixed_order() -> void:
	var state := _new_state()
	var stages: Array[int] = []
	state.armor_changed.connect(func(stage: int) -> void: stages.append(stage))
	_check(not state.obtain(GameStateScript.Piece.BOOTS), "cannot take the boots before the bracers")
	_check(state.armor_stage == 0, "a rejected piece does not change the stage")
	for piece in GameStateScript.Piece.values():
		_check(state.obtain(piece), "piece %d is accepted in order" % piece)
	_check(stages == [1, 2, 3, 4, 5], "armor_changed reports every stage, got %s" % [stages])
	_check(not state.obtain(GameStateScript.Piece.TIARA), "no piece is accepted after the full set")
	_check(state.next_piece() == -1, "no next piece after the full set")
	state.free()


func _test_set_completed_emitted_once() -> void:
	var state := _new_state()
	var completed := [0]
	state.set_completed.connect(func() -> void: completed[0] += 1)
	for piece in GameStateScript.Piece.values():
		state.obtain(piece)
		if piece < GameStateScript.Piece.TIARA:
			_check(completed[0] == 0, "set_completed not emitted before the last piece")
	_check(completed[0] == 1, "set_completed emitted exactly once")
	_check(state.is_set_complete(), "set is complete after the 5 pieces")
	state.free()


func _test_piece_icons() -> void:
	var state := _new_state()
	for piece in GameStateScript.Piece.values():
		var icon: AtlasTexture = state.piece_icon(piece)
		_check(icon != null and icon.region == Rect2(piece * 32, 0, 32, 32), "icon region for piece %d" % piece)
		_check(not String(GameStateScript.PIECE_NAMES[piece]).is_empty(), "piece %d has a name" % piece)
	state.free()


func _test_area_tileset_collisions() -> void:
	var tile_set := AreaTileset.build(preload("res://assets/tiles/desert.png"))
	var source := tile_set.get_source(AreaTileset.SOURCE_ID) as TileSetAtlasSource
	for t in AreaTileset.Tile.values():
		var polygons := source.get_tile_data(AreaTileset.coords(t), 0).get_collision_polygons_count(0)
		var solid: bool = t in AreaTileset.SOLID
		_check(polygons == (1 if solid else 0), "tile %d solid=%s has %d collision polygons" % [t, solid, polygons])


func _test_bag_starts_with_items() -> void:
	var state := _new_state()
	_check(state.item_count("fig_bread") == 2, "bag starts with 2 fig breads")
	_check(state.bag_items() == ["fig_bread"], "bag lists the starting items, got %s" % [state.bag_items()])
	_check(not String(GameStateScript.ITEMS["fig_bread"]["name"]).is_empty(), "items have a name")
	state.free()


func _test_bag_add_and_remove() -> void:
	var state := _new_state()
	var changes := [0]
	state.inventory_changed.connect(func() -> void: changes[0] += 1)
	state.add_item("fig_bread", 3)
	_check(state.item_count("fig_bread") == 5, "add_item stacks counts")
	_check(state.remove_item("fig_bread", 4), "remove_item succeeds with enough items")
	_check(state.item_count("fig_bread") == 1, "remove_item subtracts")
	_check(not state.remove_item("fig_bread", 2), "cannot remove more than owned")
	_check(state.item_count("fig_bread") == 1, "failed remove keeps the count")
	_check(state.remove_item("fig_bread"), "remove the last one")
	_check(state.bag_items().is_empty(), "items at 0 leave the bag")
	_check(changes[0] == 3, "inventory_changed on each successful change, got %d" % changes[0])
	state.free()


func _test_owned_pieces() -> void:
	var state := _new_state()
	_check(state.owned_pieces().is_empty(), "no pieces owned at start")
	state.obtain(GameStateScript.Piece.BRACERS)
	state.obtain(GameStateScript.Piece.BOOTS)
	_check(state.owned_pieces() == [GameStateScript.Piece.BRACERS, GameStateScript.Piece.BOOTS], "owned pieces in order")
	state.free()
