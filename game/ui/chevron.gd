class_name Chevron
extends Control

# A double chevron drawn in code, used on the map's "jump to the end" buttons.
const COLOR := Color("5a3a28")

var pointing_up := true:
	set(value):
		pointing_up = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var width := maxf(3.0, w * 0.09)
	for shift: float in [-0.1, 0.1]:
		var tip: float = h * ((0.36 if pointing_up else 0.64) + shift)
		var base: float = h * ((0.54 if pointing_up else 0.46) + shift)
		draw_polyline(PackedVector2Array([Vector2(w * 0.3, base), Vector2(w * 0.5, tip), Vector2(w * 0.7, base)]), COLOR, width, true)
