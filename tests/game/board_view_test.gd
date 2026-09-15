extends GdUnitTestSuite

const QualityScript := preload("res://game/autoload/quality.gd")

var _quality: Node


func before_test() -> void:
	_quality = auto_free(QualityScript.new())
	add_child(_quality)
	_quality.set_mode(&"high")


func after_test() -> void:
	Engine.max_fps = 0


func _session(rng_seed: int = 1) -> M3Session:
	var level := M3LevelDef.new()
	level.rng_seed = rng_seed
	level.moves = 50
	level.goals[1] = 999
	return M3Session.new(level)


func _view(session: M3Session) -> BoardView:
	var view: BoardView = auto_free(BoardView.new())
	view.animate = false
	view.quality = _quality
	view.size = Vector2(700, 700)
	add_child(view)
	view.setup(session.board)
	return view


func _play_first_move(session: M3Session, view: BoardView) -> void:
	var move: Vector2i = M3MoveFinder.find_moves(session.board)[0]
	await view.play(session.swap(session.board.pos(move.x), session.board.pos(move.y)))


func _press(at: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	return event


func _motion(at: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = at
	return event


func _tap(view: BoardView, i: int) -> void:
	view._gui_input(_press(view.cell_center(i), true))
	view._gui_input(_press(view.cell_center(i), false))


func test_setup_shows_one_tile_per_cell() -> void:
	var session := _session()
	var view := _view(session)
	assert_int(view.active_tile_count()).is_equal(49)
	assert_bool(view.tiles_match_board()).is_true()


func test_swap_playback_keeps_tiles_in_sync() -> void:
	var session := _session()
	var view := _view(session)
	await _play_first_move(session, view)
	assert_bool(view.tiles_match_board()).is_true()
	assert_bool(view.busy).is_false()


func test_many_moves_do_not_grow_the_tile_pool() -> void:
	var session := _session(5)
	var view := _view(session)
	var pooled := view.pooled_tile_count()
	for turn in 15:
		await _play_first_move(session, view)
	assert_int(view.pooled_tile_count()).is_equal(pooled)
	assert_bool(view.tiles_match_board()).is_true()


func test_booster_playback_keeps_tiles_in_sync() -> void:
	var session := _session()
	var view := _view(session)
	await view.play(session.use_booster(M3.BOOSTER_ROW, Vector2i(3, 3)))
	assert_bool(view.tiles_match_board()).is_true()


func test_shuffle_playback_keeps_tiles_in_sync() -> void:
	var session := _session()
	var view := _view(session)
	await view.play(session.use_booster(M3.BOOSTER_SHUFFLE, Vector2i.ZERO))
	assert_bool(view.tiles_match_board()).is_true()


func test_high_quality_emits_particles() -> void:
	var session := _session()
	var view := _view(session)
	await _play_first_move(session, view)
	assert_int(view.particle_bursts()).is_greater(0)


func test_low_quality_emits_no_particles() -> void:
	_quality.set_mode(&"low")
	var session := _session()
	var view := _view(session)
	await _play_first_move(session, view)
	assert_int(view.particle_bursts()).is_equal(0)


func test_cell_lookup_matches_cell_centers() -> void:
	var session := _session()
	var view := _view(session)
	for i in [0, 10, 48]:
		assert_that(view.cell_at(view.cell_center(i))).is_equal(session.board.pos(i))


func test_drag_right_requests_a_swap() -> void:
	var view := _view(_session())
	var got := []
	view.swap_requested.connect(func(a: Vector2i, b: Vector2i) -> void: got.append([a, b]))
	var start := view.cell_center(0)
	view._gui_input(_press(start, true))
	view._gui_input(_motion(start + Vector2(view.cell_size() * 0.6, 0)))
	assert_array(got).is_equal([[Vector2i(0, 0), Vector2i(1, 0)]])


func test_finger_lifted_during_animation_ends_the_gesture() -> void:
	var view := _view(_session())
	var got := []
	view.swap_requested.connect(func(a: Vector2i, b: Vector2i) -> void: got.append([a, b]))
	var start := view.cell_center(0)
	view._gui_input(_press(start, true))
	view._gui_input(_motion(start + Vector2(view.cell_size() * 0.6, 0)))
	view.busy = true
	view._gui_input(_press(start + Vector2(view.cell_size(), 0), false))
	view.busy = false
	_tap(view, 24)
	_tap(view, 25)
	assert_array(got).is_equal([[Vector2i(0, 0), Vector2i(1, 0)], [Vector2i(3, 3), Vector2i(4, 3)]])


func test_tapping_two_neighbours_requests_a_swap() -> void:
	var view := _view(_session())
	var got := []
	view.swap_requested.connect(func(a: Vector2i, b: Vector2i) -> void: got.append([a, b]))
	_tap(view, 8)
	_tap(view, 15)
	assert_array(got).is_equal([[Vector2i(1, 1), Vector2i(1, 2)]])


func _obstacle_session(layout: Array, sacks: int = 0) -> M3Session:
	var level := M3LevelDef.new()
	level.rng_seed = 9
	level.moves = 60
	level.goals[1] = 999
	level.layout = PackedStringArray(layout)
	level.sacks = sacks
	return M3Session.new(level)


func test_obstacle_playback_stays_in_sync() -> void:
	var session := _obstacle_session([".......", "..2C2..", ".......", ".K.P.K.", "PPPPPPP", ".......", "......."], 4)
	var view := _view(session)
	assert_int(view.block_sprite_count()).is_equal(5)
	assert_int(view.active_tile_count()).is_equal(46)
	for turn in 25:
		var move := M3Bot.new(turn + 1).choose_move(session)
		if move == M3Bot.NO_MOVE:
			break
		await view.play(session.swap(session.board.pos(move.x), session.board.pos(move.y)))
	await view.play(session.use_booster(M3.BOOSTER_ROW, Vector2i(3, 1)))
	await view.play(session.use_booster(M3.BOOSTER_SHUFFLE, Vector2i.ZERO))
	assert_int(view.resyncs).is_equal(0)
	assert_bool(view.tiles_match_board()).is_true()


func test_hint_pulses_until_the_board_is_touched() -> void:
	var session := _session()
	var view := _view(session)
	view.show_hint(M3MoveFinder.find_moves(session.board)[0])
	assert_that(view.hint_move).is_not_equal(BoardView.NO_HINT)
	view._gui_input(_press(view.cell_center(0), true))
	assert_that(view.hint_move).is_equal(BoardView.NO_HINT)


func test_armed_booster_turns_taps_into_targets() -> void:
	var view := _view(_session())
	var swaps := []
	var taps := []
	view.swap_requested.connect(func(a: Vector2i, b: Vector2i) -> void: swaps.append([a, b]))
	view.cell_tapped.connect(func(cell: Vector2i) -> void: taps.append(cell))
	view.booster_armed = true
	_tap(view, 24)
	assert_array(taps).is_equal([Vector2i(3, 3)])
	assert_array(swaps).is_empty()
