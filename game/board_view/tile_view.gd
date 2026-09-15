class_name TileView
extends Node2D

const RAINBOW := [Color("ff5a5a"), Color("ffb13d"), Color("ffe14d"), Color("5fd46b"), Color("4aa8ff"), Color("b36bff")]
const SHADOW := Color(0.35, 0.18, 0.08, 0.35)

var kind := 0
var special := 0
var cell_size := 96.0

var _sprite := Sprite2D.new()
var _overlay := Node2D.new()
var _pulse := 0.0
var _pulse_tween: Tween


func _init() -> void:
	add_child(_sprite)
	add_child(_overlay)
	_overlay.draw.connect(_draw_overlay)


func setup(new_kind: int, new_special: int, texture: Texture2D, size_px: float) -> void:
	kind = new_kind
	special = new_special
	cell_size = size_px
	_sprite.texture = texture
	_sprite.visible = texture != null and special != M3.Special.COLOR
	_fit_sprite()
	scale = Vector2.ONE
	modulate = Color.WHITE
	_restart_pulse()
	_overlay.queue_redraw()


func set_cell_size(size_px: float) -> void:
	cell_size = size_px
	_fit_sprite()
	_overlay.queue_redraw()


func _fit_sprite() -> void:
	if _sprite.texture == null:
		return
	var factor := cell_size * 0.9 / _sprite.texture.get_width()
	_sprite.scale = Vector2(factor, factor)


func _restart_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	_pulse = 0.0
	if (special == M3.Special.BOMB or special == M3.Special.COLOR) and is_inside_tree():
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_method(_set_pulse, 0.0, 1.0, 1.0)


func _set_pulse(value: float) -> void:
	_pulse = value
	_overlay.queue_redraw()


func _draw_overlay() -> void:
	var r := cell_size * 0.42
	if special == M3.Special.LINE_H or special == M3.Special.LINE_V:
		for offset in [-0.2, 0.0, 0.2]:
			var o: float = offset * cell_size
			var horizontal := special == M3.Special.LINE_H
			var from := Vector2(-r * 0.8, o) if horizontal else Vector2(o, -r * 0.8)
			var to := Vector2(r * 0.8, o) if horizontal else Vector2(o, r * 0.8)
			_overlay.draw_line(from, to, SHADOW, 10.0, true)
			_overlay.draw_line(from, to, Color(1, 1, 1, 0.92), 5.0, true)
	elif special == M3.Special.BOMB:
		var wave := 0.5 + 0.5 * sin(_pulse * TAU)
		_overlay.draw_arc(Vector2.ZERO, r * (0.98 + 0.06 * wave), 0.0, TAU, 40, Color(1.0, 0.55, 0.2, 0.55 + 0.35 * wave), 6.0, true)
		_overlay.draw_circle(Vector2(r * 0.55, -r * 0.62), 6.0 + 2.0 * wave, Color(1.0, 0.85, 0.3))
	elif special == M3.Special.COLOR:
		var spin := _pulse * TAU
		for n in RAINBOW.size():
			var angle := spin + n * TAU / RAINBOW.size()
			_overlay.draw_circle(Vector2(cos(angle), sin(angle)) * r * 0.32, r * 0.42, RAINBOW[n])
		_overlay.draw_circle(Vector2.ZERO, r * 0.46, Color(1, 1, 1, 0.9))
		_overlay.draw_circle(Vector2(-r * 0.18, -r * 0.2), r * 0.14, Color.WHITE)
	elif special == M3.Special.FLYER:
		var c := Vector2(r * 0.5, -r * 0.5)
		var points := PackedVector2Array([c + Vector2(-16, 8), c + Vector2(18, -10), c + Vector2(-4, 16)])
		_overlay.draw_colored_polygon(points, Color.WHITE)
		var outline := points.duplicate()
		outline.append(points[0])
		_overlay.draw_polyline(outline, Color(0.35, 0.18, 0.08, 0.6), 2.0, true)
