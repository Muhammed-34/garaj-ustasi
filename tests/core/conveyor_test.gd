extends GdUnitTestSuite


func _board(rows: Array, layout: Array) -> M3Board:
	var board := M3Board.from_rows(PackedStringArray(rows))
	board.apply_layout(PackedStringArray(layout))
	return board


func _row(board: M3Board, y: int) -> Array:
	return Array(board.kinds.slice(y * board.width, (y + 1) * board.width))


func _level(layout: Array, goals: Dictionary) -> M3LevelDef:
	var level := M3LevelDef.new()
	level.layout = PackedStringArray(layout)
	level.moves = 30
	level.rng_seed = 11
	for key in goals:
		level.goals[key] = goals[key]
	return level


func _has_step(steps: Array, type: StringName) -> bool:
	for step in steps:
		if step.type == type:
			return true
	return false


func test_layout_marks_belts_without_closing_cells() -> void:
	var board := _board(["12345"], [">>.<<"])
	assert_array(Array(board.belts)).is_equal([1, 1, 0, -1, -1])
	assert_bool(board.is_open(0)).is_true()
	assert_bool(board.is_fixed(0)).is_false()


func test_right_belt_moves_tiles_one_cell_and_wraps() -> void:
	var board := _board(["12345", "21212"], [">>>>."])
	var moves := board.convey()
	assert_array(_row(board, 0)).is_equal([4, 1, 2, 3, 5])
	assert_array(_row(board, 1)).is_equal([2, 1, 2, 1, 2])
	assert_bool(moves.has(Vector2i(3, 0))).is_true()
	assert_int(moves.size()).is_equal(4)


func test_left_belt_moves_the_other_way() -> void:
	var board := _board(["12345"], ["<<<<<"])
	board.convey()
	assert_array(_row(board, 0)).is_equal([2, 3, 4, 5, 1])


func test_specials_ride_with_their_tiles() -> void:
	var board := _board(["12345"], [">>>>>"])
	board.specials[1] = M3.Special.BOMB
	board.convey()
	assert_int(board.specials[2]).is_equal(M3.Special.BOMB)
	assert_int(board.specials[1]).is_equal(M3.Special.NONE)


func test_obstacles_on_a_belt_stay_and_tiles_skip_them() -> void:
	var board := _board(["12345"], [">>>>>"])
	board.set_blocker(2, M3.Block.BOX, 1)
	board.convey()
	assert_array(_row(board, 0)).is_equal([5, 1, M3.EMPTY, 2, 4])
	assert_int(board.blockers[2]).is_equal(M3.Block.BOX)


func test_swaps_run_the_belt_and_boosters_do_not() -> void:
	var session := M3Session.new(_level([">>>>>>>"], {1: 99}))
	var before := _row(session.board, 0)
	var booster := session.use_booster(M3.BOOSTER_SINGLE, Vector2i(3, 6))
	assert_bool(_has_step(booster, M3.STEP_BELT)).is_false()
	var move: Vector2i = M3MoveFinder.find_moves(session.board)[0]
	var steps := session.swap(session.board.pos(move.x), session.board.pos(move.y))
	assert_bool(_has_step(steps, M3.STEP_BELT)).is_true()
	assert_bool(session.board.is_full()).is_true()
	assert_bool(M3Matcher.find_groups(session.board).is_empty()).is_true()
	assert_int(before.size()).is_equal(7)


func test_board_view_follows_the_belt() -> void:
	var session := M3Session.new(_level([".......", ".......", ">>>>>>>"], {1: 99}))
	var view: BoardView = auto_free(BoardView.new())
	view.animate = false
	add_child(view)
	view.size = Vector2(700, 700)
	view.setup(session.board)
	var move: Vector2i = M3MoveFinder.find_moves(session.board)[0]
	var steps := session.swap(session.board.pos(move.x), session.board.pos(move.y))
	await view.play(steps)
	assert_bool(view.tiles_match_board()).is_true()
	assert_int(view.resyncs).is_equal(0)


func test_bot_can_finish_a_belt_level() -> void:
	var level := _level([".......", ".......", ">>>>>>>", ".......", "<<<<<<<", ".......", "......."], {1: 12, 3: 12})
	var wins := 0
	for s in 5:
		var def: M3LevelDef = level.duplicate()
		def.rng_seed = 100 + s
		if M3Bot.new(s + 1).play(M3Session.new(def)):
			wins += 1
	assert_int(wins).is_greater(0)
