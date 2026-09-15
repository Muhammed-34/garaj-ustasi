class_name TitleRoom
extends Control

# The opening screen's living room, drawn in code: striped wallpaper, a curtained window with a drifting
# cloud, a plank floor with a rug, twinkling stars and the game's name on a wooden sign hanging from a nail.
# Positions are fractions of the screen; cats stand on the rug at RUG_Y.
const FLOOR_Y := 0.6
const RUG_Y := 0.665
const WINDOW := Rect2(0.3, 0.255, 0.4, 0.16)
const SIGN := Rect2(0.07, 0.06, 0.86, 0.1)
const STARS := [Vector2(0.86, 0.3), Vector2(0.12, 0.36), Vector2(0.9, 0.47)]
const WALL := Color("f7dcc0")
const STRIPE := Color("f0c9a6")
const WOOD_DARK := Color("8a5a3a")
const WOOD := Color("b27a47")
const ROPE := Color("6b4226")
const CURTAIN := Color("e8613b")
const FLOOR := Color("c98f5a")
const PLANK := Color("b27a47")
const TITLE_FILL := Color("fff4e0")
const TITLE_OUTLINE := Color("5a3a28")

var title_text := "":
	set(value):
		title_text = value
		queue_redraw()
# Seconds of idle animation; the room stays still while it does not advance.
var time := 0.0:
	set(value):
		time = value
		queue_redraw()

var _sign_outer := StyleBoxFlat.new()
var _sign_inner := StyleBoxFlat.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	_sign_outer.bg_color = WOOD_DARK
	_sign_outer.set_corner_radius_all(22)
	_sign_inner.bg_color = WOOD
	_sign_inner.set_corner_radius_all(16)


func _draw() -> void:
	_draw_wall()
	_draw_window()
	_draw_floor()
	_draw_stars()
	_draw_sign()


func _draw_wall() -> void:
	_rect(0, 0, 1, FLOOR_Y, WALL)
	var x := 0.0
	while x < 1.0:
		_rect(x, 0, 0.025, FLOOR_Y, Color(STRIPE, 0.55))
		x += 0.05
	_rect(0, FLOOR_Y - 0.012, 1, 0.012, Color("e2b48a"))


func _draw_window() -> void:
	var r := _r(WINDOW)
	var frame := size.x * 0.026
	draw_rect(r.grow(frame), WOOD_DARK)
	draw_rect(r, Color("bfe3f5"))
	draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.5)), Color("9ad4f5"))
	# The cloud sways inside the glass and never reaches the frame, so nothing needs clipping.
	var puff := r.size.y * 0.11
	var cloud := Vector2(r.get_center().x + sin(time * 0.35) * (r.size.x * 0.5 - puff * 3.0), r.position.y + r.size.y * 0.3)
	for offset in [Vector2(-1.2, 0.45), Vector2(1.25, 0.45), Vector2.ZERO]:
		draw_circle(cloud + offset * puff, puff * (1.3 if offset == Vector2.ZERO else 1.0), Color(1, 1, 1, 0.95))
	draw_rect(Rect2(r.get_center().x - frame * 0.35, r.position.y, frame * 0.7, r.size.y), WOOD_DARK)
	draw_rect(Rect2(r.position.x, r.get_center().y - frame * 0.35, r.size.x, frame * 0.7), WOOD_DARK)
	var sway := sin(time * 0.8) * size.x * 0.008
	var top := r.position.y - frame * 2.0
	var bottom := r.end.y + frame * 3.0
	var middle := (top + bottom) * 0.5
	# Curtains are drawn back to the sides: wide at the rod, pinched at the middle, flaring at the hem.
	var width := r.size.x * 0.24
	var left := r.position.x - frame * 1.2
	var right := r.end.x + frame * 1.2
	draw_colored_polygon(PackedVector2Array([
		Vector2(left - width * 0.2, top), Vector2(left + width, top), Vector2(left + width * 0.2 + sway, middle),
		Vector2(left + width * 0.55 + sway * 1.6, bottom), Vector2(left - width * 0.2, bottom)]), CURTAIN)
	draw_colored_polygon(PackedVector2Array([
		Vector2(right + width * 0.2, top), Vector2(right - width, top), Vector2(right - width * 0.2 - sway, middle),
		Vector2(right - width * 0.55 - sway * 1.6, bottom), Vector2(right + width * 0.2, bottom)]), CURTAIN)
	var rod := Rect2(left - width * 0.5, top - frame * 0.9, (right - left) + width, frame * 0.9)
	draw_rect(rod, ROPE)
	draw_circle(rod.position + Vector2(0, rod.size.y * 0.5), rod.size.y, ROPE)
	draw_circle(rod.end - Vector2(0, rod.size.y * 0.5), rod.size.y, ROPE)


func _draw_floor() -> void:
	_rect(0, FLOOR_Y, 1, 1 - FLOOR_Y, FLOOR)
	var y := FLOOR_Y + 0.035
	while y < 1.0:
		draw_line(_p(0, y), _p(1, y), PLANK, 3.0)
		y += 0.045
	_ellipse(_p(0.5, RUG_Y), Vector2(size.x * 0.47, size.y * 0.048), Color("e89a86"))
	_ellipse(_p(0.5, RUG_Y), Vector2(size.x * 0.38, size.y * 0.032), Color("f2b3a0"))


func _draw_stars() -> void:
	var texture := ArtAtlas.texture("star_on")
	for n in STARS.size():
		var glow := 0.6 + 0.4 * sin(time * 2.0 + n * 2.1)
		var side := size.x * (0.055 if n == 0 else 0.038)
		draw_texture_rect(texture, Rect2(_p(STARS[n].x, STARS[n].y) - Vector2(side, side) * 0.5, Vector2(side, side)), false, Color(1, 1, 1, glow))


# The sign hangs from one nail on two ropes and sways around that nail.
func _draw_sign() -> void:
	var r := _r(SIGN)
	var nail := Vector2(size.x * 0.5, r.position.y - size.y * 0.035)
	draw_set_transform(nail, sin(time * 0.9) * 0.015, Vector2.ONE)
	var board := Rect2(r.position - nail, r.size)
	draw_line(Vector2.ZERO, board.position + Vector2(board.size.x * 0.18, 4), ROPE, 3.0, true)
	draw_line(Vector2.ZERO, board.position + Vector2(board.size.x * 0.82, 4), ROPE, 3.0, true)
	draw_style_box(_sign_outer, board)
	draw_style_box(_sign_inner, board.grow(-size.x * 0.012))
	draw_circle(Vector2.ZERO, 7.0, ROPE)
	var font := get_theme_default_font()
	var font_size := int(size.y * 0.058)
	var text_size := font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	while text_size.x > board.size.x * 0.88 and font_size > 12:
		font_size -= 2
		text_size = font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := Vector2(-text_size.x * 0.5, board.get_center().y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5)
	draw_string_outline(font, baseline, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, maxi(2, int(font_size * 0.2)), TITLE_OUTLINE)
	draw_string(font, baseline, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TITLE_FILL)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for n in 32:
		var angle := TAU * n / 32.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


func _rect(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(_p(x, y), Vector2(w * size.x, h * size.y)), color)


func _r(fraction: Rect2) -> Rect2:
	return Rect2(_p(fraction.position.x, fraction.position.y), fraction.size * size)


func _p(x: float, y: float) -> Vector2:
	return Vector2(x * size.x, y * size.y)
