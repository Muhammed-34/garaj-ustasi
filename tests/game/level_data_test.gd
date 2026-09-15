extends GdUnitTestSuite

const GameScript := preload("res://game/scenes/game/game.gd")
const OBSTACLE_INTROS := {M3.GOAL_BOX: "box", M3.GOAL_PAW: "paw", M3.GOAL_KNOT: "knot", M3.GOAL_KITTEN: "kitten", M3.GOAL_MOUSE: "mouse"}
const RECIPE_STEP := 5


func _on_board(session: M3Session, key: int) -> int:
	var board := session.board
	if key == M3.GOAL_PAW:
		return board.ground.count(1)
	if key == M3.GOAL_MOUSE:
		return board.mice.count(1)
	var block: int = {M3.GOAL_BOX: M3.Block.BOX, M3.GOAL_KNOT: M3.Block.KNOT, M3.GOAL_KITTEN: M3.Block.CRATE}[key]
	return board.blockers.count(block)


func test_every_level_file_loads_with_its_id() -> void:
	for id in range(1, Levels.COUNT + 1):
		var level := Levels.load_level(id)
		assert_object(level).is_not_null()
		assert_int(level.id).is_equal(id)


func test_every_level_serves_orders_that_can_be_cooked() -> void:
	for id in range(1, Levels.COUNT + 1):
		var level := Levels.load_level(id)
		assert_int(level.orders.size()).override_failure_message("level %d has no order" % id).is_between(1, 3)
		for order in level.orders:
			assert_bool(AtlasData.SPRITES.has("dish_%s" % order.dish)).override_failure_message("level %d dish %s" % [id, order.dish]).is_true()
			assert_int(int(order.patience)).override_failure_message("level %d patience" % id).is_between(1, level.moves)
			assert_bool(order.goals.is_empty()).is_false()
			for kind in order.goals:
				assert_int(int(kind)).is_between(1, level.kind_count)
				assert_int(int(order.goals[kind])).override_failure_message("level %d ingredient %d" % [id, kind]).is_greater(0)


func test_obstacle_goals_are_on_the_board() -> void:
	for id in range(1, Levels.COUNT + 1):
		var level := Levels.load_level(id)
		var session := M3Session.new(level)
		for key in level.goals:
			assert_bool(OBSTACLE_INTROS.has(key)).override_failure_message("level %d goal %d" % [id, key]).is_true()
			assert_int(level.goals[key]).is_greater(0)
			assert_int(_on_board(session, key)).override_failure_message("level %d lacks goal %d" % [id, key]).is_greater_equal(level.goals[key])


func test_each_recipe_first_appears_when_the_book_gains_it() -> void:
	var first := {}
	for id in range(1, Levels.COUNT + 1):
		for order in Levels.load_level(id).orders:
			if not first.has(order.dish):
				first[order.dish] = id
	for n in MetaRules.RECIPES.size():
		var recipe_id: String = MetaRules.RECIPES[n].id
		assert_int(int(first.get(recipe_id, 0))).override_failure_message("recipe %s" % recipe_id).is_equal(1 + n * RECIPE_STEP)


func test_hard_levels_follow_the_sawtooth_plan() -> void:
	var hard := []
	var very_hard := []
	for id in range(1, Levels.COUNT + 1):
		var difficulty := Levels.load_level(id).difficulty
		if difficulty == 1:
			hard.append(id)
		elif difficulty == 2:
			very_hard.append(id)
	assert_array(hard).is_equal([9, 19, 27, 39, 47, 57])
	assert_array(very_hard).is_equal([30, 60])


func test_each_mechanic_is_introduced_where_it_first_appears() -> void:
	var seen := {}
	var first_tables := 0
	for id in range(1, Levels.COUNT + 1):
		var level := Levels.load_level(id)
		if not level.intro.is_empty():
			assert_bool(GameScript.INTROS.has(level.intro)).override_failure_message("level %d intro %s" % [id, level.intro]).is_true()
		if level.orders.size() > 1 and first_tables == 0:
			first_tables = id
			assert_str(level.intro).override_failure_message("level %d should introduce tables" % id).is_equal("tables")
		for key in level.goals:
			if OBSTACLE_INTROS.has(key) and not seen.has(key):
				seen[key] = true
				assert_str(level.intro).override_failure_message("level %d should introduce %s" % [id, OBSTACLE_INTROS[key]]).is_equal(OBSTACLE_INTROS[key])
	assert_int(seen.size()).is_equal(OBSTACLE_INTROS.size())
	assert_int(first_tables).is_greater(0)


func test_rescues_happen_on_existing_levels() -> void:
	for level_id in MetaRules.RESCUE_LEVELS:
		assert_int(level_id).is_between(1, Levels.COUNT)


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
