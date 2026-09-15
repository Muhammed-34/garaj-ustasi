extends GdUnitTestSuite

const GameScript := preload("res://game/scenes/game/game.gd")
const OBSTACLE_INTROS := {M3.GOAL_BOX: "box", M3.GOAL_PAW: "paw", M3.GOAL_SACK: "sack", M3.GOAL_KNOT: "knot", M3.GOAL_KITTEN: "kitten", M3.GOAL_SLEEPER: "sleeper", M3.GOAL_FUR: "fur", M3.GOAL_CAGE: "cage", M3.GOAL_MOUSE: "mouse"}


func _on_board(session: M3Session, key: int) -> int:
	var board := session.board
	if key == M3.GOAL_PAW:
		return board.ground.count(1)
	if key == M3.GOAL_SACK:
		return board.count_sacks() + board.sacks_to_spawn
	if key == M3.GOAL_MOUSE:
		return board.mice.count(1)
	var block: int = {M3.GOAL_BOX: M3.Block.BOX, M3.GOAL_KNOT: M3.Block.KNOT, M3.GOAL_KITTEN: M3.Block.CRATE, M3.GOAL_SLEEPER: M3.Block.SLEEPER, M3.GOAL_FUR: M3.Block.FUR, M3.GOAL_CAGE: M3.Block.CAGE}[key]
	return board.blockers.count(block)


func test_every_level_file_loads_with_its_id() -> void:
	for id in range(1, Levels.COUNT + 1):
		var level := Levels.load_level(id)
		assert_object(level).is_not_null()
		assert_int(level.id).is_equal(id)


func test_goals_can_be_completed() -> void:
	for id in range(1, Levels.COUNT + 1):
		var level := Levels.load_level(id)
		var session := M3Session.new(level)
		assert_int(level.moves).is_greater(0)
		assert_bool(level.goals.is_empty()).is_false()
		for stage_goals: Dictionary in [level.goals, level.goals_2]:
			for key in stage_goals:
				assert_int(stage_goals[key]).override_failure_message("level %d goal %d" % [id, key]).is_greater(0)
				if key <= level.kind_count:
					continue
				assert_bool(OBSTACLE_INTROS.has(key)).is_true()
				assert_int(_on_board(session, key)).override_failure_message("level %d lacks goal %d" % [id, key]).is_greater_equal(stage_goals[key])


func test_second_stage_goals_never_repeat_the_first() -> void:
	var first_staged := 0
	for id in range(1, Levels.COUNT + 1):
		var level := Levels.load_level(id)
		if level.goals_2.is_empty():
			continue
		if first_staged == 0:
			first_staged = id
			assert_str(level.intro).override_failure_message("level %d should introduce stages" % id).is_equal("stages")
		for key in level.goals_2:
			assert_bool(level.goals.has(key)).override_failure_message("level %d repeats goal %d" % [id, key]).is_false()
	assert_int(first_staged).is_greater(0)


func test_hard_levels_follow_the_sawtooth_plan() -> void:
	var hard := []
	var very_hard := []
	for id in range(1, Levels.COUNT + 1):
		var difficulty := Levels.load_level(id).difficulty
		if difficulty == 1:
			hard.append(id)
		elif difficulty == 2:
			very_hard.append(id)
	assert_array(hard).is_equal([9, 19, 27, 39, 47, 57, 69, 77, 87, 99, 107, 117, 127, 137])
	assert_array(very_hard).is_equal([30, 60, 90, 120])


func test_each_mechanic_is_introduced_where_it_first_appears() -> void:
	var seen := {}
	for id in range(1, Levels.COUNT + 1):
		var level := Levels.load_level(id)
		if not level.intro.is_empty():
			assert_bool(GameScript.INTROS.has(level.intro)).override_failure_message("level %d intro %s" % [id, level.intro]).is_true()
		for key in level.goals:
			if OBSTACLE_INTROS.has(key) and not seen.has(key):
				seen[key] = true
				assert_str(level.intro).override_failure_message("level %d should introduce %s" % [id, OBSTACLE_INTROS[key]]).is_equal(OBSTACLE_INTROS[key])
	assert_int(seen.size()).is_equal(OBSTACLE_INTROS.size())


func test_rescues_happen_on_existing_levels() -> void:
	for level_id in MetaRules.RESCUE_LEVELS:
		assert_int(level_id).is_between(1, Levels.COUNT)


func test_items_fit_their_boards() -> void:
	for id in range(1, Levels.COUNT + 1):
		var level := Levels.load_level(id)
		var session := M3Session.new(level)
		# Sacks are only collected on the bottom row, so a hole would trap them.
		if level.sacks > 0:
			assert_bool(session.board.has_holes()).override_failure_message("level %d drops sacks on a shaped board" % id).is_false()
		assert_int(level.keys).override_failure_message("level %d keys" % id).is_equal(session.board.blockers.count(M3.Block.CAGE))


func test_belts_start_clear_of_obstacles() -> void:
	var first_belt := 0
	for id in range(1, Levels.COUNT + 1):
		var level := Levels.load_level(id)
		var board := M3Session.new(level).board
		if not board.has_belts():
			continue
		if first_belt == 0:
			first_belt = id
			assert_str(level.intro).override_failure_message("level %d should introduce belts" % id).is_equal("belt")
		for i in board.cell_count():
			if board.belts[i] != 0:
				assert_int(board.blockers[i]).override_failure_message("level %d belt cell %d is blocked" % [id, i]).is_equal(M3.Block.NONE)
	assert_int(first_belt).is_greater(0)


func test_every_level_starts_with_a_playable_board() -> void:
	for id in range(1, Levels.COUNT + 1):
		var session := M3Session.new(Levels.load_level(id))
		assert_bool(M3MoveFinder.has_move(session.board)).override_failure_message("level %d" % id).is_true()
