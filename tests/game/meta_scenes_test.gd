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


func _win_recipes(count: int) -> void:
	for n in count:
		_progress.record_win(MetaRules.recipe_unlock_level(n), 5, 20)


func test_empty_recipe_book_shows_where_each_recipe_opens() -> void:
	var book := _scene("res://game/scenes/recipes/recipes.tscn")
	assert_int(book.cards.size()).is_equal(MetaRules.RECIPES.size())
	assert_int(book.unlocked_count()).is_equal(0)
	assert_object(book.dish_images[0].texture).is_equal(ArtAtlas.texture("dish_locked"))
	assert_str(book.restaurant_label.text).is_equal(MetaRules.RESTAURANTS[0].name)
	assert_str(book.next_label.text).contains("4 araç kaldı")


func test_won_recipe_levels_fill_the_book() -> void:
	_win_recipes(2)
	var book := _scene("res://game/scenes/recipes/recipes.tscn")
	assert_int(book.unlocked_count()).is_equal(2)
	assert_object(book.dish_images[1].texture).is_equal(ArtAtlas.texture("dish_%s" % MetaRules.RECIPES[1].id))
	assert_object(book.dish_images[2].texture).is_equal(ArtAtlas.texture("dish_locked"))


func test_recipe_cards_line_up_whether_locked_or_not() -> void:
	_win_recipes(1)
	var book := _scene("res://game/scenes/recipes/recipes.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(book.cards[0].size.y).is_equal(book.cards[1].size.y)


func test_restaurant_grows_with_the_book() -> void:
	_win_recipes(4)
	var book := _scene("res://game/scenes/recipes/recipes.tscn")
	assert_str(book.restaurant_label.text).is_equal(MetaRules.RESTAURANTS[1].name)
	_win_recipes(MetaRules.RECIPES.size())
	var full := _scene("res://game/scenes/recipes/recipes.tscn")
	assert_str(full.restaurant_label.text).is_equal(MetaRules.RESTAURANTS.back().name)
	assert_str(full.next_label.text).contains("en yüksek")


func test_every_recipe_has_dish_art() -> void:
	for recipe in MetaRules.RECIPES:
		assert_bool(ArtAtlas.has_sprite("dish_%s" % recipe.id)).is_true()
	assert_bool(ArtAtlas.has_sprite("dish_locked")).is_true()
	assert_bool(ArtAtlas.has_sprite("fuel")).is_true()


func test_map_marker_shows_the_won_dish() -> void:
	var first := MetaRules.recipe_unlock_level(0)
	var second := MetaRules.recipe_unlock_level(1)
	var map := _scene("res://game/scenes/map/map.tscn")
	assert_int(map.recipe_markers.size()).is_equal(MetaRules.RECIPES.size())
	assert_object(map.recipe_markers[first].texture).is_equal(ArtAtlas.texture("dish_locked"))
	_progress.record_win(first, 5, 20)
	assert_object(map.recipe_markers[first].texture).is_equal(ArtAtlas.texture("dish_kupa"))
	assert_object(map.recipe_markers[second].texture).is_equal(ArtAtlas.texture("dish_locked"))


func test_map_lives_are_fuel_cans() -> void:
	var map := _scene("res://game/scenes/map/map.tscn")
	assert_object(map.bowl_icons[0].texture).is_equal(ArtAtlas.texture("fuel"))
	assert_str(map._bowl_label.text).is_equal("Depo dolu")
	assert_str(map.recipes_button.text).is_equal("Galeri")


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


func test_back_closes_an_open_popup_before_leaving() -> void:
	var map := _scene("res://game/scenes/map/map.tscn")
	assert_bool(UiKit.close_open_popup(map)).is_false()
	map.open_calendar()
	assert_bool(UiKit.close_open_popup(map)).is_true()
	assert_bool(map.calendar_visible()).is_false()
