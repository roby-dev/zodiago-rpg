class_name DialogueBox
extends CanvasLayer
## Text box with a typewriter effect. While open it pauses the scene tree;
## this node keeps running because its process_mode is ALWAYS.
## Action/Cancel: first press reveals the whole line, next press advances.

@export var chars_per_second := 40.0

var _lines: PackedStringArray = []
var _index := 0
var _shown := 0.0
var _time := 0.0

@onready var _speaker: Label = $Panel/HBox/VBox/Speaker
@onready var _text: Label = $Panel/HBox/VBox/Text
@onready var _arrow: TextureRect = $Panel/HBox/VBox/NextArrow
@onready var _icon: TextureRect = $Panel/HBox/Icon


func _ready() -> void:
	hide()


func is_open() -> bool:
	return visible


## `icon` (optional) is shown at the left, e.g. an obtained item.
func open(speaker: String, lines: PackedStringArray, icon: Texture2D = null) -> void:
	if lines.is_empty():
		return
	_speaker.text = speaker
	_icon.texture = icon
	_icon.visible = icon != null
	_lines = lines
	_index = 0
	_show_line()
	show()
	get_tree().paused = true


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	if _is_typing():
		_shown += chars_per_second * delta
		_text.visible_characters = int(_shown)
	else:
		# Blink via alpha (not `visible`) so the layout never shifts.
		_arrow.modulate.a = 1.0 if fmod(_time, 0.8) < 0.5 else 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("action") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		if _is_typing():
			_text.visible_characters = _text.get_total_character_count()
		else:
			_advance()


func _show_line() -> void:
	_text.text = _lines[_index]
	_text.visible_characters = 0
	_shown = 0.0
	_arrow.modulate.a = 0.0


func _is_typing() -> bool:
	return _text.visible_characters < _text.get_total_character_count()


func _advance() -> void:
	_index += 1
	if _index < _lines.size():
		_show_line()
	else:
		_close()


func _close() -> void:
	hide()
	get_tree().paused = false
