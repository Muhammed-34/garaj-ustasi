extends GdUnitTestSuite

var _progress: Node
var _router: Node


func before_test() -> void:
	_progress = get_tree().root.get_node("Progress")
	_progress.persist = false
	_progress.reset()
	# Level 1 opens with the basics card; most tests start from an already-seen intro.
	_progress.data.intros_seen.append("basics")
	_router = get_tree().root.get_node("Router")
	_router.params = {"level_id": 1}


func after_test() -> void:
	_progress.reset()
	_router.params = {}
	Engine.max_fps = 0


func _game() -> Control:
	var game: Control = auto_free(load("res://game/scenes/game/game.tscn").instantiate())
	add_child(game)
	return game


# Completes every goal and serves every table, so the next end check wins.
func _finish(game: Control) -> void:
	game.session.goals.clear()
	for order in game.session.orders:
		order.state = M3Session.ORDER_SERVED


func _lose(game: Control) -> void:
	game.session.moves_left = 0
	game._check_end()


func test_game_starts_the_requested_level() -> void:
	_router.params = {"level_id": 3}
	var game := _game()
	assert_int(game.level.id).is_equal(3)
	assert_int(game.session.moves_left).is_equal(Levels.load_level(3).moves)
	assert_int(game.board_view.active_tile_count()).is_equal(49)


func test_tiles_and_boosters_use_atlas_art() -> void:
	var game := _game()
	assert_object(game.board_view.textures[1]).is_instanceof(AtlasTexture)
	for button in game._booster_buttons.values():
		assert_object(button.icon).is_not_null()


func _play_one_move(game: Control) -> void:
	game.board_view.animate = false
	var move: Vector2i = M3MoveFinder.find_moves(game.session.board)[0]
	await game._on_swap_requested(game.session.board.pos(move.x), game.session.board.pos(move.y))


func test_retrying_a_lost_level_empties_a_bowl() -> void:
	var game := _game()
	await _play_one_move(game)
	_lose(game)
	assert_int(_progress.bowls()).is_equal(MetaRules.MAX_BOWLS)
	assert_str(game._end_detail.text).contains("bidonu boşalır")
	game._on_primary()
	assert_int(_progress.bowls()).is_equal(MetaRules.MAX_BOWLS - 1)
	assert_int(game.session.moves_left).is_equal(game.level.moves)


func test_coin_continue_that_wins_costs_no_bowl() -> void:
	_progress.data.coins = 300
	var game := _game()
	await _play_one_move(game)
	_lose(game)
	game._on_coin_continue()
	_finish(game)
	game.session.moves_left = 0
	game._check_end()
	assert_int(_progress.bowls()).is_equal(MetaRules.MAX_BOWLS)
	assert_int(int(_progress.data.bowls.open_level)).is_equal(0)


func test_replaying_a_won_level_on_the_last_bowl_is_free() -> void:
	for n in MetaRules.MAX_BOWLS - 1:
		_progress.spend_bowl()
	var game := _game()
	await _play_one_move(game)
	_finish(game)
	game.session.moves_left = 0
	game._check_end()
	assert_str(str(game.end_state())).is_equal("win")
	game._on_secondary()
	assert_int(_progress.bowls()).is_equal(1)
	assert_int(int(_progress.data.bowls.open_level)).is_equal(0)
	assert_int(game.session.moves_left).is_equal(game.level.moves)


func test_restarting_before_any_move_is_free() -> void:
	var game := _game()
	game.open_pause()
	assert_str(game._pause_note.text).contains("ücretsiz")
	game._on_pause_restart()
	assert_int(_progress.bowls()).is_equal(MetaRules.MAX_BOWLS)


func test_restarting_after_a_move_costs_a_bowl() -> void:
	var game := _game()
	await _play_one_move(game)
	game.open_pause()
	assert_str(game._pause_note.text).contains("bidonu boşalır")
	game._on_pause_restart()
	assert_int(_progress.bowls()).is_equal(MetaRules.MAX_BOWLS - 1)


