extends GdUnitTestSuite


func _groups(rows: Array) -> Array:
	return M3Matcher.find_groups(M3Board.from_rows(PackedStringArray(rows)))


func test_mixed_rows_have_no_match() -> void:
	assert_int(_groups(["12312", "23123", "31231"]).size()).is_equal(0)


func test_horizontal_three_is_plain_group() -> void:
	var groups := _groups(["11123", "23312", "31231"])
	assert_int(groups.size()).is_equal(1)
	assert_int(groups[0].cells.size()).is_equal(3)
	assert_int(groups[0].special).is_equal(M3.Special.NONE)


func test_vertical_three_is_plain_group() -> void:
	var groups := _groups(["123", "132", "121"])
	assert_int(groups.size()).is_equal(1)
	assert_int(groups[0].kind).is_equal(1)
	assert_int(groups[0].special).is_equal(M3.Special.NONE)


func test_horizontal_four_makes_row_clearer() -> void:
	var groups := _groups(["11112", "23231", "31323"])
	assert_int(groups[0].special).is_equal(M3.Special.LINE_H)


func test_vertical_four_makes_column_clearer() -> void:
	var groups := _groups(["123", "132", "123", "131"])
	assert_int(groups[0].special).is_equal(M3.Special.LINE_V)


func test_five_in_a_row_makes_color_bomb() -> void:
	var groups := _groups(["11111", "23232", "32323"])
	assert_int(groups[0].special).is_equal(M3.Special.COLOR)
	assert_int(groups[0].anchor).is_equal(2)


func test_l_shape_makes_bomb_on_corner() -> void:
	var groups := _groups(["111", "123", "132"])
	assert_int(groups.size()).is_equal(1)
	assert_int(groups[0].cells.size()).is_equal(5)
	assert_int(groups[0].special).is_equal(M3.Special.BOMB)
	assert_int(groups[0].anchor).is_equal(0)


func test_t_shape_makes_bomb_on_crossing() -> void:
	var groups := _groups(["111", "213", "312"])
	assert_int(groups[0].special).is_equal(M3.Special.BOMB)
	assert_int(groups[0].anchor).is_equal(1)


func test_two_by_two_square_makes_flyer() -> void:
	var groups := _groups(["112", "113", "231"])
	assert_int(groups.size()).is_equal(1)
	assert_int(groups[0].special).is_equal(M3.Special.FLYER)


func test_separate_matches_stay_separate_groups() -> void:
	assert_int(_groups(["11123", "23231", "12312", "33312"]).size()).is_equal(2)


func test_swapped_cell_becomes_anchor() -> void:
	var board := M3Board.from_rows(PackedStringArray(["11112", "23231", "31323"]))
	var groups := M3Matcher.find_groups(board, PackedInt32Array([3]))
	assert_int(groups[0].anchor).is_equal(3)


func test_existing_special_is_not_chosen_as_anchor() -> void:
	var board := M3Board.from_rows(PackedStringArray(["11112", "23231", "31323"]))
	board.specials[1] = M3.Special.BOMB
	var groups := M3Matcher.find_groups(board, PackedInt32Array([1]))
	assert_int(groups[0].anchor).is_not_equal(1)


func test_has_match_at_detects_square() -> void:
	var board := M3Board.from_rows(PackedStringArray(["112", "113", "231"]))
	assert_bool(M3Matcher.has_match_at(board, 4)).is_true()
	assert_bool(M3Matcher.has_match_at(board, 2)).is_false()
