extends GdUnitTestSuite

const BoardTest := preload("res://tests/core/board_test.gd")


func _first(steps: Array, type: StringName) -> Dictionary:
	for step in steps:
		if step.type == type:
			return step
	return {}


func _cleared_by_area(board: M3Board, cell: Vector2i) -> int:
	var steps: Array = []
	M3Resolver.new().clear_area(board, M3.Special.NONE, cell, steps)
	return _first(steps, M3.STEP_CLEAR).cells.size()


func _cleared_by_swap(board: M3Board, a: Vector2i, b: Vector2i) -> int:
	var steps := M3Resolver.new().try_swap(board, a, b)
	return _first(steps, M3.STEP_CLEAR).cells.size()


func test_non_adjacent_swap_is_rejected() -> void:
	var board := BoardTest.pattern(5, 3)
	assert_array(M3Resolver.new().try_swap(board, Vector2i(0, 0), Vector2i(2, 0))).is_empty()


func test_swap_without_match_is_rejected_and_reverted() -> void:
	var board := M3Board.from_rows(PackedStringArray(["12312", "23123", "31231"]))
	var before := Array(board.kinds)
	assert_array(M3Resolver.new().try_swap(board, Vector2i(0, 0), Vector2i(1, 0))).is_empty()
	assert_array(Array(board.kinds)).is_equal(before)


func test_valid_swap_clears_and_leaves_a_stable_full_board() -> void:
	var board := M3Board.from_rows(PackedStringArray(["11213", "23121", "31232"]))
	var steps := M3Resolver.new().try_swap(board, Vector2i(2, 0), Vector2i(2, 1))
	assert_str(str(steps[0].type)).is_equal("swap")
	assert_dict(_first(steps, M3.STEP_CLEAR)).is_not_empty()
	assert_bool(board.is_full()).is_true()
	assert_int(M3Matcher.find_groups(board).size()).is_equal(0)


func test_four_match_places_row_clearer_on_swapped_cell() -> void:
	var board := M3Board.from_rows(PackedStringArray(["11213", "23121", "31232"]))
	var steps := M3Resolver.new().try_swap(board, Vector2i(2, 0), Vector2i(2, 1))
	var special := _first(steps, M3.STEP_SPECIAL)
	assert_int(special.special).is_equal(M3.Special.LINE_H)
	assert_int(special.cells[0]).is_equal(2)


func test_row_clearer_clears_whole_row() -> void:
	var board := BoardTest.pattern(5, 3)
	board.specials[board.idx(Vector2i(2, 1))] = M3.Special.LINE_H
	assert_int(_cleared_by_area(board, Vector2i(2, 1))).is_equal(5)


func test_column_clearer_clears_whole_column() -> void:
	var board := BoardTest.pattern(5, 3)
	board.specials[board.idx(Vector2i(2, 1))] = M3.Special.LINE_V
	assert_int(_cleared_by_area(board, Vector2i(2, 1))).is_equal(3)


func test_bomb_clears_three_by_three() -> void:
	var board := BoardTest.pattern(5, 3)
	board.specials[board.idx(Vector2i(2, 1))] = M3.Special.BOMB
	assert_int(_cleared_by_area(board, Vector2i(2, 1))).is_equal(9)


func test_bomb_in_corner_stays_inside_board() -> void:
	var board := BoardTest.pattern(5, 3)
	board.specials[0] = M3.Special.BOMB
	assert_int(_cleared_by_area(board, Vector2i(0, 0))).is_equal(4)


func test_specials_chain_into_each_other() -> void:
	var board := BoardTest.pattern(5, 3)
	board.specials[board.idx(Vector2i(0, 1))] = M3.Special.LINE_H
	board.specials[board.idx(Vector2i(4, 1))] = M3.Special.LINE_V
	assert_int(_cleared_by_area(board, Vector2i(0, 1))).is_equal(7)


func test_flyer_clears_cross_and_one_target() -> void:
	var board := BoardTest.pattern(5, 3)
	board.specials[board.idx(Vector2i(2, 1))] = M3.Special.FLYER
	assert_int(_cleared_by_area(board, Vector2i(2, 1))).is_equal(6)


func test_color_bomb_with_tile_clears_that_kind() -> void:
	var board := BoardTest.pattern(5, 3)
	board.kinds[0] = M3.EMPTY
	board.specials[0] = M3.Special.COLOR
	assert_int(_cleared_by_swap(board, Vector2i(0, 0), Vector2i(1, 0))).is_equal(6)


func test_two_color_bombs_clear_everything() -> void:
	var board := BoardTest.pattern(5, 3)
	for i in [0, 1]:
		board.kinds[i] = M3.EMPTY
		board.specials[i] = M3.Special.COLOR
	assert_int(_cleared_by_swap(board, Vector2i(0, 0), Vector2i(1, 0))).is_equal(15)


func test_two_line_clearers_clear_a_cross() -> void:
	var board := BoardTest.pattern(5, 5)
	board.specials[board.idx(Vector2i(2, 2))] = M3.Special.LINE_H
	board.specials[board.idx(Vector2i(3, 2))] = M3.Special.LINE_V
	assert_int(_cleared_by_swap(board, Vector2i(2, 2), Vector2i(3, 2))).is_equal(9)


func test_line_and_bomb_clear_three_rows_and_columns() -> void:
	var board := BoardTest.pattern(7, 7)
	board.specials[board.idx(Vector2i(3, 3))] = M3.Special.LINE_H
	board.specials[board.idx(Vector2i(4, 3))] = M3.Special.BOMB
	assert_int(_cleared_by_swap(board, Vector2i(3, 3), Vector2i(4, 3))).is_equal(33)


func test_two_bombs_clear_five_by_five() -> void:
	var board := BoardTest.pattern(7, 7)
	board.specials[board.idx(Vector2i(3, 3))] = M3.Special.BOMB
	board.specials[board.idx(Vector2i(4, 3))] = M3.Special.BOMB
	assert_int(_cleared_by_swap(board, Vector2i(3, 3), Vector2i(4, 3))).is_equal(25)
