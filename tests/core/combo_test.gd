extends GdUnitTestSuite

const BoardTest := preload("res://tests/core/board_test.gd")


func _first(steps: Array, type: StringName) -> Dictionary:
	for step in steps:
		if step.type == type:
			return step
	return {}


func _index_of(steps: Array, type: StringName) -> int:
	for i in steps.size():
		if steps[i].type == type:
			return i
	return -1


func test_color_bomb_hit_by_blast_clears_most_common_kind() -> void:
	var board := BoardTest.pattern(5, 3)
	var color := board.idx(Vector2i(0, 1))
	board.kinds[color] = M3.EMPTY
	board.specials[color] = M3.Special.COLOR
	board.specials[board.idx(Vector2i(4, 1))] = M3.Special.LINE_H
	var steps: Array = []
	M3Resolver.new().clear_area(board, M3.Special.NONE, Vector2i(4, 1), steps)
	assert_int(_first(steps, M3.STEP_CLEAR).cells.size()).is_greater(5)
	assert_int(Array(board.kinds).count(1)).is_equal(0)


func test_color_bomb_with_line_turns_that_kind_into_lines() -> void:
	var board := BoardTest.pattern(5, 5)
	board.kinds[0] = M3.EMPTY
	board.specials[0] = M3.Special.COLOR
	board.specials[1] = M3.Special.LINE_H
	var steps := M3Resolver.new().try_swap(board, Vector2i(0, 0), Vector2i(1, 0))
	var converted := _first(steps, M3.STEP_SPECIAL)
	assert_int(converted.special).is_equal(M3.Special.LINE_H)
	assert_int(converted.cells.size()).is_greater(0)


func test_two_flyers_hit_three_targets() -> void:
	var board := BoardTest.pattern(5, 5)
	board.specials[board.idx(Vector2i(2, 2))] = M3.Special.FLYER
	board.specials[board.idx(Vector2i(3, 2))] = M3.Special.FLYER
	var steps := M3Resolver.new().try_swap(board, Vector2i(2, 2), Vector2i(3, 2))
	assert_int(_first(steps, M3.STEP_CLEAR).cells.size()).is_equal(5)


func test_flyer_carries_a_bomb_to_its_target() -> void:
	var board := BoardTest.pattern(5, 5)
	board.specials[board.idx(Vector2i(2, 2))] = M3.Special.FLYER
	board.specials[board.idx(Vector2i(3, 2))] = M3.Special.BOMB
	var steps := M3Resolver.new().try_swap(board, Vector2i(2, 2), Vector2i(3, 2))
	assert_int(_first(steps, M3.STEP_CLEAR).cells.size()).is_greater_equal(6)


func test_flyer_targets_goal_tiles_first() -> void:
	var board := M3Board.from_rows(PackedStringArray(["12121", "21212", "12123"]))
	board.specials[board.idx(Vector2i(1, 1))] = M3.Special.FLYER
	var resolver := M3Resolver.new()
	resolver.priority_kinds = PackedInt32Array([3])
	var steps: Array = []
	resolver.clear_area(board, M3.Special.NONE, Vector2i(1, 1), steps)
	assert_bool(Array(_first(steps, M3.STEP_CLEAR).cells).has(14)).is_true()


func test_swap_into_empty_cell_is_rejected() -> void:
	var board := M3Board.from_rows(PackedStringArray(["1.2", "212", "121"]))
	assert_array(M3Resolver.new().try_swap(board, Vector2i(0, 0), Vector2i(1, 0))).is_empty()


func test_swap_outside_board_is_rejected() -> void:
	var board := BoardTest.pattern(5, 3)
	assert_array(M3Resolver.new().try_swap(board, Vector2i(4, 0), Vector2i(5, 0))).is_empty()


func test_steps_run_swap_then_clear_then_refill() -> void:
	var board := M3Board.from_rows(PackedStringArray(["11213", "23121", "31232"]))
	var steps := M3Resolver.new().try_swap(board, Vector2i(2, 0), Vector2i(2, 1))
	var clear := _index_of(steps, M3.STEP_CLEAR)
	var fall := _index_of(steps, M3.STEP_FALL)
	var spawn := _index_of(steps, M3.STEP_SPAWN)
	assert_int(_index_of(steps, M3.STEP_SWAP)).is_equal(0)
	assert_int(clear).is_greater(0)
	assert_int(spawn).is_greater(clear)
	if fall >= 0:
		assert_int(fall).is_less(spawn)
