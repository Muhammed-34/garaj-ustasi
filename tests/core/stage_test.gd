extends GdUnitTestSuite


func _level(layout: Array, goals: Dictionary, goals_2: Dictionary, moves: int = 30) -> M3LevelDef:
	var level := M3LevelDef.new()
	level.layout = PackedStringArray(layout)
	level.moves = moves
	level.rng_seed = 11
	for key in goals:
		level.goals[key] = goals[key]
	for key in goals_2:
		level.goals_2[key] = goals_2[key]
	return level


func _has_step(steps: Array, type: StringName) -> bool:
	for step in steps:
		if step.type == type:
			return true
	return false


func test_finishing_the_first_goals_opens_the_second_stage() -> void:
	var session := M3Session.new(_level(["...1..."], {M3.GOAL_BOX: 1}, {1: 5}))
	assert_int(session.stage_count()).is_equal(2)
	var steps := session.use_booster(M3.BOOSTER_SINGLE, Vector2i(3, 0))
	assert_bool(_has_step(steps, M3.STEP_STAGE)).is_true()
	assert_int(session.stage).is_equal(2)
	assert_bool(session.goals.has(M3.GOAL_BOX)).is_false()
	assert_int(session.goals[1]).is_equal(5)
	assert_int(session.goal_totals[1]).is_equal(5)
	assert_bool(session.is_won()).is_false()


func test_obstacles_broken_early_count_for_the_second_stage() -> void:
	var session := M3Session.new(_level(["1..C..."], {M3.GOAL_BOX: 1}, {M3.GOAL_KITTEN: 1}))
	session.use_booster(M3.BOOSTER_SINGLE, Vector2i(3, 0))
	session.use_booster(M3.BOOSTER_SINGLE, Vector2i(3, 0))
	session.use_booster(M3.BOOSTER_SINGLE, Vector2i(0, 0))
	assert_int(session.stage).is_equal(2)
	assert_int(session.goals[M3.GOAL_KITTEN]).is_equal(0)
	assert_int(session.goal_totals[M3.GOAL_KITTEN]).is_equal(1)
	assert_bool(session.is_won()).is_true()


func test_tiles_cleared_early_do_not_count_for_the_second_stage() -> void:
	var session := M3Session.new(_level([], {2: 99}, {1: 50}))
	session.use_booster(M3.BOOSTER_ROW, Vector2i(0, 6))
	session.use_booster(M3.BOOSTER_ROW, Vector2i(0, 5))
	assert_int(session.stage).is_equal(1)
	assert_int(session._pending[1]).is_equal(50)


func test_clone_keeps_the_stage() -> void:
	var session := M3Session.new(_level(["...1..."], {M3.GOAL_BOX: 1}, {1: 5}))
	session.use_booster(M3.BOOSTER_SINGLE, Vector2i(3, 0))
	var copy := session.clone()
	assert_int(copy.stage).is_equal(2)
	assert_dict(copy.goals).is_equal(session.goals)
	assert_bool(copy.is_won()).is_false()


func test_single_stage_levels_are_unchanged() -> void:
	var session := M3Session.new(_level(["...1..."], {M3.GOAL_BOX: 1}, {}))
	assert_int(session.stage_count()).is_equal(1)
	var steps := session.use_booster(M3.BOOSTER_SINGLE, Vector2i(3, 0))
	assert_bool(_has_step(steps, M3.STEP_STAGE)).is_false()
	assert_bool(session.is_won()).is_true()


func test_bot_can_finish_a_two_stage_level() -> void:
	var level := _level([".......", ".......", "..111..", ".......", ".......", ".......", "......."], {M3.GOAL_BOX: 3}, {1: 12}, 40)
	var wins := 0
	for s in 5:
		var def: M3LevelDef = level.duplicate()
		def.rng_seed = 100 + s
		if M3Bot.new(s + 1).play(M3Session.new(def)):
			wins += 1
	assert_int(wins).is_greater(0)
