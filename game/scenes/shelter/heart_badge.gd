class_name HeartBadge
extends Control

# Small heart drawn on a favourite cat's card. The dark rim keeps it readable on the white card.
const FILL := Color("e8613b")
const RIM := Color("a8321f")
const SHINE := Color(1, 1, 1, 0.75)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var rim := minf(size.x, size.y) * 0.1
	_heart(RIM, 0.0)
	_heart(FILL, rim)
	draw_circle(Vector2(size.x * 0.3, size.y * 0.32), minf(size.x, size.y) * 0.09, SHINE)


func _heart(color: Color, inset: float) -> void:
	var w := size.x - inset * 2.0
	var h := size.y - inset * 2.0
	var origin := Vector2(inset, inset)
	draw_circle(origin + Vector2(w * 0.29, h * 0.34), w * 0.27, color)
	draw_circle(origin + Vector2(w * 0.71, h * 0.34), w * 0.27, color)
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(w * 0.04, h * 0.44),
		origin + Vector2(w * 0.96, h * 0.44),
		origin + Vector2(w * 0.5, h * 0.98),
	]), color)
