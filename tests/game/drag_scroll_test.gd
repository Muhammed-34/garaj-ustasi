extends GdUnitTestSuite

const ROWS := 12
const ROW_HEIGHT := 100.0

var _taps: Array = []


func _list() -> DragScroll:
	_taps.clear()
	var scroll: DragScroll = auto_free(DragScroll.new())
	scroll.size = Vector2(400, 300)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	scroll.add_child(column)
	for n in ROWS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(380, ROW_HEIGHT)
		button.pressed.connect(func() -> void: _taps.append(n))
		column.add_child(button)
	add_child(scroll)
	return scroll


func _press(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	event.global_position = at
	get_viewport().push_input(event, true)


func _drag_to(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(event, true)


func test_short_tap_still_presses_a_button() -> void:
	var scroll := _list()
	await await_idle_frame()
	_press(Vector2(200, 50), true)
	_press(Vector2(200, 50), false)
	assert_array(_taps).is_equal([0])
	assert_int(scroll.scroll_vertical).is_equal(0)


func test_drag_that_starts_on_a_button_scrolls_without_pressing_it() -> void:
	var scroll := _list()
	await await_idle_frame()
	_press(Vector2(200, 250), true)
	for y in [230, 180, 120, 50]:
		_drag_to(Vector2(200, y))
	_press(Vector2(200, 50), false)
	assert_int(scroll.scroll_vertical).is_between(180, 220)
	assert_array(_taps).is_empty()


func test_list_stays_put_behind_an_open_popup() -> void:
	var scroll := _list()
	var popup: ColorRect = auto_free(ColorRect.new())
	popup.add_to_group(UiKit.MODAL_GROUP)
	add_child(popup)
	await await_idle_frame()
	_press(Vector2(200, 250), true)
	_drag_to(Vector2(200, 50))
	_press(Vector2(200, 50), false)
	assert_int(scroll.scroll_vertical).is_equal(0)
