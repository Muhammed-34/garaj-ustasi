class_name MapTheme
extends RefCounted

# Garaj Ustası map ("Yarış Pisti"): a race track with red-and-white kerbs climbs through the infield past tyre
# barriers and cones, the levels are race numbers and a chequered line marks the start below level 1.
# map.gd draws the track behind its level column, so it scrolls with the levels.
const BACKGROUND_TOP := Color("8fcf72")
const BACKGROUND_BOTTOM := Color("6fae62")
const NODE_RADIUS := 75
const NODE_CURRENT := Color("ffd166")
const NODE_DONE := Color("ffffff")
const NODE_LOCKED := Color("c9d1da")
const NODE_EDGE := Color("1c1f24")
const NODE_EDGE_LOCKED := Color("7d8894")
const TEXT_DARK := Color("1c1f24")
const TEXT_LOCKED := Color("6b7480")
const ASPHALT := Color("4a4f57")
const KERB_RED := Color("e0503c")
const TRACK_WIDTH := 108.0
const KERB_WIDTH := 134.0
const KERB_STEP := 34.0
# Measured from the bottom end of the track, well below level 1's stars.
const START_DISTANCE := 70.0
const TYRE := Color("2b2f36")
const TYRE_HUB := Color("6b7480")
const CONE := Color("ff8a3d")
# Scenery keeps to the right of the level column, where the track never goes.
const SCENERY_LEFT := 490.0
const SCENERY_STEP := 300.0


static func background() -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, BACKGROUND_TOP)
	gradient.set_color(1, BACKGROUND_BOTTOM)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_to = Vector2(0, 1)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


# state is &"current" (the next level to play), &"done" (beaten) or &"locked".
static func style_node(button: Button, state: StringName) -> void:
	var fill := NODE_CURRENT
	var edge := NODE_EDGE
	var text_color := TEXT_DARK
	if state == &"done":
		fill = NODE_DONE
	elif state == &"locked":
		fill = NODE_LOCKED
		edge = NODE_EDGE_LOCKED
		text_color = TEXT_LOCKED
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		button.add_theme_color_override(key, text_color)
	button.add_theme_stylebox_override("normal", _number(fill, edge))
	button.add_theme_stylebox_override("disabled", _number(fill, edge))
	button.add_theme_stylebox_override("hover", _number(fill.lightened(0.06), edge))
	button.add_theme_stylebox_override("pressed", _number(fill.darkened(0.08), edge))
	button.add_theme_stylebox_override("hover_pressed", _number(fill.darkened(0.08), edge))


static func decorate_node(_button: Button) -> void:
	pass


static func draw_scenery(canvas: CanvasItem, area: Rect2) -> void:
	var y := area.position.y + 120.0
	var k := 0
	while y < area.end.y:
		var at := Vector2(SCENERY_LEFT + fmod(k * 83.0, 110.0), y)
		if k % 2 == 0:
			_tyre_wall(canvas, at)
		else:
			_cone(canvas, at)
		y += SCENERY_STEP
		k += 1


static func draw_track(canvas: CanvasItem, points: PackedVector2Array) -> void:
	canvas.draw_polyline(points, Color.WHITE, KERB_WIDTH, true)
	var red := true
	for mark in marks(points, KERB_STEP):
		if red:
			var along := Vector2.from_angle(mark[1]) * KERB_STEP * 0.5
			canvas.draw_line(mark[0] - along, mark[0] + along, KERB_RED, KERB_WIDTH)
		red = not red
	canvas.draw_polyline(points, ASPHALT, TRACK_WIDTH, true)
	var start := marks(points, START_DISTANCE)
	if start.size() > 1:
		_start_line(canvas, start[1][0], start[1][1])


# Evenly spaced points along the track, each as [position, direction of travel in radians].
static func marks(points: PackedVector2Array, spacing: float) -> Array:
	var result := []
	var next := 0.0
	var walked := 0.0
	for n in range(1, points.size()):
		var a := points[n - 1]
		var b := points[n]
		var length := a.distance_to(b)
		while length > 0.0 and next <= walked + length:
			result.append([a.lerp(b, (next - walked) / length), (b - a).angle()])
			next += spacing
		walked += length
	return result


static func _number(fill: Color, edge: Color) -> StyleBoxFlat:
	var style := UiKit.box(fill, NODE_RADIUS, 12)
	style.set_border_width_all(7)
	style.border_color = edge
	return style


# Two rows of chequered squares across the track.
static func _start_line(canvas: CanvasItem, at: Vector2, angle: float) -> void:
	canvas.draw_set_transform(at, angle, Vector2.ONE)
	var cell := TRACK_WIDTH / 8.0
	for column in 2:
		for row in 8:
			var color: Color = Color.WHITE if (column + row) % 2 == 0 else TYRE
			canvas.draw_rect(Rect2(Vector2(column * cell - cell, row * cell - TRACK_WIDTH * 0.5), Vector2(cell, cell)), color)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _tyre_wall(canvas: CanvasItem, at: Vector2) -> void:
	for offset in [Vector2(0, 0), Vector2(40, 0), Vector2(80, 0), Vector2(20, -32), Vector2(60, -32)]:
		canvas.draw_circle(at + offset, 21.0, TYRE)
		canvas.draw_circle(at + offset, 9.0, TYRE_HUB)


static func _cone(canvas: CanvasItem, at: Vector2) -> void:
	canvas.draw_rect(Rect2(at + Vector2(-26, 20), Vector2(52, 8)), TYRE)
	canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-20, 20), at + Vector2(20, 20), at + Vector2(0, -34)]), CONE)
	canvas.draw_line(at + Vector2(-11, -4), at + Vector2(11, -4), Color.WHITE, 6.0)
