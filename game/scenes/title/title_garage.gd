class_name TitleGarage
extends Control

# The opening screen's garage ("Mahalle Garajı"), drawn in code: a blue plank wall, the game's name on a
# riveted metal sign, a tool pegboard, a half-open shutter and a grey floor with a car lift. The picture is
# static and drawn once; only the sparkle layer redraws while the screen idles.
# The sign, pegboard and shutter sit at fractions of the screen height; the floor, lift and car sit a fixed
# distance (in screen widths) above stage_bottom, so tall phones get more wall rather than an empty floor.
const SIGN := Rect2(0.07, 0.07, 0.86, 0.13)
const PEGBOARD := Rect2(0.08, 0.235, 0.36, 0.14)
const SHUTTER := Rect2(0.52, 0.235, 0.41, 0.18)
const FLOOR_ABOVE_STAGE := 0.45
const LIFT_ABOVE_STAGE := 0.2
const POST_FOOT_ABOVE_STAGE := 0.035
const CAR_WIDTH := 0.66
const WALL := Color("5b7fa6")
const PLANK := Color("4c6d92")
const PLATE := Color("c9d1da")
const PLATE_EDGE := Color("8a95a1")
const RIVET := Color("7d8894")
const BOARD := Color("d8b48a")
const BOARD_HOLE := Color("a8845c")
const SHUTTER_DARK := Color("3a3f47")
const SLAT := Color("9aa3ad")
const FLOOR := Color("8b949e")
const FLOOR_EDGE := Color("6b7480")
const LIFT := Color("ffd166")
const LIFT_BAR := Color("e8a317")
const TITLE_FILL := Color("ffd166")
const TITLE_OUTLINE := Color("2b2f36")

var title_text := "":
	set(value):
		title_text = value
		queue_redraw()
# Top of the button area in pixels; 0 falls back to a fraction of the screen.
var stage_bottom := 0.0:
	set(value):
		stage_bottom = value
		queue_redraw()
		_sparkle.queue_redraw()
# Seconds of idle animation; the sparkles stay still while it does not advance.
var time := 0.0:
	set(value):
		time = value
		_sparkle.queue_redraw()
# Extra shine after the car is tapped; fades back to 0.
var shine := 0.0

var _sparkle := Control.new()
var _plate := StyleBoxFlat.new()
var _board := StyleBoxFlat.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	_plate.bg_color = PLATE
	_plate.border_color = PLATE_EDGE
	_plate.set_border_width_all(6)
	_plate.set_corner_radius_all(24)
	_plate.shadow_color = Color(0, 0, 0, 0.18)
	_plate.shadow_size = 8
	_plate.shadow_offset = Vector2(0, 6)
	_board.bg_color = BOARD
	_board.set_corner_radius_all(14)
	_sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sparkle.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sparkle.draw.connect(_draw_sparkles)
	add_child(_sparkle)


func _draw() -> void:
	_draw_wall()
	_draw_sign()
	_draw_pegboard()
	_draw_shutter()
	_draw_floor()


# Car rectangle in screen pixels; the title screen places the tappable car here, wheels on the lift.
func car_rect() -> Rect2:
	var car_size := Vector2(CAR_WIDTH, CAR_WIDTH * 0.75) * size.x
	# The vehicle art's wheels touch the ground at 109/120 of its height.
	var top := _above_stage(LIFT_ABOVE_STAGE) - car_size.y * 109.0 / 120.0
	return Rect2(Vector2(size.x * 0.5 - car_size.x * 0.5, top), car_size)


func _above_stage(widths: float) -> float:
	var stage := stage_bottom if stage_bottom > 0.0 else size.y * 0.69
	return stage - widths * size.x


func _r(fraction: Rect2) -> Rect2:
	return Rect2(fraction.position * size, fraction.size * size)


func _draw_wall() -> void:
	var floor_top := _above_stage(FLOOR_ABOVE_STAGE)
	draw_rect(Rect2(0, 0, size.x, floor_top), WALL)
	var gap := size.x * 0.072
	var y := gap
	while y < floor_top:
		draw_line(Vector2(0, y), Vector2(size.x, y), PLANK, 3.0)
		y += gap


