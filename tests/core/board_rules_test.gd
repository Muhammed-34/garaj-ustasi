extends GdUnitTestSuite


func test_index_and_position_round_trip() -> void:
	var board := M3Board.new(7, 5)
	for i in board.cell_count():
		assert_int(board.idx(board.pos(i))).is_equal(i)


func test_in_bounds_edges() -> void:
	var board := M3Board.new(7, 5)
	assert_bool(board.in_bounds(Vector2i(6, 4))).is_true()
	assert_bool(board.in_bounds(Vector2i(7, 4))).is_false()
	assert_bool(board.in_bounds(Vector2i(-1, 0))).is_false()


func test_from_rows_reads_empty_cells() -> void:
	var board := M3Board.from_rows(PackedStringArray(["1.3"]))
	assert_bool(board.is_occupied(1)).is_false()
	assert_int(board.kinds[2]).is_equal(3)


func test_swap_cells_moves_specials_too() -> void:
	var board := M3Board.from_rows(PackedStringArray(["12"]))
	board.specials[0] = M3.Special.BOMB
	board.swap_cells(0, 1)
	assert_int(board.specials[1]).is_equal(M3.Special.BOMB)
	assert_int(board.kinds[1]).is_equal(1)


func test_gravity_carries_specials_down() -> void:
	var board := M3Board.from_rows(PackedStringArray(["1", ".", "."]))
	board.specials[0] = M3.Special.LINE_V
	board.apply_gravity()
	assert_int(board.specials[2]).is_equal(M3.Special.LINE_V)
	assert_int(board.specials[0]).is_equal(M3.Special.NONE)


func test_color_bomb_cell_counts_as_occupied() -> void:
	var board := M3Board.from_rows(PackedStringArray(["."]))
	board.specials[0] = M3.Special.COLOR
	assert_bool(board.is_occupied(0)).is_true()


func test_clone_is_independent_but_replays_same_refills() -> void:
	var board := M3Board.new(7, 7, 5, 9)
	board.generate()
	var copy := board.clone()
	copy.kinds[0] = 99
	assert_int(board.kinds[0]).is_not_equal(99)
	assert_int(copy.spawn_rng.randi()).is_equal(board.spawn_rng.randi())


func test_three_kind_boards_still_generate_cleanly() -> void:
	for s in range(1, 21):
		var board := M3Board.new(7, 7, 3, s)
		board.generate()
		assert_int(M3Matcher.find_groups(board).size()).is_equal(0)
