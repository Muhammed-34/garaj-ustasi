extends GdUnitTestSuite

const BoardTest := preload("res://tests/core/board_test.gd")


func test_limit_caps_the_result() -> void:
	var board := M3Board.new(7, 7, 5, 3)
	board.generate()
	assert_int(M3MoveFinder.find_moves(board, 1).size()).is_equal(1)


func test_two_adjacent_specials_are_a_move() -> void:
	var board := BoardTest.pattern(5, 3)
	board.specials[0] = M3.Special.LINE_H
	board.specials[1] = M3.Special.BOMB
	assert_array(M3MoveFinder.find_moves(board)).contains([Vector2i(0, 1)])


func test_empty_cells_are_never_part_of_a_move() -> void:
	var board := M3Board.from_rows(PackedStringArray(["11.11", "23123", "31231"]))
	for move in M3MoveFinder.find_moves(board):
		assert_bool(move.x == 2 or move.y == 2).is_false()


func test_empty_board_has_no_moves() -> void:
	assert_int(M3MoveFinder.find_moves(M3Board.new(3, 3)).size()).is_equal(0)


func test_every_found_move_is_accepted_by_the_resolver() -> void:
	for s in range(1, 11):
		var board := M3Board.new(7, 7, 5, s)
		board.generate()
		for move in M3MoveFinder.find_moves(board):
			var copy := board.clone()
			assert_array(M3Resolver.new().try_swap(copy, copy.pos(move.x), copy.pos(move.y))).is_not_empty()
