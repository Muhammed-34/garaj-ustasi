class_name RoomBackdrop
extends Control

# Scenery for the shelter rooms, drawn in code. Every room looks different so opening a new one feels
# like a reward; a locked room is dimmed behind a padlock. Cats stand on the floor below FLOOR_Y.
const STYLES := ["salon", "garden", "attic", "winter_garden", "library"]
const FLOOR_Y := 0.72
const DIM := Color(0.18, 0.1, 0.05, 0.55)
# Winter garden sill: plant x positions, sill height and plant size, all as room fractions.
const SHELF_PLANTS := [0.22, 0.5, 0.78]
const SHELF_Y := 0.42
const PLANT_SCALE := 0.8
const PLANT_REACH := 0.3

var room_index := 0:
	set(value):
		room_index = value
		queue_redraw()
var locked := false:
	set(value):
		locked = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


static func style_for(index: int) -> String:
	return STYLES[clampi(index, 0, STYLES.size() - 1)]


func _draw() -> void:
	var style := style_for(room_index)
	if style == "salon":
		_draw_salon()
	elif style == "garden":
		_draw_garden()
	elif style == "attic":
		_draw_attic()
	elif style == "winter_garden":
		_draw_winter_garden()
	else:
		_draw_library()
	if locked:
		_draw_lock()


func _draw_salon() -> void:
	_rect(0, 0, 1, FLOOR_Y, Color("f9dcbc"))
	_rect(0, 0.6, 1, FLOOR_Y - 0.6, Color("f0c9a2"))
	_rect(0.06, 0.08, 0.24, 0.37, Color("fffaf3"))
	_rect(0.075, 0.105, 0.21, 0.32, Color("bfe3f5"))
	_rect(0.175, 0.105, 0.01, 0.32, Color("fffaf3"))
	_rect(0.075, 0.26, 0.21, 0.012, Color("fffaf3"))
	_rect(0.68, 0.12, 0.18, 0.26, Color("c98f5a"))
	_rect(0.695, 0.145, 0.15, 0.21, Color("fdf1dc"))
	draw_circle(_p(0.77, 0.25), size.y * 0.055, Color("f2b33d"))
	_floor(Color("d8a26c"), Color("c38c58"))
	_ellipse(_p(0.5, 0.88), Vector2(size.x * 0.24, size.y * 0.075), Color("e7a38f"))
	_ellipse(_p(0.5, 0.88), Vector2(size.x * 0.18, size.y * 0.045), Color("f0bca9"))


func _draw_garden() -> void:
	_rect(0, 0, 1, FLOOR_Y, Color("cdeeff"))
	draw_circle(_p(0.86, 0.17), size.y * 0.075, Color("ffe38a"))
	for cloud in [Vector2(0.18, 0.16), Vector2(0.52, 0.1)]:
		for n in 3:
			draw_circle(_p(cloud.x + n * 0.04, cloud.y + (0.02 if n == 1 else 0.035)), size.y * (0.06 if n == 1 else 0.045), Color.WHITE)
	for n in 6:
		draw_circle(_p(0.08 + n * 0.18, FLOOR_Y - 0.06), size.y * 0.11, Color("7cc26a"))
	for n in 13:
		_rect(0.02 + n * 0.08, 0.42, 0.035, FLOOR_Y - 0.42, Color("fff4e0"))
	_rect(0, 0.5, 1, 0.03, Color("fff4e0"))
	_rect(0, 0.62, 1, 0.03, Color("fff4e0"))
	_floor(Color("8fcf6b"), Color("7ab95a"))
	for n in 5:
		var at := _p(0.06 + n * 0.22, 0.78)
		draw_line(at, at + Vector2(0, size.y * 0.06), Color("4f9a32"), 3.0)
		draw_circle(at, size.y * 0.025, Color("ff8fb1") if n % 2 == 0 else Color("ffd94d"))


func _draw_attic() -> void:
	_rect(0, 0, 1, FLOOR_Y, Color("ecd1b0"))
	var beam := Color("b98352")
	draw_colored_polygon(PackedVector2Array([_p(0, 0), _p(0.34, 0), _p(0, 0.55)]), beam)
	draw_colored_polygon(PackedVector2Array([_p(1, 0), _p(0.66, 0), _p(1, 0.55)]), beam)
	draw_line(_p(0.34, 0), _p(0, 0.55), Color("8c5a2c"), 6.0)
	draw_line(_p(0.66, 0), _p(1, 0.55), Color("8c5a2c"), 6.0)
	draw_circle(_p(0.5, 0.26), size.y * 0.15, Color("fffaf3"))
	draw_circle(_p(0.5, 0.26), size.y * 0.12, Color("bfe3f5"))
	draw_line(_p(0.5, 0.14), _p(0.5, 0.38), Color("fffaf3"), 5.0)
	draw_line(_p(0.44, 0.26), _p(0.56, 0.26), Color("fffaf3"), 5.0)
	_floor(Color("c08a55"), Color("a8743f"))
	_rect(0.8, 0.5, 0.16, 0.22, Color("d9a061"))
	_rect(0.865, 0.5, 0.03, 0.22, Color("f3e1b5"))
	_rect(0.84, 0.36, 0.11, 0.14, Color("e3b075"))
	_rect(0.04, 0.56, 0.12, 0.16, Color("d9a061"))


