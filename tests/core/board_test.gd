extends GdUnitTestSuite


static func pattern(w: int, h: int) -> M3Board:
	var rows := PackedStringArray()
	for y in h:
		var row := ""
		for x in w:
			row += str((x + y) % 3 + 1)
		rows.append(row)
	return M3Board.from_rows(rows)


func test_generated_boards_have_no_match_and_a_move() -> void:
	for s in range(1, 51):
		var board := M3Board.new(7, 7, 5, s)
		board.generate()
		assert_int(M3Matcher.find_groups(board).size()).is_equal(0)
		assert_bool(M3MoveFinder.has_move(board)).is_true()


func test_same_seed_gives_same_board() -> void:
	var a := M3Board.new(7, 7, 5, 42)
	var b := M3Board.new(7, 7, 5, 42)
	a.generate()
	b.generate()
	assert_array(Array(a.kinds)).is_equal(Array(b.kinds))


func test_different_seeds_give_different_boards() -> void:
	var a := M3Board.new(7, 7, 5, 1)
	var b := M3Board.new(7, 7, 5, 2)
	a.generate()
	b.generate()
	assert_array(Array(a.kinds)).is_not_equal(Array(b.kinds))


func test_gravity_compacts_columns_keeping_order() -> void:
	var board := M3Board.from_rows(PackedStringArray(["1.", ".2", "3."]))
	var moves := board.apply_gravity()
	assert_array(Array(board.kinds)).is_equal([0, 0, 1, 0, 3, 2])
	assert_int(moves.size()).is_equal(2)


func test_refill_fills_every_gap_with_valid_kinds() -> void:
	var board := M3Board.from_rows(PackedStringArray(["1.", ".2", "3."]), 4)
	board.apply_gravity()
	board.refill()
	assert_bool(board.is_full()).is_true()
	for kind in board.kinds:
		assert_int(kind).is_between(1, 4)


func test_shuffle_fixes_a_deadlocked_board() -> void:
	var board := pattern(6, 6)
	assert_bool(M3MoveFinder.has_move(board)).is_false()
	board.shuffle()
	assert_bool(M3MoveFinder.has_move(board)).is_true()
	assert_int(M3Matcher.find_groups(board).size()).is_equal(0)