func _order_game(orders: Array) -> Control:
	var game := _game()
	# Replace the level's own orders and goals so each test controls every table.
	game.level.orders.clear()
	game.level.goals.clear()
	for order in orders:
		game.level.orders.append(order)
	game.session = M3Session.new(game.level)
	game.board_view.setup(game.session.board)
	game._build_orders()
	game._build_goals()
	game._refresh_goals(game.session.goals)
	return game


func test_order_cards_show_tables_ingredients_and_patience() -> void:
	var game := _order_game([{"dish": "kupa", "goals": {1: 4, 2: 2}, "patience": 12}, {"dish": "skuter", "goals": {4: 3}, "patience": 9}])
	assert_int(game._order_cards.size()).is_equal(2)
	assert_str(game._order_cards[0].card.get_child(0).get_child(1).get_child(0).text).is_equal("İŞ 1 · Kırmızı Kupa")
	assert_str(game._order_cards[0].items[1].count.text).is_equal("0/4")
	assert_str(game._order_cards[1].patience.text).is_equal("9")
	game.session.orders[0].need[1] = 1
	game.session.orders[1].patience = 2
	game._refresh_orders()
	assert_str(game._order_cards[0].items[1].count.text).is_equal("3/4")
	assert_object(game._order_cards[1].patience.get_theme_color("font_color")).is_equal(UiKit.DANGER)


func test_order_card_stays_one_compact_row() -> void:
	var game := _order_game([{"dish": "kupa", "goals": {1: 8, 2: 6}, "patience": 20}])
	await get_tree().process_frame
	await get_tree().process_frame
	var card: Control = game._order_cards[0].card
	assert_float(card.size.y).override_failure_message("order card is %s tall" % card.size.y).is_less(140.0)
	var patience: Label = game._order_cards[0].patience
	assert_int(patience.get_line_count()).is_equal(1)


func test_served_order_shows_on_its_card_and_wins_with_its_dish() -> void:
	var game := _order_game([{"dish": "pikap", "goals": {3: 1}, "patience": 20}])
	game.session.orders[0].need[3] = 0
	game.session.orders[0].state = M3Session.ORDER_SERVED
	game._refresh_orders()
	assert_str(game._order_cards[0].status.text).is_equal("Teslim edildi")
	game.session.moves_left = 0
	game._check_end()
	assert_str(str(game.end_state())).is_equal("win")
	assert_str(game._end_title.text).is_equal("Yeşil Pikap hazır!")


func test_table_running_out_of_patience_explains_the_loss() -> void:
	_progress.data.coins = 300
	var game := _order_game([{"dish": "kupa", "goals": {1: 99}, "patience": 1}])
	game.session.orders[0].patience = 0
	game._check_end()
	assert_str(game._end_title.text).is_equal("Müşteri gitti")
	assert_str(game._end_detail.text).contains("Müşteri 1")
	game._on_coin_continue()
	assert_int(game.session.orders[0].patience).is_equal(_progress.CONTINUE_MOVES)
	assert_bool(game.session.is_finished()).is_false()


func test_game_knows_when_every_bowl_is_empty() -> void:
	var game := _game()
	assert_bool(game.out_of_bowls()).is_false()
	for n in MetaRules.MAX_BOWLS:
		_progress.spend_bowl()
	assert_bool(game.out_of_bowls()).is_true()


func test_using_a_booster_starts_the_attempt() -> void:
	var game := _game()
	game.board_view.animate = false
	await game._use_booster(M3.BOOSTER_SHUFFLE, Vector2i.ZERO)
	assert_int(int(_progress.data.bowls.open_level)).is_equal(1)
	game.open_pause()
	assert_str(game._pause_note.text).contains("bidonu boşalır")
	game.fail_attempt()
	assert_int(_progress.bowls()).is_equal(MetaRules.MAX_BOWLS - 1)


