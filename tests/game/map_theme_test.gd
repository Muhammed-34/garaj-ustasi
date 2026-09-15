extends GdUnitTestSuite

var _progress: Node


func before_test() -> void:
	_progress = get_tree().root.get_node("Progress")
	_progress.persist = false
	_progress.reset()


func after_test() -> void:
	_progress.reset()


func _map() -> Control:
	var map: Control = auto_free(load("res://game/scenes/map/map.tscn").instantiate())
	add_child(map)
	return map


func test_track_climbs_through_every_level() -> void:
	var map := _map()
	await get_tree().process_frame
	await get_tree().process_frame
	var centers: PackedVector2Array = map.level_centers()
	assert_int(centers.size()).is_equal(Levels.COUNT)
	for n in range(1, centers.size()):
		assert_float(centers[n].y).is_less(centers[n - 1].y)
	var track: PackedVector2Array = map.track_points()
	assert_int(track.size()).is_greater(Levels.COUNT)
	assert_float(track[0].y).is_greater(centers[0].y)


func test_level_nodes_use_the_theme_colors() -> void:
	var map := _map()
	var current: StyleBoxFlat = map.level_buttons[0].get_theme_stylebox("normal")
	assert_bool(current.bg_color.is_equal_approx(MapTheme.NODE_CURRENT)).is_true()
	var locked: StyleBoxFlat = map.level_buttons[1].get_theme_stylebox("disabled")
	assert_bool(locked.bg_color.is_equal_approx(MapTheme.NODE_LOCKED)).is_true()
	_progress.record_win(1, 10, 20)
	var done: StyleBoxFlat = map.level_buttons[0].get_theme_stylebox("normal")
	assert_bool(done.bg_color.is_equal_approx(MapTheme.NODE_DONE)).is_true()


func test_track_marks_are_evenly_spaced() -> void:
	var line := PackedVector2Array([Vector2.ZERO, Vector2(0, 100), Vector2(100, 100)])
	var marks := MapTheme.marks(line, 50.0)
	assert_int(marks.size()).is_equal(5)
	assert_bool((marks[3][0] as Vector2).is_equal_approx(Vector2(50, 100))).is_true()


func test_app_icon_is_the_rendered_scene() -> void:
	assert_str(str(ProjectSettings.get_setting("application/config/icon"))).is_equal("res://icon.png")
	for file in ["res://icon.png", "res://icon_foreground.png", "res://icon_background.png"]:
		assert_bool(ResourceLoader.exists(file)).override_failure_message("%s is missing" % file).is_true()
