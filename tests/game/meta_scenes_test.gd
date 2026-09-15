extends GdUnitTestSuite

var _progress: Node
var _router: Node


func before_test() -> void:
	_progress = get_tree().root.get_node("Progress")
	_progress.persist = false
	_progress.reset()
	_router = get_tree().root.get_node("Router")


func after_test() -> void:
	_progress.reset()
	_router.params = {}
	Engine.max_fps = 0


func _scene(path: String) -> Control:
	var scene: Control = auto_free(load(path).instantiate())
	add_child(scene)
	return scene


func _add_cats(count: int) -> void:
	for n in count:
		_progress.data.cats.append(MetaRules.new_cat(n + 1, n, "Kedi%d" % n, 3))
	_progress.changed.emit()


func test_rescue_screen_names_and_saves_the_cat() -> void:
	_progress.record_win(5, 5, 20)
	_router.params = {"level_id": 5}
	var rescue := _scene("res://game/scenes/rescue/rescue.tscn")
	assert_int(rescue.suggestion_buttons.size()).is_equal(3)
	rescue.suggestion_buttons[1].pressed.emit()
	var chosen: String = rescue.name_input.text
	assert_str(chosen).is_not_empty()
	rescue.save_rescue()
	assert_str(str(_progress.cats()[0].name)).is_equal(chosen)
	assert_int(rescue.cat_rig.part_count()).is_greater(0)


func test_empty_shelter_explains_where_the_first_cat_is() -> void:
	var shelter := _scene("res://game/scenes/shelter/shelter.tscn")
	assert_int(shelter.cat_buttons.size()).is_equal(0)
	assert_int(shelter.room_rigs.size()).is_equal(0)
	assert_str(shelter._room_lock.text).contains("%d. bölümde" % MetaRules.RESCUE_LEVELS[0])


func test_empty_shelter_points_to_a_waiting_cat() -> void:
	_progress.record_win(MetaRules.RESCUE_LEVELS[0], 5, 20)
	var shelter := _scene("res://game/scenes/shelter/shelter.tscn")
	assert_str(shelter._room_lock.text).contains("seni bekliyor")
	assert_str(shelter._room_lock.text).not_contains("bölümde")


func test_back_while_typing_a_name_only_closes_the_keyboard() -> void:
	_progress.record_win(MetaRules.RESCUE_LEVELS[0], 5, 20)
	_router.params = {"level_id": MetaRules.RESCUE_LEVELS[0]}
	var rescue := _scene("res://game/scenes/rescue/rescue.tscn")
	rescue.name_input.grab_focus()
	rescue.name_input.text = "Mi"
	rescue.handle_back()
	assert_bool(rescue.name_input.has_focus()).is_false()
	assert_int(_progress.cats().size()).is_equal(0)


func test_shelter_fills_rooms_four_at_a_time() -> void:
	_add_cats(5)
	var shelter := _scene("res://game/scenes/shelter/shelter.tscn")
	assert_int(shelter.cat_buttons.size()).is_equal(5)
	assert_int(shelter.room_rigs.size()).is_equal(4)
	shelter.show_room(1)
	assert_int(shelter.room_rigs.size()).is_equal(1)
	shelter.show_room(2)
	assert_int(shelter.room_rigs.size()).is_equal(0)


func test_newly_opened_empty_room_says_it_awaits_friends() -> void:
	_add_cats(8)
	var shelter := _scene("res://game/scenes/shelter/shelter.tscn")
	shelter.show_room(2)
	assert_bool(shelter._room_backdrop.locked).is_false()
	assert_int(shelter.room_rigs.size()).is_equal(0)
	assert_bool(shelter._room_lock.visible).is_true()
	assert_str(shelter._room_lock.text).contains("yeni dostlarını bekliyor")
	await get_tree().process_frame
	await get_tree().process_frame
	var stage: Rect2 = shelter._room_stage.get_global_rect()
	var note: Rect2 = shelter._room_lock.get_global_rect()
	assert_bool(stage.encloses(note)).override_failure_message("note %s outside room %s" % [note, stage]).is_true()
	assert_float(note.size.x).is_less(stage.size.x * 0.9)
	shelter.show_room(1)
	assert_bool(shelter._room_lock.visible).is_false()


func test_low_quality_shelter_cats_do_not_animate() -> void:
	_progress.set_setting("quality", "low")
	_add_cats(2)
	var shelter := _scene("res://game/scenes/shelter/shelter.tscn")
	for rig in shelter.room_rigs:
		assert_int(rig.active_animation_count()).is_equal(0)


