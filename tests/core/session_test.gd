extends GdUnitTestSuite

const BoardTest := preload("res://tests/core/board_test.gd")


func _session(goals: Dictionary, moves: int = 10, rng_seed: int = 1) -> M3Session:
	var level := M3LevelDef.new()
	level.moves = moves
	level.rng_seed = rng_seed
	for kind in goals:
		level.goals[kind] = goals[kind]
	return M3Session.new(level)


func _known_board() -> M3Board:
	return M3Board.from_rows(PackedStringArray(["11213", "23121", "31232"]))


func _first_clear_size(steps: Array) -> int:
	for step in steps:
		if step.type == M3.STEP_CLEAR:
			return step.cells.size()
	return 0


func test_valid_swap_uses_one_move() -> void:
	var session := _session({1: 50})
	var m: Vector2i = M3MoveFinder.find_moves(session.board)[0]
	session.swap(session.board.pos(m.x), session.board.pos(m.y))
	assert_int(session.moves_left).is_equal(9)


func test_invalid_swap_uses_no_move() -> void:
	var session := _session({1: 50})
	assert_array(session.swap(Vector2i(0, 0), Vector2i(3, 3))).is_empty()
	assert_int(session.moves_left).is_equal(10)


func test_cleared_tiles_count_toward_goals() -> void:
	var session := _session({1: 4})
	session.board = _known_board()
	var steps := session.swap(Vector2i(2, 0), Vector2i(2, 1))
	assert_int(session.goals[1]).is_less_equal(1)
	assert_str(str(steps[-1].type)).is_equal("goal")


func test_reaching_goals_wins() -> void:
	var session := _session({1: 1})
	session.board = _known_board()
	session.swap(Vector2i(2, 0), Vector2i(2, 1))
	assert_bool(session.is_won()).is_true()
	assert_bool(session.is_finished()).is_true()


func test_running_out_of_moves_loses_and_locks_board() -> void:
	var session := _session({1: 999}, 1)
	session.board = _known_board()
	session.swap(Vector2i(2, 0), Vector2i(2, 1))
	assert_bool(session.is_lost()).is_true()
	var m: Vector2i = M3MoveFinder.find_moves(session.board)[0]
	assert_array(session.swap(session.board.pos(m.x), session.board.pos(m.y))).is_empty()


func test_extra_moves_reopen_a_lost_level() -> void:
	var session := _session({1: 999}, 1)
	session.board = _known_board()
	session.swap(Vector2i(2, 0), Vector2i(2, 1))
	session.add_moves(5)
	assert_bool(session.is_lost()).is_false()
	assert_int(session.moves_left).is_equal(5)


func test_single_booster_clears_one_tile_without_using_a_move() -> void:
	var session := _session({1: 50})
	session.board = BoardTest.pattern(5, 3)
	var steps := session.use_booster(M3.BOOSTER_SINGLE, Vector2i(0, 0))
	assert_int(_first_clear_size(steps)).is_equal(1)
	assert_int(session.moves_left).is_equal(10)
	assert_bool(session.board.is_full()).is_true()


func test_row_booster_clears_a_row() -> void:
	var session := _session({1: 50})
	session.board = BoardTest.pattern(5, 3)
	assert_int(_first_clear_size(session.use_booster(M3.BOOSTER_ROW, Vector2i(1, 1)))).is_equal(5)


func test_shuffle_booster_leaves_a_playable_board() -> void:
	var session := _session({1: 50})
	session.board = BoardTest.pattern(6, 6)
	var steps := session.use_booster(M3.BOOSTER_SHUFFLE, Vector2i.ZERO)
	assert_str(str(steps[0].type)).is_equal("shuffle")
	assert_bool(M3MoveFinder.has_move(session.board)).is_true()


func test_unknown_booster_does_nothing() -> void:
	var session := _session({1: 50})
	assert_array(session.use_booster(&"unknown", Vector2i.ZERO)).is_empty()


func test_random_play_keeps_board_full_stable_and_playable() -> void:
	for s in range(1, 31):
		var session := _session({1: 999}, 99, s)
		for turn in 12:
			var moves := M3MoveFinder.find_moves(session.board)
			assert_bool(moves.is_empty()).is_false()
			var m: Vector2i = moves[(s * 7 + turn) % moves.size()]
			var steps := session.swap(session.board.pos(m.x), session.board.pos(m.y))
			assert_bool(steps.is_empty()).is_false()
			assert_bool(session.board.is_full()).is_true()
			assert_int(M3Matcher.find_groups(session.board).size()).is_equal(0)
