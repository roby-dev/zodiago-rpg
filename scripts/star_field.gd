class_name StarField
extends Control
## Night sky drawn in code: twinkling stars plus one constellation (Aries).
## Purely decorative background for menus.

const STAR_COUNT := 90
const LINE_COLOR := Color(0.95, 0.8, 0.35, 0.35)
## Aries, in fractions of the control size (right margin, outside the menu window).
const ARIES: Array[Vector2] = [
	Vector2(0.885, 0.16), Vector2(0.925, 0.21), Vector2(0.955, 0.29), Vector2(0.962, 0.38),
]

var _stars: Array[Vector3] = []  # x, y (fractions), twinkle phase
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 12  # Same sky every time.
	for i in STAR_COUNT:
		_stars.append(Vector3(rng.randf(), rng.randf(), rng.randf() * TAU))


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_time += delta
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.09, 0.82))
	for star in _stars:
		var alpha := 0.35 + 0.35 * sin(_time * 1.5 + star.z)
		draw_rect(Rect2(Vector2(star.x, star.y) * size, Vector2(2, 2)), Color(0.85, 0.88, 1.0, alpha))
	for i in ARIES.size() - 1:
		draw_line(ARIES[i] * size, ARIES[i + 1] * size, LINE_COLOR, 2.0)
	for point in ARIES:
		draw_rect(Rect2(point * size - Vector2(3, 3), Vector2(6, 6)), Color(1.0, 0.92, 0.6))