func test_buying_or_arming_a_booster_is_still_free() -> void:
	_progress.data.coins = 400
	_progress.data.boosters.single = 0
	var game := _game()
	game._on_booster_pressed(M3.BOOSTER_SINGLE)
	game._confirm_yes.pressed.emit()
	assert_int(_progress.booster_stock(M3.BOOSTER_SINGLE)).is_equal(1)
	game._on_booster_pressed(M3.BOOSTER_SINGLE)
	game._on_booster_pressed(M3.BOOSTER_SINGLE)
	assert_int(int(_progress.data.bowls.open_level)).is_equal(0)
	game.open_pause()
	assert_str(game._pause_note.text).contains("ücretsiz")
	game.fail_attempt()
	assert_int(_progress.bowls()).is_equal(MetaRules.MAX_BOWLS)


func test_booster_on_a_cell_starts_the_attempt() -> void:
	var game := _game()
	game.board_view.animate = false
	game._on_booster_pressed(M3.BOOSTER_SINGLE)
	await game._on_cell_tapped(Vector2i(3, 3))
	assert_int(int(_progress.data.bowls.open_level)).is_equal(1)
	assert_int(_progress.booster_stock(M3.BOOSTER_SINGLE)).is_equal(2)


func test_pause_menu_opens_and_resumes() -> void:
	var game := _game()
	game.pause_button.pressed.emit()
	assert_bool(game.pause_visible()).is_true()
	game.close_pause()
	assert_bool(game.pause_visible()).is_false()
	assert_bool(game._overlay.visible).is_false()


func test_pause_restart_starts_the_level_over() -> void:
	var game := _game()
	var move: Vector2i = M3MoveFinder.find_moves(game.session.board)[0]
	game.session.swap(game.session.board.pos(move.x), game.session.board.pos(move.y))
	game.open_pause()
	game._on_pause_restart()
	assert_int(game.session.moves_left).is_equal(game.level.moves)
	assert_bool(game.pause_visible()).is_false()


func test_pause_toggles_change_settings() -> void:
	var game := _game()
	game.open_pause()
	game._pause_sound.pressed.emit()
	assert_bool(_progress.setting("sound")).is_false()
	assert_str(game._pause_sound.text).contains("Kapalı")


func test_back_button_opens_then_closes_pause() -> void:
	var game := _game()
	game.handle_back()
	assert_bool(game.pause_visible()).is_true()
	game.handle_back()
	assert_bool(game.pause_visible()).is_false()


func test_leaving_the_app_pauses_the_game() -> void:
	var game := _game()
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_bool(game.pause_visible()).is_true()


func test_pause_is_not_offered_after_the_level_ends() -> void:
	var game := _game()
	_finish(game)
	game.session.moves_left = 0
	game._check_end()
	game.open_pause()
	assert_bool(game.pause_visible()).is_false()


func test_shaped_board_view_stays_in_sync_after_a_move() -> void:
	_router.params = {"level_id": 54}
	var game := _game()
	assert_bool(game.session.board.has_holes()).is_true()
	assert_int(game.board_view.block_sprite_count()).is_equal(0)
	await _play_one_move(game)
	assert_bool(game.board_view.tiles_match_board()).is_true()
	assert_int(game.board_view.resyncs).is_equal(0)


func test_mice_view_stays_in_sync_after_a_move() -> void:
	_router.params = {"level_id": 45}
	var game := _game()
	assert_int(game.board_view.mouse_sprite_count()).is_equal(game.session.board.mice.count(1))
	await _play_one_move(game)
	assert_bool(game.board_view.tiles_match_board()).is_true()
	assert_int(game.board_view.resyncs).is_equal(0)
	assert_int(game.board_view.mouse_sprite_count()).is_equal(game.session.board.mice.count(1))


func test_obstacle_goals_have_icons() -> void:
	var game := _game()
	for key in game.GOAL_ART:
		assert_object(game._goal_texture(key)).is_not_null()
	assert_object(game._goal_texture(M3.SACK)).is_not_null()


func test_new_mechanic_intro_shows_once() -> void:
	var game := _game()
	game.level.intro = "box"
	assert_bool(game._maybe_show_intro()).is_true()
	assert_bool(game.intro_visible()).is_true()
	game._on_intro_done()
	assert_bool(game.intro_visible()).is_false()
	assert_bool(_progress.intro_seen("box")).is_true()
	assert_bool(game._maybe_show_intro()).is_false()


