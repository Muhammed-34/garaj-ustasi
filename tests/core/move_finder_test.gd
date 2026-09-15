extends GdUnitTestSuite

const BoardTest := preload("res://tests/core/board_test.gd")


func test_finds_the_known_move() -> void:
	var board := M3Board.from_rows(PackedStringArray(["11213", "23121", "31232"]))
	assert_array(M3MoveFinder.find_moves(board)).contains([Vector2i(2, 7)])


func test_finding_moves_leaves_board_untouched() -> void:
	var board := M3Board.from_rows(PackedStringArray(["11213", "23121", "31232"]))
	var before := Array(board.kinds)
	M3MoveFinder.find_moves(board)
	assert_array(Array(board.kinds)).is_equal(before)


func test_deadlocked_pattern_has_no_moves() -> void:
	assert_int(M3MoveFinder.find_moves(BoardTest.pattern(6, 6)).size()).is_equal(0)


func test_color_bomb_can_always_be_swapped() -> void:
	var board := BoardTest.pattern(5, 3)
	board.kinds[0] = M3.EMPTY
	board.specials[0] = M3.Special.COLOR
	assert_bool(M3MoveFinder.has_move(board)).is_true()