func _draw_winter_garden() -> void:
	_rect(0, 0, 1, FLOOR_Y, Color("e3f5f1"))
	for n in 9:
		_rect(n * 0.125 - 0.004, 0, 0.008, FLOOR_Y, Color.WHITE)
	_rect(0, 0.24, 1, 0.012, Color.WHITE)
	_floor(Color("efe4d2"), Color("dccdb4"))
	# Plants sit on a sill above the cats' heads, so no cat stands in front of a pot.
	_rect(0.04, SHELF_Y, 0.92, 0.035, Color("c98f5a"))
	_rect(0.04, SHELF_Y + 0.035, 0.92, 0.012, Color("a8743f"))
	for x in SHELF_PLANTS:
		_plant(x, SHELF_Y, PLANT_SCALE)


func _draw_library() -> void:
	_rect(0, 0, 1, FLOOR_Y, Color("d4b28c"))
	_rect(0.03, 0.05, 0.94, 0.62, Color("7a4a2a"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var colors := [Color("d9574a"), Color("4a8fc9"), Color("e9b530"), Color("5fb36b"), Color("9b6fc6"), Color("f2efe6")]
	for shelf in 3:
		var bottom := 0.24 + shelf * 0.2
		_rect(0.03, bottom, 0.94, 0.025, Color("5e3519"))
		var x := 0.05
		while x < 0.93:
			var width := rng.randf_range(0.025, 0.045)
			var height := rng.randf_range(0.11, 0.16)
			_rect(x, bottom - height, width, height, colors[rng.randi_range(0, colors.size() - 1)])
			x += width + 0.006
	_floor(Color("9a6640"), Color("845535"))
	_ellipse(_p(0.5, 0.88), Vector2(size.x * 0.26, size.y * 0.075), Color("a8453a"))


func _draw_lock() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), DIM)
	var s := size.y * 0.16
	var center := _p(0.5, 0.36)
	draw_arc(center, s * 0.42, PI, TAU, 20, Color("fff3e6"), s * 0.16, true)
	var body := StyleBoxFlat.new()
	body.bg_color = Color("ffe38a")
	body.set_corner_radius_all(int(s * 0.18))
	draw_style_box(body, Rect2(center + Vector2(-s * 0.6, 0), Vector2(s * 1.2, s * 0.95)))
	draw_circle(center + Vector2(0, s * 0.4), s * 0.13, Color("5a3a28"))
	draw_rect(Rect2(center + Vector2(-s * 0.05, s * 0.42), Vector2(s * 0.1, s * 0.28)), Color("5a3a28"))


# A potted plant standing on base_y; leaves reach PLANT_REACH * scale of the room height.
func _plant(x: float, base_y: float, plant_scale: float) -> void:
	var pot_height := 0.14 * plant_scale
	var pot_top := base_y - pot_height
	var half := 0.05 * plant_scale
	draw_colored_polygon(PackedVector2Array([_p(x - half, pot_top), _p(x + half, pot_top), _p(x + half * 0.7, base_y), _p(x - half * 0.7, base_y)]), Color("d0764f"))
	for n in 5:
		var angle := -PI / 2 + (n - 2) * 0.45
		var tip := _p(x, pot_top) + Vector2(cos(angle), sin(angle)) * size.y * PLANT_REACH * plant_scale
		draw_line(_p(x, pot_top), tip, Color("4f9a32"), 4.0, true)
		draw_circle(tip, size.y * 0.035 * plant_scale, Color("6fb04a"))


func _floor(base: Color, lines: Color) -> void:
	_rect(0, FLOOR_Y, 1, 1 - FLOOR_Y, base)
	for n in 3:
		var y := FLOOR_Y + (n + 1) * (1 - FLOOR_Y) / 4.0
		draw_line(_p(0, y), _p(1, y), lines, 2.0)


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for n in 28:
		var angle := TAU * n / 28.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


func _rect(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(_p(x, y), Vector2(w * size.x, h * size.y)), color)


func _p(x: float, y: float) -> Vector2:
	return Vector2(x * size.x, y * size.y)
