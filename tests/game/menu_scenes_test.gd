extends GdUnitTestSuite

const MapScript := preload("res://game/scenes/map/map.gd")

var _progress: Node


func before_test() -> void:
	_progress = get_tree().root.get_node("Progress")
	_progress.persist = false
	_progress.reset()


func after_test() -> void:
	MapScript.last_opened_level = 0
	_progress.reset()
	_progress.apply_settings()
	Engine.max_fps = 0


func _scene(path: String) -> Control:
	var scene: Control = auto_free(load(path).instantiate())
	add_child(scene)
	return scene


func test_title_screen_shows_the_garage() -> void:
	var title := _scene("res://game/scenes/title/title.tscn")
	assert_object(title.car.texture).is_equal(ArtAtlas.texture("dish_kupa"))
	assert_str(title.play_button.text).is_equal("Oyna")
	assert_str(title.recipes_button.text).is_equal("Galeri")
	assert_bool(title.has_method("handle_back")).is_true()
	assert_str(title.garage.title_text).is_equal(MetaRules.GAME_NAME)
	await get_tree().process_frame
	await get_tree().process_frame
	var car: Rect2 = title.car.get_global_rect()
	assert_bool(car.intersects(title.play_button.get_global_rect())).override_failure_message("car %s covers the play button" % car).is_false()


func test_title_play_button_continues_from_the_next_level() -> void:
	_progress.record_win(1, 10, 20)
	var title := _scene("res://game/scenes/title/title.tscn")
	assert_str(title.play_button.text).is_equal("Devam et")
	assert_str(title.next_label.text).contains("2")


func test_tapping_the_title_car_makes_it_bounce() -> void:
	var title := _scene("res://game/scenes/title/title.tscn")
	title.honk()
	assert_int(title.honks).is_equal(1)
	assert_float(title.garage.shine).is_equal(1.0)


func test_map_offers_a_way_back_to_the_title() -> void:
	var map := _scene("res://game/scenes/map/map.tscn")
	assert_object(map.home_button).is_not_null()
	assert_str(map.home_button.text).is_equal("‹")


func test_beating_every_level_shows_the_finale() -> void:
	var map := _scene("res://game/scenes/map/map.tscn")
	assert_bool(map.finale_card.visible).is_false()
	for id in range(1, Levels.COUNT + 1):
		_progress.data.stars[str(id)] = 1
	_progress.data.unlocked = Levels.COUNT
	map._refresh()
	assert_bool(map.all_levels_done()).is_true()
	assert_bool(map.finale_card.visible).is_true()
	var title := _scene("res://game/scenes/title/title.tscn")
	assert_str(title.next_label.text).contains("bitirdin")


func test_map_lists_every_level() -> void:
	var map := _scene("res://game/scenes/map/map.tscn")
	assert_int(map.level_buttons.size()).is_equal(Levels.COUNT)


func test_new_player_can_only_open_the_first_level() -> void:
	var map := _scene("res://game/scenes/map/map.tscn")
	assert_bool(map.level_buttons[0].disabled).is_false()
	assert_bool(map.level_buttons[1].disabled).is_true()


func test_map_shows_stars_and_unlocks_after_a_win() -> void:
	var map := _scene("res://game/scenes/map/map.tscn")
	_progress.record_win(1, 10, 20)
	assert_bool(map.level_buttons[1].disabled).is_false()
	assert_int(map.shown_stars(1)).is_equal(3)
	assert_int(map.shown_stars(2)).is_equal(0)


func _map_at_level_18(last_opened: int) -> Control:
	for id in range(1, 18):
		_progress.data.stars[str(id)] = 3
	_progress.data.unlocked = 18
	_progress.data.calendar.last_claim = Time.get_date_string_from_system()
	MapScript.last_opened_level = last_opened
	var map := _scene("res://game/scenes/map/map.tscn")
	for n in 4:
		await get_tree().process_frame
	return map


func test_map_opens_at_the_next_level_without_history() -> void:
	var map: Control = await _map_at_level_18(0)
	assert_bool(map.is_level_on_screen(18)).is_true()
	assert_bool(map.next_button.visible).is_false()


