extends GdUnitTestSuite

const BoardTest := preload("res://tests/core/board_test.gd")


func _session(goals: Dictionary = {1: 50}, moves: int = 10, rng_seed: int = 1) -> M3Session:
	var level := M3LevelDef.new()
	level.moves = moves
	level.rng_seed = rng_seed
	for kind in goals:
		level.goals[kind] = goals[kind]
	return M3Session.new(level)


func test_goals_never_go_below_zero() -> void:
	var session := _session({1: 1})
	session.board = BoardTest.pattern(5, 3)
	session.use_booster(M3.BOOSTER_ROW, Vector2i(0, 0))
	assert_int(session.goals[1]).is_equal(0)


func test_finished_goals_stop_steering_flyers() -> void:
	var session := _session({1: 1})
	session.board = BoardTest.pattern(5, 3)
	session.use_booster(M3.BOOSTER_ROW, Vector2i(0, 0))
	assert_int(session.resolver.priority_kinds.size()).is_equal(0)


func test_boosters_do_nothing_after_level_ends() -> void:
	var session := _session({1: 1})
	session.board = BoardTest.pattern(5, 3)
	session.use_booster(M3.BOOSTER_ROW, Vector2i(0, 0))
	assert_bool(session.is_won()).is_true()
	assert_array(session.use_booster(M3.BOOSTER_SINGLE, Vector2i(0, 0))).is_empty()


func test_booster_outside_board_does_nothing() -> void:
	var session := _session()
	assert_array(session.use_booster(M3.BOOSTER_SINGLE, Vector2i(9, 9))).is_empty()
	assert_int(session.moves_left).is_equal(10)


func test_same_seed_and_moves_replay_identically() -> void:
	var a := _session({1: 50}, 10, 7)
	var b := _session({1: 50}, 10, 7)
	for turn in 5:
		var m: Vector2i = M3MoveFinder.find_moves(a.board)[0]
		a.swap(a.board.pos(m.x), a.board.pos(m.y))
		b.swap(b.board.pos(m.x), b.board.pos(m.y))
	assert_array(Array(a.board.kinds)).is_equal(Array(b.board.kinds))


func test_clone_does_not_change_original() -> void:
	var session := _session()
	var copy := session.clone()
	var m: Vector2i = M3MoveFinder.find_moves(copy.board)[0]
	copy.swap(copy.board.pos(m.x), copy.board.pos(m.y))
	assert_int(session.moves_left).is_equal(10)
	assert_int(copy.moves_left).is_equal(9)
	assert_int(session.goals[1]).is_equal(50)
