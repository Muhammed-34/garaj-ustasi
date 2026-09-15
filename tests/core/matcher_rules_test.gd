extends GdUnitTestSuite


func _groups(rows: Array) -> Array:
	return M3Matcher.find_groups(M3Board.from_rows(PackedStringArray(rows)))


func test_six_in_a_row_is_one_color_bomb_group() -> void:
	var groups := _groups(["111111", "232323", "323232"])
	assert_int(groups.size()).is_equal(1)
	assert_int(groups[0].special).is_equal(M3.Special.COLOR)


func test_plus_shape_makes_bomb_in_the_middle() -> void:
	var groups := _groups(["212", "111", "212"])
	assert_int(groups[0].special).is_equal(M3.Special.BOMB)
	assert_int(groups[0].anchor).is_equal(4)


func test_square_touching_a_line_becomes_one_flyer_group() -> void:
	var groups := _groups(["1112", "1123", "2331"])
	assert_int(groups.size()).is_equal(1)
	assert_int(groups[0].special).is_equal(M3.Special.FLYER)


func test_empty_cells_never_match() -> void:
	assert_int(_groups(["...", "121", "212"]).size()).is_equal(0)


func test_color_bomb_cell_is_not_part_of_a_match() -> void:
	var board := M3Board.from_rows(PackedStringArray(["1.11", "2323", "3232"]))
	board.specials[1] = M3.Special.COLOR
	assert_int(M3Matcher.find_groups(board).size()).is_equal(0)


func test_four_run_anchor_defaults_to_second_cell() -> void:
	assert_int(_groups(["11112", "23231", "31323"])[0].anchor).is_equal(1)


func test_two_kinds_side_by_side_form_two_groups() -> void:
	assert_int(_groups(["111222", "232323", "323232"]).size()).is_equal(2)
