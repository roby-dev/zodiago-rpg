class_name BattleScreen
extends CanvasLayer
## Battle UI on top of the world. The rules live in Battle; this node only
## shows state, collects the player's choice and reports the outcome.
## While open it pauses the scene tree (process_mode is ALWAYS).
##
## Flow: messages -> commands -> (technique / bag / target list) -> round
## messages -> commands ... until the battle ends, then `finished` is emitted.

signal finished(outcome: Battle.Outcome)

enum Mode { HIDDEN, MESSAGES, COMMANDS, TECHNIQUES, BAG, TARGET }

const COMMANDS: Array[String] = ["Atacar", "Técnica", "Bolsa", "Huir"]
const FRAME: StyleBox = preload("res://assets/ui/greek_frame.tres")
const STAR: Texture2D = preload("res://assets/ui/star.png")
const GOLD := Color(0.95, 0.8, 0.35)
const TEXT := Color(0.92, 0.94, 1)
const DIM := Color(0.55, 0.58, 0.7)
const HP_COLOR := Color(0.85, 0.3, 0.3)
const COSMOS_COLOR := Color(0.35, 0.6, 1.0)
const SAND := Color(0.85, 0.68, 0.45)

var _battle: Battle
var _mode := Mode.HIDDEN
var _cursor := 0
## Action waiting for a target (attack or single-target technique).
var _pending: Dictionary = {}
var _messages: Array[String] = []
var _after_messages: Callable
var _enemy_views: Array[Dictionary] = []

var _root: Control
var _enemy_row: HBoxContainer
var _message: Label
var _options: VBoxContainer
var _hero_name: Label
var _hp_label: Label
var _hp_bar: ProgressBar
var _cosmos_label: Label
var _cosmos_bar: ProgressBar
var _flash: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 12
	_build()
	hide()


func is_active() -> bool:
	return _mode != Mode.HIDDEN


func start(enemies: Array[Combatant]) -> void:
	_battle = Battle.new(GameState.hero_combatant(), enemies)
	_battle.hero_cosmos_regen = GameState.cosmos_regen()
	_build_enemy_views()
	_refresh_status()
	show()
	get_tree().paused = true
	_flash.modulate.a = 1.0
	create_tween().tween_property(_flash, "modulate:a", 0.0, 0.5)
	var intro: Array[String] = []
	for enemy in enemies:
		intro.append("¡Aparece %s!" % enemy.display_name)
	_say(intro, _show_commands)


# --- Input -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _mode == Mode.HIDDEN:
		return
	var step := 0
	if event.is_action_pressed("move_up") or event.is_action_pressed("move_left"):
		step = -1
	elif event.is_action_pressed("move_down") or event.is_action_pressed("move_right"):
		step = 1
	if step != 0:
		_move(step)
	elif event.is_action_pressed("action"):
		_accept()
	elif event.is_action_pressed("cancel"):
		_back()
	else:
		return
	get_viewport().set_input_as_handled()


func _move(step: int) -> void:
	var count := _option_count()
	if count == 0:
		return
	_cursor = wrapi(_cursor + step, 0, count)
	_refresh_options()


func _accept() -> void:
	match _mode:
		Mode.MESSAGES:
			_next_message()
		Mode.COMMANDS:
			_choose_command()
		Mode.TECHNIQUES:
			var id: String = GameState.known_techniques()[_cursor]
			var tech: Dictionary = Techniques.ALL[id]
			if _battle.hero.cosmos < tech["cost"]:
				return  # Greyed out: not enough cosmos.
			if tech["all"]:
				_play({"type": "technique", "id": id})
			else:
				_ask_target({"type": "technique", "id": id})
		Mode.BAG:
			var ids := _usable_items()
			if ids.is_empty():
				return
			var id: String = ids[_cursor]
			GameState.remove_item(id)
			_play({"type": "card", "name": GameState.ITEMS[id]["name"], "effect": GameState.ITEMS[id]["effect"]})
		Mode.TARGET:
			_pending["target"] = _battle.enemies.find(_battle.living_enemies()[_cursor])
			_play(_pending)


func _back() -> void:
	match _mode:
		Mode.TECHNIQUES, Mode.BAG, Mode.TARGET:
			_show_commands()
		Mode.MESSAGES:
			_next_message()


