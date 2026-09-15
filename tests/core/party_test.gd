extends GdUnitTestSuite


func _won_session(moves: int) -> M3Session:
	var level := M3LevelDef.new()
	level.goals = {1: 1}
	level.moves = moves
	var session := M3Session.new(level)
	session.goals[1] = 0
	return session


func test_party_turns_leftover_moves_into_line_specials() -> void:
	var session := _won_session(3)
	var steps := session.party(8, 5)
	var specials := steps.filter(func(step: Dictionary) -> bool: return step.type == M3.STEP_SPECIAL)
	var clears := steps.filter(func(step: Dictionary) -> bool: return step.type == M3.STEP_CLEAR and step.cause == &"party")
	assert_int(specials.size()).is_equal(3)
	assert_int(clears.size()).is_equal(1)
	assert_int(clears[0].cells.size()).is_greater_equal(7)
	assert_int(session.moves_left).is_equal(0)
	assert_bool(session.board.is_full()).is_true()


func test_party_is_capped() -> void:
	var session := _won_session(30)
	var specials := session.party(8, 5).filter(func(step: Dictionary) -> bool: return step.type == M3.STEP_SPECIAL)
	assert_int(specials.size()).is_equal(8)


func test_no_party_before_winning_or_without_moves() -> void:
	var level := M3LevelDef.new()
	level.goals = {1: 10}
	assert_array(M3Session.new(level).party(8, 1)).is_empty()
	assert_array(_won_session(1).party(0, 1)).is_empty()