func test_map_reopens_at_the_last_opened_level() -> void:
	var map: Control = await _map_at_level_18(3)
	assert_bool(map.is_level_on_screen(3)).is_true()
	assert_bool(map.is_level_on_screen(18)).is_false()
	assert_bool(map.next_button.visible).is_true()
	map.jump_to_next(false)
	assert_bool(map.is_level_on_screen(18)).is_true()
	assert_bool(map.next_button.visible).is_false()


func test_jump_to_level_one_keeps_its_stars_clear() -> void:
	var map: Control = await _map_at_level_18(0)
	assert_bool(map.bottom_button.visible).is_true()
	map.jump_to_bottom(false)
	assert_bool(map.is_level_on_screen(1)).is_true()
	# The scroll container moves its content on the next frame; measure screen positions after that.
	await get_tree().process_frame
	await get_tree().process_frame
	var stars: Control = map._star_rows[1]
	var stars_bottom := stars.get_global_rect().end.y
	assert_float(stars_bottom).is_less(map.next_button.get_global_rect().position.y)
	assert_bool(map.bottom_button.visible).is_false()
	assert_bool(map.next_button.visible).is_true()


func test_map_blocks_levels_while_every_bowl_is_empty() -> void:
	var map := _scene("res://game/scenes/map/map.tscn")
	assert_float(map.bowl_icons[0].modulate.a).is_equal(1.0)
	for n in MetaRules.MAX_BOWLS:
		_progress.spend_bowl()
	map._refresh_bowls()
	assert_float(map.bowl_icons[0].modulate.a).is_less(1.0)
	map._open_level(1)
	assert_bool(map.bowls_popup_visible()).is_true()
	assert_int(MapScript.last_opened_level).is_equal(0)
	_progress.data.coins = 100
	map._refresh_bowls()
	assert_bool(map.coins_short_label.visible).is_true()
	assert_str(map.coins_short_label.text).contains("100 / 300")
	_progress.data.coins = 400
	map._refresh_bowls()
	assert_bool(map.coins_short_label.visible).is_false()
	assert_bool(map.refill_bowls()).is_true()
	assert_bool(map.bowls_popup_visible()).is_false()
	assert_int(_progress.bowls()).is_equal(MetaRules.MAX_BOWLS)


func test_map_explains_a_bowl_lost_to_a_closed_app_once() -> void:
	_progress.bowl_lost_on_launch = true
	var map := _scene("res://game/scenes/map/map.tscn")
	assert_bool(map.bowl_lost_note_visible()).is_true()
	var again := _scene("res://game/scenes/map/map.tscn")
	assert_bool(again.bowl_lost_note_visible()).is_false()


func test_wait_is_shown_as_minutes_and_seconds() -> void:
	assert_str(MapScript.format_wait(29 * 60 + 5)).is_equal("29:05")
	assert_str(MapScript.format_wait(0)).is_equal("0:00")


func test_settings_quality_choice_is_saved() -> void:
	var settings := _scene("res://game/scenes/settings/settings.tscn")
	settings.select_quality(&"low")
	assert_str(str(_progress.setting("quality"))).is_equal("low")


func test_settings_toggles_are_saved() -> void:
	var settings := _scene("res://game/scenes/settings/settings.tscn")
	settings.reduce_motion_toggle.button_pressed = true
	settings.vibration_toggle.button_pressed = false
	assert_bool(_progress.setting("reduce_motion")).is_true()
	assert_bool(_progress.setting("vibration")).is_false()


func test_sound_toggle_mutes_audio() -> void:
	var settings := _scene("res://game/scenes/settings/settings.tscn")
	settings.sound_toggle.button_pressed = false
	assert_bool(_progress.setting("sound")).is_false()
	assert_bool(get_tree().root.get_node("Audio").enabled).is_false()


func test_licenses_include_godot_and_its_components() -> void:
	var licenses := _scene("res://game/scenes/licenses/licenses.tscn")
	var text: String = licenses.text_label.text
	assert_str(text).contains("Godot Engine")
	assert_str(text).contains("MIT")
	assert_str(text).contains(MetaRules.GAME_NAME)
	assert_str(text).contains("özgün İngilizce")
