extends GdUnitTestSuite


func _session(goals: Dictionary, moves: int, rng_seed: int) -> M3Session:
	var level := M3LevelDef.new()
	level.moves = moves
	level.rng_seed = rng_seed
	for kind in goals:
		level.goals[kind] = goals[kind]
	return M3Session.new(level)


func test_bot_beats_an_easy_level() -> void:
	for s in range(1, 6):
		assert_bool(M3Bot.new(s).play(_session({1: 3}, 20, s))).is_true()


func test_bot_cannot_beat_an_impossible_level() -> void:
	var session := _session({1: 500}, 3, 1)
	assert_bool(M3Bot.new(1).play(session)).is_false()
	assert_int(session.moves_left).is_equal(0)


func test_bot_is_deterministic_for_a_seed() -> void:
	var a := _session({1: 30, 2: 30}, 8, 4)
	var b := _session({1: 30, 2: 30}, 8, 4)
	M3Bot.new(4).play(a)
	M3Bot.new(4).play(b)
	assert_array(Array(a.board.kinds)).is_equal(Array(b.board.kinds))
