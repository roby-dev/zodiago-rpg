class_name GameMenu
extends CanvasLayer
## Pause menu, opened with "cancel" while exploring.
## Tabs: Equipment (armor pieces), Bag (items) and Status (level, stats). While open it pauses the
## scene tree; this node keeps running because its process_mode is ALWAYS.
## Up/down move, action enters/confirms, cancel goes back or closes.

enum Tab { EQUIPMENT, BAG, STATUS, CLOSE }

const TAB_NAMES: Array[String] = ["Equipo", "Bolsa", "Estado", "Cerrar"]
const GOLD := Color(0.95, 0.8, 0.35)
const TEXT := Color(0.92, 0.94, 1)
const DIM := Color(0.55, 0.58, 0.7)
const ICON_SIZE := Vector2(48, 48)
const STAR: Texture2D = preload("res://assets/ui/star.png")

var _tab := Tab.EQUIPMENT
## True while the cursor is inside the bag list instead of the tabs.
var _in_list := false
var _item_index := 0

@onready var _tabs: VBoxContainer = $Window/HBox/Tabs
@onready var _title: Label = $Window/HBox/Content/Title
@onready var _list: VBoxContainer = $Window/HBox/Content/List
@onready var _footer: Label = $Window/HBox/Content/Footer


func _ready() -> void:
	hide()


func open() -> void:
	_tab = Tab.EQUIPMENT
	_in_list = false
	_refresh()
	show()
	get_tree().paused = true


func close() -> void:
	hide()
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		# Only open while exploring (not during a dialogue or another pause).
		if event.is_action_pressed("cancel") and not get_tree().paused:
			get_viewport().set_input_as_handled()
			open()
		return
	if event.is_action_pressed("move_up"):
		_move(-1)
	elif event.is_action_pressed("move_down"):
		_move(1)
	elif event.is_action_pressed("action"):
		_accept()
	elif event.is_action_pressed("cancel"):
		_back()
	else:
		return
	get_viewport().set_input_as_handled()


func _move(step: int) -> void:
	if _in_list:
		_item_index = wrapi(_item_index + step, 0, GameState.bag_items().size())
	else:
		_tab = wrapi(_tab + step, 0, TAB_NAMES.size()) as Tab
	_refresh()


func _accept() -> void:
	match _tab:
		Tab.BAG:
			if not _in_list and not GameState.bag_items().is_empty():
				_in_list = true
				_item_index = 0
		Tab.CLOSE:
			close()
			return
	_refresh()


func _back() -> void:
	if _in_list:
		_in_list = false
		_refresh()
	else:
		close()


func _refresh() -> void:
	_clear(_tabs)
	for i in TAB_NAMES.size():
		var selected := i == _tab
		_tabs.add_child(_row([_cursor(selected and not _in_list), _label(TAB_NAMES[i], 30, GOLD if selected else TEXT)]))
	_clear(_list)
	match _tab:
		Tab.EQUIPMENT:
			_show_equipment()
		Tab.BAG:
			_show_bag()
		Tab.STATUS:
			_show_status()
		Tab.CLOSE:
			_title.text = "Cerrar"
			_footer.text = "Volver a la aventura."


func _show_equipment() -> void:
	_title.text = "Equipo"
	var owned := GameState.owned_pieces()
	for piece: int in GameState.Piece.values():
		var has_it := piece in owned
		var icon := TextureRect.new()
		icon.texture = GameState.piece_icon(piece)
		icon.custom_minimum_size = ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# Missing pieces show as a dark silhouette.
		icon.modulate = Color.WHITE if has_it else Color(0, 0, 0, 0.55)
		var name_text: String = GameState.PIECE_NAMES[piece] if has_it else "???"
		_list.add_child(_row([icon, _label(name_text, 26, TEXT if has_it else DIM)]))
	var status := "Piezas: %d/%d" % [owned.size(), GameState.FULL_SET]
	if GameState.is_set_complete():
		status += "\n¡Set completo! Tu cosmos arde con fuerza."
	else:
		status += "\nCompleta el set para despertar su poder."
	_footer.text = status


func _show_bag() -> void:
	_title.text = "Bolsa"
	var ids := GameState.bag_items()
	if ids.is_empty():
		_footer.text = "La bolsa está vacía."
		return
	_item_index = clampi(_item_index, 0, ids.size() - 1)
	for i in ids.size():
		var selected := _in_list and i == _item_index
		var color := GOLD if selected else TEXT
		var item_name := _label(String(GameState.ITEMS[ids[i]]["name"]), 26, color)
		item_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_list.add_child(_row([_cursor(selected), item_name, _label("x%d" % GameState.item_count(ids[i]), 26, color)]))
	_footer.text = GameState.ITEMS[ids[_item_index]]["description"]


func _show_status() -> void:
	_title.text = "Estado"
	var hero := GameState.hero_combatant()
	var rows: Array[String] = [
		"%s   Nivel %d   Exp %d/%d" % [hero.display_name, GameState.level, GameState.experience, GameState.exp_to_next()],
		"PS %d/%d   Cosmos %d/%d" % [hero.hp, hero.max_hp, hero.cosmos, hero.max_cosmos],
		"Ataque %d   Defensa %d   Velocidad %d" % [hero.attack, hero.defense, hero.speed],
		"Técnicas:",
	]
	for id in GameState.known_techniques():
		rows.append("    %s  (%d de cosmos)" % [Techniques.ALL[id]["name"], Techniques.ALL[id]["cost"]])
	for i in rows.size():
		_list.add_child(_label(rows[i], 24, GOLD if i == 3 else TEXT))
	_footer.text = "Cada pieza de armadura suma %d de defensa y %d de cosmos." % [GameState.ARMOR_DEFENSE, GameState.ARMOR_COSMOS]
	if GameState.is_set_complete():
		_footer.text += "
Set completo: recuperas %d de cosmos por turno." % GameState.SET_COSMOS_REGEN


func _clear(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


## Gold star marking the selected row (transparent when not selected,
## so rows never shift sideways).
func _cursor(shown: bool) -> TextureRect:
	var cursor := TextureRect.new()
	cursor.texture = STAR
	cursor.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	cursor.modulate.a = 1.0 if shown else 0.0
	return cursor


func _row(children: Array[Control]) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
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