func _choose_command() -> void:
	match _cursor:
		0:
			_ask_target({"type": "attack"})
		1:
			_set_mode(Mode.TECHNIQUES)
		2:
			_set_mode(Mode.BAG)
		3:
			_play({"type": "flee"})


func _ask_target(action: Dictionary) -> void:
	_pending = action
	if _battle.living_enemies().size() == 1:
		_pending["target"] = _battle.enemies.find(_battle.living_enemies()[0])
		_play(_pending)
	else:
		_set_mode(Mode.TARGET)


# --- Battle flow ---------------------------------------------------------------

func _play(action: Dictionary) -> void:
	var log := _battle.play_round(action)
	_refresh_status()
	_refresh_enemies()
	_say(log, _after_round)


func _after_round() -> void:
	match _battle.outcome:
		Battle.Outcome.ONGOING:
			_show_commands()
		Battle.Outcome.VICTORY:
			var gained := _battle.exp_reward()
			var lines: Array[String] = ["¡Victoria! Ganaste %d de experiencia." % gained]
			lines.append_array(GameState.gain_exp(gained))
			_say(lines, _finish)
		Battle.Outcome.DEFEAT:
			_say(["Tu cosmos se apaga... Todo se vuelve oscuro."], _finish)
		Battle.Outcome.FLED:
			_finish()


func _finish() -> void:
	GameState.store_hero(_battle.hero)
	_mode = Mode.HIDDEN
	hide()
	get_tree().paused = false
	finished.emit(_battle.outcome)


func _say(lines: Array[String], then: Callable) -> void:
	_messages = lines.duplicate()
	_after_messages = then
	_set_mode(Mode.MESSAGES)
	_next_message()


func _next_message() -> void:
	if _messages.is_empty():
		_after_messages.call()
		return
	_message.text = _messages.pop_front()


func _show_commands() -> void:
	_message.text = "¿Qué hará %s?" % GameState.HERO_NAME
	_set_mode(Mode.COMMANDS)


func _set_mode(mode: Mode) -> void:
	_mode = mode
	_cursor = 0
	_refresh_options()


func _usable_items() -> Array[String]:
	var ids: Array[String] = []
	for id in GameState.bag_items():
		if GameState.ITEMS[id].has("effect"):
			ids.append(id)
	return ids


func _option_count() -> int:
	match _mode:
		Mode.COMMANDS:
			return COMMANDS.size()
		Mode.TECHNIQUES:
			return GameState.known_techniques().size()
		Mode.BAG:
			return _usable_items().size()
		Mode.TARGET:
			return _battle.living_enemies().size()
	return 0


# --- Views ---------------------------------------------------------------------

func _refresh_options() -> void:
	for child in _options.get_children():
		_options.remove_child(child)
		child.queue_free()
	var entries: Array[Array] = []  # [text, enabled]
	match _mode:
		Mode.COMMANDS:
			for command in COMMANDS:
				entries.append([command, true])
		Mode.TECHNIQUES:
			for id in GameState.known_techniques():
				var tech: Dictionary = Techniques.ALL[id]
				entries.append(["%s  %d" % [tech["name"], tech["cost"]], _battle.hero.cosmos >= tech["cost"]])
			if _cursor < entries.size():
				_message.text = Techniques.ALL[GameState.known_techniques()[_cursor]]["description"]
		Mode.BAG:
			for id in _usable_items():
				entries.append(["%s  x%d" % [GameState.ITEMS[id]["name"], GameState.item_count(id)], true])
			_message.text = "La bolsa está vacía." if entries.is_empty() else String(GameState.ITEMS[_usable_items()[_cursor]]["description"])
		Mode.TARGET:
			_message.text = "¿A quién?"
	for i in entries.size():
		var selected := i == _cursor
		var color := (GOLD if selected else TEXT) if entries[i][1] else DIM
		_options.add_child(_row([_star(selected), _label(entries[i][0], 24, color)]))
	_refresh_enemies()


