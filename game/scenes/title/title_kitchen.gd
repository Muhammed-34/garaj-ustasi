class_name TitleKitchen
extends Control

# The opening screen's kitchen ("Çinili Mutfak"), drawn in code: a blue-and-white tiled wall, the game's
# name on a green board, a shelf of jars and tools, and a dark stove. The picture is static and drawn once;
# only the steam layer redraws while the screen idles. Positions are fractions of the screen.
const WALL_BOTTOM := 0.58
const BURNER_Y := 0.64
const DISH_CENTER := Vector2(0.5, 0.525)
const DISH_WIDTH := 0.56
const SIGN := Rect2(0.08, 0.07, 0.84, 0.12)
const SHELF_Y := 0.29
const JARS := [[0.19, Color("e0503c")], [0.31, Color("f2c94c")], [0.43, Color("86c962")]]
const TILES_ACROSS := 9
const WALL := Color("f4f1ea")
const TILE_EDGE := Color("c9dcec")
const TILE_MARK := Color("4a86c5", 0.55)
const BOARD := Color("2f5240")
const BOARD_TRIM := Color("c9b27a")
const WOOD := Color("8a5a2e")
const STOVE := Color("3a302b")
const STOVE_EDGE := Color("6b5a50")
const TITLE_FILL := Color("fff4e0")
const TITLE_OUTLINE := Color("1f3a2b")

var title_text := "":
	set(value):
		title_text = value
		queue_redraw()
# Seconds of idle animation; the steam stays still while it does not advance.
var time := 0.0:
	set(value):
		time = value
		_steam.queue_redraw()
# Extra steam after the pan is tapped; fades back to 0.
var puff := 0.0

var _steam := Control.new()
var _tile := StyleBoxFlat.new()
var _jar := StyleBoxFlat.new()
var _board := StyleBoxFlat.new()
var _board_shadow := StyleBoxFlat.new()
var _trim := StyleBoxFlat.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	_tile.bg_color = Color.WHITE
	_tile.border_color = TILE_EDGE
	_tile.set_border_width_all(3)
	_tile.set_corner_radius_all(8)
	_jar.bg_color = Color(1, 1, 1, 0.85)
	_jar.border_color = Color("d9cfc2")
	_jar.set_border_width_all(3)
	_jar.set_corner_radius_all(12)
	_board.bg_color = BOARD
	_board.set_corner_radius_all(30)
	_board_shadow.bg_color = Color(0, 0, 0, 0.14)
	_board_shadow.set_corner_radius_all(30)
	_trim.draw_center = false
	_trim.border_color = BOARD_TRIM
	_trim.set_border_width_all(5)
	_trim.set_corner_radius_all(22)
	_steam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_steam.set_anchors_preset(Control.PRESET_FULL_RECT)
	_steam.draw.connect(_draw_steam)
	add_child(_steam)


func _draw() -> void:
	_draw_wall()
	_draw_sign()
	_draw_shelf()
	_draw_stove()


# Dish rectangle in screen pixels; the title screen places the tappable pan here.
func dish_rect() -> Rect2:
	var dish_size := Vector2(DISH_WIDTH, DISH_WIDTH * 0.75) * size.x
	return Rect2(_p(DISH_CENTER.x, DISH_CENTER.y) - dish_size * 0.5, dish_size)


func _draw_wall() -> void:
	draw_rect(Rect2(Vector2.ZERO, _p(1, WALL_BOTTOM)), WALL)
	var side := size.x / TILES_ACROSS
	var row := 0
	while row * side < size.y * WALL_BOTTOM:
		var x := -side * 0.5 if row % 2 == 1 else 0.0
		while x < size.x:
			var cell := Rect2(x, row * side, side, side)
			draw_style_box(_tile, cell.grow(-side * 0.05))
			var c := cell.get_center()
			var h := side * 0.3
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -h), c + Vector2(h * 0.5, 0), c + Vector2(0, h), c + Vector2(-h * 0.5, 0)]), TILE_MARK)
			x += side
		row += 1


