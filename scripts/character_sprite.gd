@tool
class_name CharacterSprite
extends Sprite2D
## Character drawn from a 3x4 spritesheet of 32x48 frames.
##   Rows:    0 down, 1 left, 2 right, 3 up
##   Columns: 0 standing, 1 walk (left foot), 2 walk (right foot)
## The node origin is the center of the tile; the offset puts the feet on
## the bottom edge of the tile, so the head overlaps the tile above (y-sort).

const ROWS := {
	Vector2i.DOWN: 0,
	Vector2i.LEFT: 1,
	Vector2i.RIGHT: 2,
	Vector2i.UP: 3,
}

var facing := Vector2i.DOWN:
	set(value):
		facing = value
		refresh()

## 0 = standing, 1/2 = walking frames.
var step_frame := 0:
	set(value):
		step_frame = value
		refresh()


func _ready() -> void:
	hframes = 3
	vframes = 4
	refresh()


## Picks the frame for the current facing/step. Call after changing texture.
func refresh() -> void:
	if texture == null:
		return
	frame_coords = Vector2i(step_frame, ROWS.get(facing, 0))
