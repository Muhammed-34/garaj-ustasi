extends GdUnitTestSuite

const BoardTest := preload("res://tests/core/board_test.gd")


func _session(goals: Dictionary = {1: 50}) -> M3Session:
	var level := M3LevelDef.new()
	level.moves = 10
	level.rng_seed = 3
	for kind in goals:
		level.goals[kind] = goals[kind]
	return M3Session.new(level)


func test_chosen_move_is_a_legal_move() -> void:
	var session := _session()
	var move := M3Bot.new(1).choose_move(session)
	assert_array(M3MoveFinder.find_moves(session.board)).contains([move])


func test_choosing_a_move_does_not_play_it() -> void:
	var session := _session()
	var before := Array(session.board.kinds)
	M3Bot.new(1).choose_move(session)
	assert_int(session.moves_left).is_equal(10)
	assert_array(Array(session.board.kinds)).is_equal(before)


func test_bot_goes_for_goal_tiles() -> void:
	var session := _session({1: 50})
	session.board = M3Board.from_rows(PackedStringArray(["11213", "23121", "31232"]))
	var move := M3Bot.new(1).choose_move(session)
	session.swap(session.board.pos(move.x), session.board.pos(move.y))
	assert_int(session.goals[1]).is_less(50)


func test_bot_reports_no_move_on_a_dead_board() -> void:
	var session := _session()
	session.board = BoardTest.pattern(6, 6)
	assert_that(M3Bot.new(1).choose_move(session)).is_equal(M3Bot.NO_MOVE)