func _refresh_status() -> void:
	var hero := _battle.hero
	_hero_name.text = "%s  Nv %d" % [hero.display_name, GameState.level]
	_hp_label.text = "PS  %d/%d" % [hero.hp, hero.max_hp]
	_hp_bar.max_value = hero.max_hp
	_hp_bar.value = hero.hp
	_cosmos_label.text = "Cosmos  %d/%d" % [hero.cosmos, hero.max_cosmos]
	_cosmos_bar.max_value = maxi(1, hero.max_cosmos)
	_cosmos_bar.value = hero.cosmos


func _refresh_enemies() -> void:
	var targeted: Combatant = null
	if _mode == Mode.TARGET and _cursor < _battle.living_enemies().size():
		targeted = _battle.living_enemies()[_cursor]
	for view in _enemy_views:
		var enemy: Combatant = view["enemy"]
		view["box"].modulate.a = 1.0 if enemy.is_alive() else 0.0
		view["bar"].value = enemy.hp
		view["marker"].modulate.a = 1.0 if enemy == targeted else 0.0


func _build_enemy_views() -> void:
	for child in _enemy_row.get_children():
		_enemy_row.remove_child(child)
		child.queue_free()
	_enemy_views.clear()
	for enemy in _battle.enemies:
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_END
		var marker := _star(false)
		marker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var sprite := TextureRect.new()
		sprite.texture = load("res://assets/enemies/%s.png" % enemy.enemy_id)
		sprite.custom_minimum_size = Vector2(144, 144)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var name_label := _label(enemy.display_name, 22, TEXT)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var bar := _bar(HP_COLOR, Vector2(150, 10))
		bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		bar.max_value = enemy.max_hp
		for node: Control in [marker, sprite, name_label, bar]:
			box.add_child(node)
		_enemy_row.add_child(box)
		_enemy_views.append({"enemy": enemy, "box": box, "bar": bar, "marker": marker})
	_refresh_enemies()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var backdrop := ColorRect.new()  # Hides the world behind the battle.
	backdrop.color = Color(0.02, 0.03, 0.09)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(backdrop)
	var sky := StarField.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(sky)
	var ground := ColorRect.new()
	ground.color = SAND
	ground.anchor_right = 1.0
	ground.offset_top = 330
	ground.offset_bottom = 470
	_root.add_child(ground)

	_enemy_row = HBoxContainer.new()
	_enemy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_enemy_row.add_theme_constant_override("separation", 96)
	_enemy_row.anchor_right = 1.0
	_enemy_row.offset_top = 120
	_enemy_row.offset_bottom = 420
	_root.add_child(_enemy_row)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	bottom.anchor_top = 1.0
	bottom.anchor_right = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_left = 16
	bottom.offset_top = -244
	bottom.offset_right = -16
	bottom.offset_bottom = -16
	_root.add_child(bottom)

	var status := _panel(Vector2(300, 0))
	var status_box := VBoxContainer.new()
	status_box.add_theme_constant_override("separation", 6)
	status.add_child(status_box)
	_hero_name = _label("", 24, GOLD)
	_hp_label = _label("", 20, TEXT)
	_hp_bar = _bar(HP_COLOR, Vector2(0, 10))
	_cosmos_label = _label("", 20, TEXT)
	_cosmos_bar = _bar(COSMOS_COLOR, Vector2(0, 10))
	for node: Control in [_hero_name, _hp_label, _hp_bar, _cosmos_label, _cosmos_bar]:
		status_box.add_child(node)
	bottom.add_child(status)

	var message_panel := _panel(Vector2.ZERO)
	message_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message = _label("", 24, TEXT)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_panel.add_child(_message)
	bottom.add_child(message_panel)

	var options_panel := _panel(Vector2(330, 0))
	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 4)
	options_panel.add_child(_options)
	bottom.add_child(options_panel)

	_flash = ColorRect.new()
	_flash.color = Color.WHITE
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.modulate.a = 0.0
	_root.add_child(_flash)


func _panel(min_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.add_theme_stylebox_override("panel", FRAME)
	return panel


func _bar(color: Color, min_size: Vector2) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = min_size
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.03, 0.04, 0.1)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", background)
	return bar


func _star(shown: bool) -> TextureRect:
	var star := TextureRect.new()
	star.texture = STAR
	star.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	star.modulate.a = 1.0 if shown else 0.0
	return star


func _row(children: Array[Control]) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for child in children:
		child.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(child)
	return row


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
