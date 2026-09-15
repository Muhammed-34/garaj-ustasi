extends GdUnitTestSuite


func _groups(rows: Array) -> Array:
	return M3Matcher.find_groups(M3Board.from_rows(PackedStringArray(rows)))


func test_vertical_five_makes_color_bomb_in_the_middle() -> void:
	var groups := _groups(["12", "13", "12", "13", "12"])
	assert_int(groups[0].special).is_equal(M3.Special.COLOR)
	assert_int(groups[0].anchor).is_equal(4)


func test_vertical_four_anchor_defaults_to_second_cell() -> void:
	var groups := _groups(["12", "13", "12", "13"])
	assert_int(groups[0].special).is_equal(M3.Special.LINE_V)
	assert_int(groups[0].anchor).is_equal(2)


func test_line_of_five_with_a_leg_is_still_a_color_bomb() -> void:
	var groups := _groups(["11111", "1....", "1...."])
	assert_int(groups.size()).is_equal(1)
	assert_int(groups[0].cells.size()).is_equal(7)
	assert_int(groups[0].special).is_equal(M3.Special.COLOR)


func test_two_by_three_block_is_one_flyer_group() -> void:
	var groups := _groups(["111", "111", "232"])
	assert_int(groups.size()).is_equal(1)
	assert_int(groups[0].cells.size()).is_equal(6)
	assert_int(groups[0].special).is_equal(M3.Special.FLYER)


func test_different_kinds_touching_stay_separate() -> void:
	assert_int(_groups(["111", "222", "313"]).size()).is_equal(2)


func test_swapped_cell_outside_group_is_ignored() -> void:
	var board := M3Board.from_rows(PackedStringArray(["11112", "23231", "31323"]))
	assert_int(M3Matcher.find_groups(board, PackedInt32Array([9]))[0].anchor).is_equal(1)


func test_finding_groups_leaves_board_untouched() -> void:
	var board := M3Board.from_rows(PackedStringArray(["11112", "23231", "31323"]))
	var before := Array(board.kinds)
	M3Matcher.find_groups(board)
	assert_array(Array(board.kinds)).is_equal(before)


func test_has_match_at_empty_cell_is_false() -> void:
	assert_bool(M3Matcher.has_match_at(M3Board.from_rows(PackedStringArray(["1.1"])), 1)).is_false()


func test_has_match_at_detects_vertical_run() -> void:
	assert_bool(M3Matcher.has_match_at(M3Board.from_rows(PackedStringArray(["123", "132", "121"])), 3)).is_true()
