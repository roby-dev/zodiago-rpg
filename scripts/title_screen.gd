extends Control
## Pantalla de inicio de Zodiago RPG.
## La imagen de fondo trae los botones dibujados; los botones reales se
## colocan exactamente encima, en coordenadas de la imagen, y se reubican
## cuando cambia el tamaño de la ventana.

const GOLD := Color(0.95, 0.80, 0.35)
## Must be fully opaque: the buttons hide the ones drawn on the background.
const NAVY := Color(0.10, 0.10, 0.32, 1.0)
const SIDE_COLOR := Color(0.07, 0.06, 0.20)
const WORLD_SCENE := "res://scenes/world.tscn"
const SAVE_PATH := "user://save.json"
const BACKGROUND: Texture2D = preload("res://assets/ui/title_background.png")

## Button rects in background-image pixels (measured on the 1448x1086 PNG).
## They are slightly wider than the drawn ones so they also cover the drawn ▶.
const BUTTON_RECTS: Array[Rect2] = [
	Rect2(938, 714, 466, 80),
	Rect2(938, 800, 466, 80),
	Rect2(938, 886, 466, 80),
]
## Where the status message goes (above the drawn "Presiona Start").
const INFO_RECT := Rect2(300, 980, 848, 44)

var _buttons: Array[Button] = []
var _cursors: Array[Label] = []
var _info: Label
var _image_rect := Rect2()


func _ready() -> void:
	_build_ui()
	resized.connect(_layout)
	_layout()
	# Entrada con fundido
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.8)
	for b in _buttons:
		if not b.disabled:
			b.grab_focus()
			break


func _draw() -> void:
	# Side bands for the parts of the window the 4:3 image does not cover.
	draw_rect(Rect2(Vector2.ZERO, size), SIDE_COLOR)
	draw_texture_rect(BACKGROUND, _image_rect, false)


## Fits the image inside the window (keeping aspect) and moves the buttons.
func _layout() -> void:
	var tex_size := BACKGROUND.get_size()
	var k := minf(size.x / tex_size.x, size.y / tex_size.y)
	var fitted := tex_size * k
	_image_rect = Rect2((size - fitted) / 2.0, fitted)
	for i in _buttons.size():
		_place(_buttons[i], BUTTON_RECTS[i], k)
		_buttons[i].add_theme_font_size_override("font_size", int(36 * k))
		_cursors[i].add_theme_font_size_override("font_size", int(30 * k))
		_cursors[i].position = Vector2(14 * k, 0)
		_cursors[i].size = Vector2(40 * k, BUTTON_RECTS[i].size.y * k)
	_place(_info, INFO_RECT, k)
	_info.add_theme_font_size_override("font_size", int(28 * k))
	queue_redraw()


func _place(control: Control, image_rect: Rect2, k: float) -> void:
	control.position = _image_rect.position + image_rect.position * k
	control.size = image_rect.size * k


func _build_ui() -> void:
	var new_btn := _make_button("Nueva partida")
	new_btn.pressed.connect(_on_new_game)

	var cont_btn := _make_button("Continuar")
	cont_btn.disabled = not FileAccess.file_exists(SAVE_PATH)
	cont_btn.pressed.connect(_on_continue)

	var quit_btn := _make_button("Salir")
	quit_btn.pressed.connect(_on_quit)

	# Keyboard navigation between absolutely-placed buttons (skips disabled ones).
	var usable := _buttons.filter(func(b: Button) -> bool: return not b.disabled)
	for b in _buttons:
		if b.disabled:
			b.focus_mode = Control.FOCUS_NONE
	for i in usable.size():
		var b: Button = usable[i]
		var prev: Button = usable[(i - 1 + usable.size()) % usable.size()]
		var next: Button = usable[(i + 1) % usable.size()]
		b.focus_neighbor_top = b.get_path_to(prev)
		b.focus_neighbor_bottom = b.get_path_to(next)

	_info = Label.new()
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_info.add_theme_color_override("font_color", Color(1, 0.88, 0.55))
	_info.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.15))
	_info.add_theme_constant_override("outline_size", 8)
	add_child(_info)

	var version := Label.new()
	version.text = "v0.1"
	version.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	version.offset_right = -12
	version.offset_bottom = -8
	add_child(version)


func _make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text

	var normal := StyleBoxFlat.new()
	normal.bg_color = NAVY
	normal.border_color = GOLD.darkened(0.25)
	normal.set_border_width_all(4)
	normal.set_corner_radius_all(10)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.18, 0.18, 0.48, 1.0)
	hover.border_color = GOLD

	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_stylebox_override("disabled", normal)
	b.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_focus_color", GOLD)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
	b.mouse_entered.connect(func(): if not b.disabled: b.grab_focus())

	# ▶ cursor inside the button, visible only while focused.
	var cursor := Label.new()
	cursor.text = "▶"
	cursor.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cursor.add_theme_color_override("font_color", GOLD)
	cursor.visible = false
	cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(cursor)
	b.focus_entered.connect(func(): cursor.visible = true)
	b.focus_exited.connect(func(): cursor.visible = false)

	add_child(b)
	_buttons.append(b)
	_cursors.append(cursor)
	return b


func _on_new_game() -> void:
	if ResourceLoader.exists(WORLD_SCENE):
		get_tree().change_scene_to_file(WORLD_SCENE)
	else:
		_info.text = "Aquí comenzará la aventura (el mundo aún no existe)."


func _on_continue() -> void:
	_info.text = "Cargar partida: pendiente de implementar."


func _on_quit() -> void:
	get_tree().quit()