func test_first_level_explains_the_basics() -> void:
	_progress.data.intros_seen.clear()
	var game := _game()
	assert_bool(game.intro_visible()).is_true()
	assert_bool(game._intro_tile.visible).is_true()


func test_idle_player_gets_a_hint() -> void:
	var game := _game()
	game.board_view.animate = false
	game._process(10.0)
	assert_that(game.board_view.hint_move).is_not_equal(BoardView.NO_HINT)


func test_winning_records_progress_and_shows_stars() -> void:
	var game := _game()
	_finish(game)
	game.session.moves_left = 0
	game._check_end()
	assert_str(str(game.end_state())).is_equal("win")
	assert_bool(game._overlay.visible).is_true()
	assert_bool(_progress.is_unlocked(2)).is_true()
	assert_int(_progress.coins()).is_greater(_progress.START_COINS)
	assert_str(game._primary.text).is_equal("Devam")


func test_leftover_moves_throw_a_kitchen_party() -> void:
	var game := _game()
	game.board_view.animate = false
	_finish(game)
	game.session.moves_left = 4
	await game._on_won()
	assert_str(str(game.end_state())).is_equal("win")
	assert_int(int(game.result.party_coins)).is_equal(4 * MetaRules.PARTY_COINS)
	assert_int(game.session.moves_left).is_equal(0)
	assert_str(game._moves_label.text).is_equal("0")
	assert_bool(game.board_view.tiles_match_board()).is_true()


func test_first_win_on_a_recipe_level_adds_it_to_the_book() -> void:
	_router.params = {"level_id": MetaRules.recipe_unlock_level(1)}
	var game := _game()
	_finish(game)
	game.session.moves_left = 0
	game._check_end()
	assert_str(game._end_detail.text).contains("Mavi Skuter galeriye eklendi")
	var again := _game()
	_finish(again)
	again.session.moves_left = 0
	again._check_end()
	assert_str(again._end_detail.text).not_contains("galeriye")


func test_losing_offers_coin_continue_only_when_affordable() -> void:
	_progress.data.coins = 300
	var rich := _game()
	_lose(rich)
	assert_str(str(rich.end_state())).is_equal("lose")
	assert_bool(rich._continue_coins.visible).is_true()
	_progress.data.coins = 100
	var poor := _game()
	_lose(poor)
	assert_bool(poor._continue_coins.visible).is_false()


func test_coin_continue_adds_moves_once() -> void:
	_progress.data.coins = 300
	var game := _game()
	_lose(game)
	game._on_coin_continue()
	assert_int(game.session.moves_left).is_equal(_progress.CONTINUE_MOVES)
	assert_int(_progress.coins()).is_equal(50)
	assert_bool(game._overlay.visible).is_false()
	_progress.data.coins = 1000
	_lose(game)
	assert_bool(game._continue_coins.visible).is_false()


func test_ad_continue_stays_hidden_while_ads_are_off() -> void:
	var game := _game()
	_lose(game)
	assert_bool(game._continue_ad.visible).is_false()


func test_empty_booster_can_be_bought_with_coins() -> void:
	_progress.data.boosters.row = 0
	_progress.data.coins = 400
	var game := _game()
	game._on_booster_pressed(M3.BOOSTER_ROW)
	assert_bool(game._confirm_panel.visible).is_true()
	game._confirm_yes.pressed.emit()
	assert_int(_progress.booster_stock(M3.BOOSTER_ROW)).is_equal(1)
	assert_int(_progress.coins()).is_equal(100)


func test_empty_booster_without_coins_only_explains() -> void:
	_progress.data.boosters.row = 0
	_progress.data.coins = 10
	var game := _game()
	game._on_booster_pressed(M3.BOOSTER_ROW)
	assert_bool(game._confirm_no.visible).is_false()
	game._confirm_yes.pressed.emit()
	assert_int(_progress.coins()).is_equal(10)