func _draw_sign() -> void:
	var plate := _r(SIGN)
	draw_style_box(_plate, plate)
	var inset := size.x * 0.035
	for corner in [plate.position + Vector2(inset, inset), Vector2(plate.end.x - inset, plate.position.y + inset), Vector2(plate.position.x + inset, plate.end.y - inset), plate.end - Vector2(inset, inset)]:
		draw_circle(corner, size.x * 0.011, RIVET)
	var font := get_theme_default_font()
	var font_size := int(size.x * 0.105)
	var text_size := font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	while text_size.x > plate.size.x * 0.84 and font_size > 12:
		font_size -= 2
		text_size = font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := Vector2(plate.get_center().x - text_size.x * 0.5, plate.get_center().y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5)
	draw_string_outline(font, baseline, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, maxi(2, int(font_size * 0.2)), TITLE_OUTLINE)
	draw_string(font, baseline, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TITLE_FILL)


func _draw_pegboard() -> void:
	var board := _r(PEGBOARD)
	draw_style_box(_board, board)
	var step := size.x * 0.032
	var y := board.position.y + step
	while y < board.end.y - step * 0.5:
		var x := board.position.x + step
		while x < board.end.x - step * 0.5:
			draw_circle(Vector2(x, y), size.x * 0.004, BOARD_HOLE)
			x += step
		y += step
	var side := board.size.y * 0.55
	_icon("booster_row", board.position + Vector2(board.size.x * 0.26, board.size.y * 0.36), side)
	_icon("booster_single", board.position + Vector2(board.size.x * 0.72, board.size.y * 0.36), side)
	_icon("tile_5", board.position + Vector2(board.size.x * 0.22, board.size.y * 0.8), board.size.y * 0.34)
	_icon("tile_2", board.position + Vector2(board.size.x * 0.75, board.size.y * 0.8), board.size.y * 0.3)


func _draw_shutter() -> void:
	var door := _r(SHUTTER)
	draw_rect(door, SHUTTER_DARK)
	var slat := size.y * 0.009
	var y := door.position.y
	while y < door.position.y + door.size.y * 0.6:
		draw_rect(Rect2(door.position.x, y, door.size.x, slat), SLAT)
		y += slat * 1.5
	draw_rect(Rect2(door.position.x - size.x * 0.012, door.position.y, size.x * 0.012, door.size.y), FLOOR_EDGE)
	draw_rect(Rect2(door.end.x, door.position.y, size.x * 0.012, door.size.y), FLOOR_EDGE)


func _draw_floor() -> void:
	var top := _above_stage(FLOOR_ABOVE_STAGE)
	draw_rect(Rect2(0, top, size.x, size.y - top), FLOOR)
	draw_rect(Rect2(0, top, size.x, size.x * 0.02), FLOOR_EDGE)
	var foot := _above_stage(POST_FOOT_ABOVE_STAGE)
	var bar := _above_stage(LIFT_ABOVE_STAGE)
	_ellipse(Vector2(size.x * 0.5, foot), Vector2(size.x * 0.4, size.x * 0.03), Color(0.23, 0.25, 0.28, 0.45))
	for x in [0.2, 0.8]:
		draw_rect(Rect2(size.x * x - size.x * 0.022, bar, size.x * 0.044, foot - bar), LIFT)
	var bar_rect := Rect2(size.x * 0.14, bar - size.x * 0.012, size.x * 0.72, size.x * 0.034)
	draw_rect(bar_rect, LIFT_BAR)
	for n in 3:
		_icon("fuel", Vector2(size.x * (0.1 + n * 0.075), _above_stage(0.08)), size.x * 0.085)
	_icon("tile_3", Vector2(size.x * 0.76, _above_stage(0.075)), size.x * 0.11)
	_icon("tile_4", Vector2(size.x * 0.9, _above_stage(0.08)), size.x * 0.1)


# Two small stars twinkle on the freshly polished car; a tap makes them bigger for a moment.
func _draw_sparkles() -> void:
	var car := car_rect()
	var texture := ArtAtlas.texture("star_on")
	var spots := [Vector2(0.62, 0.36), Vector2(0.3, 0.52)]
	for n in spots.size():
		var glow := clampf(0.35 + 0.45 * sin(time * 2.2 + n * 2.4) + shine * 0.6, 0.0, 1.0)
		var side := size.x * (0.045 + 0.03 * shine) * (1.0 if n == 0 else 0.7)
		var center: Vector2 = car.position + car.size * spots[n]
		_sparkle.draw_texture_rect(texture, Rect2(center - Vector2(side, side) * 0.5, Vector2(side, side)), false, Color(1, 1, 1, glow))


func _icon(sprite: String, center: Vector2, side: float) -> void:
	draw_texture_rect(ArtAtlas.texture(sprite), Rect2(center - Vector2(side, side) * 0.5, Vector2(side, side)), false)


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for n in 32:
		var angle := TAU * n / 32.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