func test_favorite_is_toggled_from_the_detail_card() -> void:
	_add_cats(1)
	var shelter := _scene("res://game/scenes/shelter/shelter.tscn")
	shelter.cat_buttons[0].pressed.emit()
	assert_bool(shelter.detail_visible()).is_true()
	shelter.toggle_favorite()
	assert_bool(_progress.cats()[0].favorite).is_true()


func test_adopted_cats_leave_the_shelter_and_letters_are_read() -> void:
	_add_cats(2)
	_progress.data.stars["60"] = 1
	_progress.adopt_cat("cat_1", "2020-01-01")
	var shelter := _scene("res://game/scenes/shelter/shelter.tscn")
	assert_int(shelter.cat_buttons.size()).is_equal(1)
	shelter.open_mail()
	assert_int(shelter.shown_letters()).is_equal(1)
	assert_int(_progress.unread_mail_count()).is_equal(0)


func test_each_room_has_its_own_scenery() -> void:
	var styles := {}
	for n in MetaRules.ROOM_NAMES.size():
		styles[RoomBackdrop.style_for(n)] = true
	assert_int(styles.size()).is_equal(MetaRules.ROOM_NAMES.size())
	_add_cats(9)
	var shelter := _scene("res://game/scenes/shelter/shelter.tscn")
	shelter.show_room(2)
	assert_int(shelter._room_backdrop.room_index).is_equal(2)


func test_winter_garden_plants_stay_inside_and_behind_the_cats() -> void:
	var stage := Vector2(980, 330)
	var cat_top: float = RoomBackdrop.FLOOR_Y
	for slot in load("res://game/scenes/shelter/shelter.gd").SLOTS:
		cat_top = minf(cat_top, slot.y - 150.0 / stage.y)
	for x in RoomBackdrop.SHELF_PLANTS:
		var reach: float = RoomBackdrop.PLANT_REACH * RoomBackdrop.PLANT_SCALE * stage.y / stage.x
		assert_float(x - reach).is_greater(0.0)
		assert_float(x + reach).is_less(1.0)
	assert_float(RoomBackdrop.SHELF_Y).is_less_equal(cat_top + 0.05)


func test_locked_room_is_dimmed() -> void:
	_add_cats(5)
	var shelter := _scene("res://game/scenes/shelter/shelter.tscn")
	shelter.show_room(2)
	assert_bool(shelter._room_backdrop.locked).is_true()
	shelter.show_room(1)
	assert_bool(shelter._room_backdrop.locked).is_false()


func test_favorite_cards_show_a_heart() -> void:
	_add_cats(2)
	var shelter := _scene("res://game/scenes/shelter/shelter.tscn")
	_progress.set_favorite("cat_2", true)
	var hearts: Array = shelter.cat_buttons.map(func(button: Button) -> bool: return button.get_children().any(func(child: Node) -> bool: return child is HeartBadge))
	assert_array(hearts).is_equal([false, true])


func test_mail_window_fits_its_letters() -> void:
	_add_cats(1)
	_progress.data.stars["60"] = 1
	_progress.adopt_cat("cat_1", "2020-01-01")
	var shelter := _scene("res://game/scenes/shelter/shelter.tscn")
	shelter.open_mail()
	var height: float = shelter._mail_scroll.custom_minimum_size.y
	assert_float(height).is_greater(shelter.EMPTY_MAIL_HEIGHT)
	assert_float(height).is_less(shelter.MAIL_LIST_HEIGHT)


func test_back_closes_an_open_popup_before_leaving() -> void:
	_add_cats(1)
	var shelter := _scene("res://game/scenes/shelter/shelter.tscn")
	assert_bool(UiKit.close_open_popup(shelter)).is_false()
	shelter.open_mail()
	assert_bool(UiKit.close_open_popup(shelter)).is_true()
	assert_bool(UiKit.popup_root(shelter._mail_rows).visible).is_false()
	shelter.open_detail("cat_1")
	assert_bool(UiKit.close_open_popup(shelter)).is_true()
	assert_bool(shelter.detail_visible()).is_false()
	var map := _scene("res://game/scenes/map/map.tscn")
	map.open_calendar()
	assert_bool(UiKit.close_open_popup(map)).is_true()
	assert_bool(map.calendar_visible()).is_false()


func test_empty_mailbox_is_compact() -> void:
	var shelter := _scene("res://game/scenes/shelter/shelter.tscn")
	shelter.open_mail()
	assert_int(shelter.shown_letters()).is_equal(0)
	assert_float(shelter._mail_scroll.custom_minimum_size.y).is_less(200.0)


