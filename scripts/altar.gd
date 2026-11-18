class_name Altar
extends StaticBody2D
## Pedestal holding one armor piece. Interacting takes the piece if it is
## the next one in order (see GameState) and asks for a message.

signal talk_requested(speaker: String, lines: PackedStringArray, icon: Texture2D)

const SPEAKER := "Altar de las estrellas"

## Index in GameState.Piece.
@export_enum("Bracers", "Boots", "Chest", "Shoulders", "Tiara") var piece := 0

var _taken := false

@onready var _item: Sprite2D = $Item


func _ready() -> void:
	_item.texture = GameState.piece_icon(piece)
	var bob := create_tween().set_loops()
	bob.tween_property(_item, "position:y", _item.position.y - 3.0, 0.7)
	bob.tween_property(_item, "position:y", _item.position.y, 0.7)


func interact(_by: Node) -> void:
	var icon := GameState.piece_icon(piece)
	if _taken:
		talk_requested.emit(SPEAKER, PackedStringArray(["El altar está vacío. Solo queda el eco de las estrellas."]), null)
		return
	if not GameState.obtain(piece):
		talk_requested.emit(SPEAKER, PackedStringArray(["Una fuerza antigua protege esta reliquia. Aún no es tu momento."]), icon)
		return
	_taken = true
	_item.hide()
	var lines := PackedStringArray([
		"¡Obtuviste: %s!" % GameState.PIECE_NAMES[piece],
		GameState.PIECE_LORE[piece],
	])
	if GameState.is_set_complete():
		lines.append("¡Tu armadura está completa! Tu cosmos arde como nunca.")
	talk_requested.emit(SPEAKER, lines, icon)
