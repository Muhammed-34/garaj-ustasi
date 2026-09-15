class_name CatRig
extends Node2D

# Origin is the point between the cat's feet; parts rotate and scale around their own pivots.

const TOP_PARTS := ["tail", "body", "head"]
const BLINK_EVERY := 3.0
const BLINK_TIME := 0.12

var cat_id := ""
var height_px := 240.0
var idle_level := 2

var _parts := {}
var _tweens: Array[Tween] = []


func _ready() -> void:
	if not _parts.is_empty() and _tweens.is_empty():
		_start_idle()


func setup(id: String, height: float, level: int) -> void:
	cat_id = id
	height_px = height
	idle_level = level
	_stop_idle()
	for child in get_children():
		child.free()
	_parts.clear()
	for part in TOP_PARTS:
		var sprite := _make_part("cat_%s_%s" % [id, part])
		add_child(sprite)
		_parts[part] = sprite
	var blink := _make_part("cat_%s_blink" % id)
	blink.position = Vector2.ZERO
	blink.scale = Vector2.ONE
	blink.visible = false
	_parts.head.add_child(blink)
	_parts["blink"] = blink
	if is_inside_tree():
		_start_idle()


func get_part(part: String) -> Sprite2D:
	return _parts.get(part)


func part_count() -> int:
	return _parts.size()


func active_animation_count() -> int:
	return _tweens.size()


func _make_part(sprite_name: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture = ArtAtlas.texture(sprite_name)
	if sprite.texture == null:
		return sprite
	var size := Vector2(sprite.texture.get_width(), sprite.texture.get_height())
	var factor := height_px / size.y
	var pivot := ArtAtlas.pivot(sprite_name) * size
	sprite.offset = -pivot
	sprite.scale = Vector2(factor, factor)
	sprite.position = (pivot - Vector2(size.x * 0.5, size.y)) * factor
	return sprite


func _start_idle() -> void:
	if idle_level <= 0:
		return
	var blink: Sprite2D = _parts.blink
	var blinking := create_tween().set_loops()
	blinking.tween_interval(BLINK_EVERY)
	blinking.tween_callback(func() -> void: blink.visible = true)
	blinking.tween_interval(BLINK_TIME)
	blinking.tween_callback(func() -> void: blink.visible = false)
	_tweens.append(blinking)
	if idle_level < 2:
		return
	var body: Sprite2D = _parts.body
	var rest := body.scale
	var breathing := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathing.tween_property(body, "scale", Vector2(rest.x, rest.y * 1.035), 0.9)
	breathing.tween_property(body, "scale", rest, 0.9)
	_tweens.append(breathing)
	var tail: Sprite2D = _parts.tail
	var wagging := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	wagging.tween_property(tail, "rotation", 0.18, 0.7)
	wagging.tween_property(tail, "rotation", -0.1, 0.7)
	_tweens.append(wagging)


func _stop_idle() -> void:
	for tween in _tweens:
		tween.kill()
	_tweens.clear()
