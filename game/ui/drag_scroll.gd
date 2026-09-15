class_name DragScroll
extends ScrollContainer

# Touch-drag scrolling for lists full of buttons. Godot's own drag scrolling never sees a drag that starts
# on a child button, and that drag still counted as a tap when the finger lifted. This follows the gesture
# in _input instead: past DRAG_THRESHOLD it scrolls, cancels the button press and swallows the release.
const DRAG_THRESHOLD := 18.0
const FRICTION := 5.0
const MIN_FLING := 60.0
const FAR_AWAY := Vector2(-100000, -100000)

var dragging := false

var _pressed := false
var _press_pos := Vector2.ZERO
var _last_pos := Vector2.ZERO
var _last_time := 0
var _offset := 0.0
var _velocity := 0.0
var _glide: Tween


func _ready() -> void:
	set_process(false)


func _input(event: InputEvent) -> void:
	# Mouse events (emulated from touch on phones) drive the gesture; raw touch drags are only swallowed so
	# the built-in scrolling does not move the list a second time.
	if event is InputEventScreenDrag:
		if _pressed and event.index == 0:
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.position == FAR_AWAY:
			return
		if event.pressed:
			_begin(event.position)
		elif _pressed:
			_end()
	elif event is InputEventMouseMotion and _pressed and event.position != FAR_AWAY:
		_move(event.position)


func _process(delta: float) -> void:
	_velocity *= exp(-FRICTION * delta)
	_scroll_to(_offset + _velocity * delta)
	if absf(_velocity) < MIN_FLING:
		set_process(false)


func max_offset() -> float:
	var bar := get_v_scroll_bar()
	return maxf(bar.max_value - bar.page, 0.0)


# Scrolls to an offset with a short ease-out; a new touch on the list stops it.
func glide_to(offset: float, animate: bool = true) -> void:
	set_process(false)
	_velocity = 0.0
	_stop_glide()
	var target := clampf(offset, 0.0, max_offset())
	var duration := clampf(absf(target - scroll_vertical) / 4000.0, 0.2, 0.6)
	var quality := UiKit.autoload("Quality")
	if quality and quality.profile:
		duration = quality.duration(duration)
	if not animate or duration <= 0.01 or not is_inside_tree():
		_scroll_to(target)
		return
	_offset = target
	_glide = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_glide.tween_property(self, "scroll_vertical", int(target), duration)


func _stop_glide() -> void:
	if _glide:
		_glide.kill()
		_glide = null


func _begin(pos: Vector2) -> void:
	set_process(false)
	_velocity = 0.0
	_stop_glide()
	if not is_visible_in_tree() or not get_global_rect().has_point(pos) or _covered_by_modal():
		return
	_pressed = true
	dragging = false
	_press_pos = pos
	_last_pos = pos
	_last_time = Time.get_ticks_msec()
	_offset = scroll_vertical


func _move(pos: Vector2) -> void:
	if not dragging:
		if absf(pos.y - _press_pos.y) < DRAG_THRESHOLD:
			return
		dragging = true
		_cancel_child_press()
	var now := Time.get_ticks_msec()
	var dy := pos.y - _last_pos.y
	var dt := maxf((now - _last_time) / 1000.0, 0.001)
	_velocity = lerpf(_velocity, -dy / dt, 0.5)
	_last_pos = pos
	_last_time = now
	_scroll_to(_offset - dy)
	get_viewport().set_input_as_handled()


func _end() -> void:
	_pressed = false
	if not dragging:
		return
	dragging = false
	get_viewport().set_input_as_handled()
	if absf(_velocity) >= MIN_FLING:
		set_process(true)


# Moves the button's pointer off it and releases there, so the button resets without emitting pressed.
func _cancel_child_press() -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = FAR_AWAY
	motion.global_position = FAR_AWAY
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(motion, true)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = FAR_AWAY
	release.global_position = FAR_AWAY
	get_viewport().push_input(release, true)


func _scroll_to(offset: float) -> void:
	_offset = clampf(offset, 0.0, max_offset())
	scroll_vertical = int(_offset)


# Popups opened over this list take the touches; a list inside the popup itself still scrolls.
func _covered_by_modal() -> bool:
	for modal in get_tree().get_nodes_in_group(UiKit.MODAL_GROUP):
		if modal is CanvasItem and modal.is_visible_in_tree() and not modal.is_ancestor_of(self):
			return true
	return false