func test_newest_letter_is_listed_first() -> void:
	_add_cats(2)
	_progress.data.stars["60"] = 1
	_progress.adopt_cat("cat_1", "2020-01-01")
	_progress.adopt_cat("cat_2", "2020-01-05")
	var shelter := _scene("res://game/scenes/shelter/shelter.tscn")
	shelter.open_mail()
	var first: Label = shelter._mail_list.get_child(0).get_child(0)
	assert_str(first.text).contains("Kedi1")


func test_latest_of_same_day_letters_is_listed_first() -> void:
	_add_cats(3)
	_progress.data.stars["60"] = 1
	_progress.adopt_cat("cat_1", "2020-01-01")
	_progress.adopt_cat("cat_3", "2020-01-05")
	_progress.adopt_cat("cat_2", "2020-01-05")
	var shelter := _scene("res://game/scenes/shelter/shelter.tscn")
	shelter.open_mail()
	var names := []
	for card in shelter._mail_list.get_children():
		var text: String = card.get_child(0).text
		for cat_name in ["Kedi0", "Kedi1", "Kedi2"]:
			if text.contains(cat_name):
				names.append(cat_name)
	assert_array(names).is_equal(["Kedi1", "Kedi2", "Kedi0"])


func test_album_cards_line_up_with_or_without_the_home_badge() -> void:
	_add_cats(2)
	_progress.data.stars["60"] = 1
	_progress.adopt_cat("cat_2", "2020-01-01")
	var album := _scene("res://game/scenes/album/album.tscn")
	assert_float(album.home_badges["pamuk"].modulate.a).is_equal(1.0)
	assert_float(album.home_badges["tekir"].modulate.a).is_equal(0.0)
	# Card texts wrap, so heights are only meaningful once the grid has laid out at its real width.
	await get_tree().process_frame
	await get_tree().process_frame
	var heights := {}
	for breed in album.cards:
		var content: Control = album.cards[breed].get_child(0)
		heights[roundi(content.get_combined_minimum_size().y)] = breed
	assert_int(heights.size()).override_failure_message("content heights %s" % str(heights)).is_equal(1)


func test_album_shows_every_breed_and_counts_discoveries() -> void:
	_add_cats(3)
	var album := _scene("res://game/scenes/album/album.tscn")
	assert_int(album.cards.size()).is_equal(MetaRules.BREEDS.size())
	assert_int(album.discovered_count()).is_equal(3)


func test_map_calendar_claims_todays_gift() -> void:
	var map := _scene("res://game/scenes/map/map.tscn")
	map.open_calendar()
	assert_bool(map.calendar_visible()).is_true()
	var reward: Dictionary = map.claim_calendar()
	assert_int(int(reward.coins)).is_equal(50)
	assert_int(_progress.coins()).is_equal(_progress.START_COINS + 50)
	assert_bool(map.claim_calendar().is_empty()).is_true()


func test_finished_week_stays_claimed_until_tomorrow() -> void:
	_progress.data.calendar.index = 6
	_progress.data.calendar.last_claim = "2000-01-01"
	var map := _scene("res://game/scenes/map/map.tscn")
	map.open_calendar()
	assert_float(map.calendar_cells[6].modulate.a).is_equal(1.0)
	var reward: Dictionary = map.claim_calendar()
	assert_str(str(reward.booster)).is_equal("row")
	for cell in map.calendar_cells:
		assert_float(cell.modulate.a).is_less(1.0)


func test_map_marker_shows_the_rescued_friend() -> void:
	var first: int = MetaRules.RESCUE_LEVELS[0]
	var second: int = MetaRules.RESCUE_LEVELS[1]
	var map := _scene("res://game/scenes/map/map.tscn")
	assert_object(map.rescue_markers[first].texture).is_equal(ArtAtlas.texture("cat_silhouette"))
	_progress.record_win(first, 5, 20)
	var cat: Dictionary = _progress.rescue_cat(first, "Bulut")
	assert_object(map.rescue_markers[first].texture).is_equal(ArtAtlas.texture("cat_%s_face" % cat.breed))
	assert_object(map.rescue_markers[second].texture).is_equal(ArtAtlas.texture("cat_silhouette"))


func test_map_shelter_button_announces_a_waiting_cat() -> void:
	var map := _scene("res://game/scenes/map/map.tscn")
	_progress.record_win(5, 5, 20)
	assert_str(map.shelter_button.text).contains("yeni dost")
