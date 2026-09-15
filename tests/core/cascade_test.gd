extends GdUnitTestSuite

const BoardTest := preload("res://tests/core/board_test.gd")
const FIVE_ROWS := ["12312", "23123", "11211"]
const FOUR_ROWS := ["11213", "23121", "31232"]


func _first(steps: Array, type: StringName) -> Dictionary:
	for step in steps:
		if step.type == type:
			return step
	return {}


func _session(goals: Dictionary = {1: 50}, moves: int = 10) -> M3Session:
	var level := M3LevelDef.new()
	level.moves = moves
	for kind in goals:
		level.goals[kind] = goals[kind]
	return M3Session.new(level)


func test_match_clear_is_labelled_match() -> void:
	var board := M3Board.from_rows(PackedStringArray(FOUR_ROWS))
	var steps := M3Resolver.new().try_swap(board, Vector2i(2, 0), Vector2i(2, 1))
	assert_str(str(_first(steps, M3.STEP_CLEAR).cause)).is_equal("match")


func test_combo_clear_is_labelled_combo() -> void:
	var board := BoardTest.pattern(5, 5)
	board.specials[board.idx(Vector2i(1, 1))] = M3.Special.BOMB
	board.specials[board.idx(Vector2i(2, 1))] = M3.Special.BOMB
	var steps := M3Resolver.new().try_swap(board, Vector2i(1, 1), Vector2i(2, 1))
	assert_str(str(_first(steps, M3.STEP_CLEAR).cause)).is_equal("combo")


func test_booster_clear_is_labelled_booster() -> void:
	var session := _session()
	session.board = BoardTest.pattern(5, 3)
	var steps := session.use_booster(M3.BOOSTER_SINGLE, Vector2i(0, 0))
	assert_str(str(_first(steps, M3.STEP_CLEAR).cause)).is_equal("booster")


func test_five_match_swap_creates_color_bomb_on_swapped_cell() -> void:
	var board := M3Board.from_rows(PackedStringArray(FIVE_ROWS))
	var special := _first(M3Resolver.new().try_swap(board, Vector2i(2, 2), Vector2i(2, 1)), M3.STEP_SPECIAL)
	assert_int(special.special).is_equal(M3.Special.COLOR)
	assert_int(special.cells[0]).is_equal(12)
	assert_int(special.kind).is_equal(M3.EMPTY)


func test_falling_tiles_only_move_down_their_column() -> void:
	var board := M3Board.from_rows(PackedStringArray(FIVE_ROWS))
	var fall := _first(M3Resolver.new().try_swap(board, Vector2i(2, 2), Vector2i(2, 1)), M3.STEP_FALL)
	assert_dict(fall).is_not_empty()
	for move in fall.moves:
		assert_int(move.y).is_greater(move.x)
		assert_int(move.y % 5).is_equal(move.x % 5)


func test_refilled_tiles_use_valid_kinds() -> void:
	var board := M3Board.from_rows(PackedStringArray(FOUR_ROWS), 4)
	M3Resolver.new().try_swap(board, Vector2i(2, 0), Vector2i(2, 1))
	for i in board.cell_count():
		if board.specials[i] != M3.Special.COLOR:
			assert_int(board.kinds[i]).is_between(1, 4)


func test_row_booster_fires_specials_in_that_row() -> void:
	var session := _session()
	session.board = BoardTest.pattern(5, 3)
	session.board.specials[session.board.idx(Vector2i(3, 1))] = M3.Special.LINE_V
	var steps := session.use_booster(M3.BOOSTER_ROW, Vector2i(0, 1))
	assert_int(_first(steps, M3.STEP_CLEAR).cells.size()).is_equal(7)


func test_single_booster_on_a_bomb_sets_it_off() -> void:
	var session := _session()
	session.board = BoardTest.pattern(5, 3)
	session.board.specials[session.board.idx(Vector2i(2, 1))] = M3.Special.BOMB
	var steps := session.use_booster(M3.BOOSTER_SINGLE, Vector2i(2, 1))
	assert_int(_first(steps, M3.STEP_CLEAR).cells.size()).is_equal(9)


func test_row_booster_works_on_the_bottom_row() -> void:
	var session := _session()
	session.board = BoardTest.pattern(5, 3)
	var steps := session.use_booster(M3.BOOSTER_ROW, Vector2i(0, 2))
	assert_int(_first(steps, M3.STEP_CLEAR).cells.size()).is_equal(5)


func test_goal_step_reports_remaining_goals() -> void:
	var session := _session({1: 50})
	var m: Vector2i = M3MoveFinder.find_moves(session.board)[0]
	var steps := session.swap(session.board.pos(m.x), session.board.pos(m.y))
	var goal: Dictionary = steps[-1]
	assert_int(goal.remaining[1]).is_equal(session.goals[1])


func test_two_color_bombs_leave_a_full_stable_board() -> void:
	var board := BoardTest.pattern(5, 3)
	for i in [0, 1]:
		board.kinds[i] = M3.EMPTY
		board.specials[i] = M3.Special.COLOR
	M3Resolver.new().try_swap(board, Vector2i(0, 0), Vector2i(1, 0))
	assert_bool(board.is_full()).is_true()
	assert_int(M3Matcher.find_groups(board).size()).is_equal(0)


func test_rejected_swap_does_not_consume_randomness() -> void:
	var board := M3Board.from_rows(PackedStringArray(["12312", "23123", "31231"]))
	var state := board.spawn_rng.state
	M3Resolver.new().try_swap(board, Vector2i(0, 0), Vector2i(1, 0))
	assert_int(board.spawn_rng.state).is_equal(state)


func test_bombs_on_the_edge_stay_inside_board() -> void:
	var board := BoardTest.pattern(5, 5)
	board.specials[0] = M3.Special.BOMB
	board.specials[1] = M3.Special.BOMB
	var steps := M3Resolver.new().try_swap(board, Vector2i(0, 0), Vector2i(1, 0))
	assert_int(_first(steps, M3.STEP_CLEAR).cells.size()).is_equal(12)


func test_shuffle_is_deterministic_for_a_seed() -> void:
	var a := BoardTest.pattern(6, 6)
	var b := BoardTest.pattern(6, 6)
	a.shuffle()
	b.shuffle()
	assert_array(Array(a.kinds)).is_equal(Array(b.kinds))


func test_shuffle_keeps_the_same_tiles() -> void:
	var board := BoardTest.pattern(6, 6)
	var before := Array(board.kinds)
	before.sort()
	board.shuffle()
	var after := Array(board.kinds)
	after.sort()
	assert_array(after).is_equal(before)