func _draw_sign() -> void:
	var board := _r(SIGN)
	draw_style_box(_board_shadow, Rect2(board.position + Vector2(0, size.y * 0.007), board.size))
	draw_style_box(_board, board)
	draw_style_box(_trim, board.grow(-size.x * 0.022))
	var font := get_theme_default_font()
	var font_size := int(size.x * 0.1)
	var text_size := font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	while text_size.x > board.size.x * 0.86 and font_size > 12:
		font_size -= 2
		text_size = font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := Vector2(board.get_center().x - text_size.x * 0.5, board.get_center().y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5)
	draw_string_outline(font, baseline, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, maxi(2, int(font_size * 0.18)), TITLE_OUTLINE)
	draw_string(font, baseline, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TITLE_FILL)


func _draw_shelf() -> void:
	var shelf := Rect2(_p(0.11, SHELF_Y), Vector2(size.x * 0.78, size.y * 0.012))
	var jar_size := Vector2(size.x * 0.09, size.y * 0.052)
	for jar in JARS:
		var body := Rect2(Vector2(size.x * jar[0] - jar_size.x * 0.5, shelf.position.y - jar_size.y), jar_size)
		draw_style_box(_jar, body)
		draw_rect(Rect2(body.position + Vector2(jar_size.x * 0.1, jar_size.y * 0.36), Vector2(jar_size.x * 0.8, jar_size.y * 0.56)), jar[1])
		draw_rect(Rect2(body.position + Vector2(-jar_size.x * 0.06, -jar_size.y * 0.1), Vector2(jar_size.x * 1.12, jar_size.y * 0.18)), WOOD)
	_icon("booster_row", 0.64, 0.262, 0.155)
	_icon("booster_shuffle", 0.8, 0.258, 0.14)
	draw_rect(shelf, WOOD)


func _draw_stove() -> void:
	draw_rect(Rect2(_p(0, WALL_BOTTOM), Vector2(size.x, size.y * (1.0 - WALL_BOTTOM))), STOVE)
	draw_rect(Rect2(_p(0, WALL_BOTTOM), Vector2(size.x, size.y * 0.011)), STOVE_EDGE)
	_ellipse(_p(0.5, BURNER_Y), Vector2(size.x * 0.24, size.y * 0.018), Color("1f1b19"))
	_ellipse(_p(0.5, BURNER_Y), Vector2(size.x * 0.17, size.y * 0.01), Color("e8613b", 0.5))
	_icon("tile_1", 0.14, 0.545, 0.16)
	_icon("tile_3", 0.86, 0.55, 0.145)


# Three wisps rise over the pan and sway; a tap makes them taller and brighter for a moment.
func _draw_steam() -> void:
	var dish := dish_rect()
	var bottom := dish.position.y + dish.size.y * 0.2
	var height := size.y * (0.06 + 0.03 * puff)
	for n in 3:
		var x := dish.get_center().x + (n - 1) * size.x * 0.14
		var points := PackedVector2Array()
		for step in 9:
			var f := step / 8.0
			var sway := sin(time * 2.4 + n * 1.9 + f * 5.0) * size.x * 0.018 * (0.4 + f)
			points.append(Vector2(x + sway, bottom - height * f))
		var alpha := (0.45 + 0.2 * sin(time * 1.7 + n)) * (1.0 + puff * 0.6)
		# A soft grey edge keeps the white wisps readable against the white tiles.
		_steam.draw_polyline(points, Color(0.42, 0.5, 0.58, clampf(alpha * 0.35, 0.0, 0.4)), size.x * 0.026, true)
		_steam.draw_polyline(points, Color(1, 1, 1, clampf(alpha * 1.3, 0.0, 0.95)), size.x * 0.014, true)


func _icon(sprite: String, x: float, y: float, width: float) -> void:
	var side := size.x * width
	draw_texture_rect(ArtAtlas.texture(sprite), Rect2(_p(x, y) - Vector2(side, side) * 0.5, Vector2(side, side)), false)


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for n in 32:
		var angle := TAU * n / 32.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


func _r(fraction: Rect2) -> Rect2:
	return Rect2(_p(fraction.position.x, fraction.position.y), fraction.size * size)


func _p(x: float, y: float) -> Vector2:
	return Vector2(x * size.x, y * size.y)
