extends GdUnitTestSuite


func _level(orders: Array, moves: int = 40) -> M3LevelDef:
	var level := M3LevelDef.new()
	level.moves = moves
	level.rng_seed = 21
	for order in orders:
		level.orders.append(order)
	return level


func _has_step(steps: Array, type: StringName) -> bool:
	for step in steps:
		if step.type == type:
			return true
	return false


func _clear_kind(session: M3Session, kind: int) -> Array:
	var i := session.board.kinds.find(kind)
	assert_int(i).override_failure_message("no tile of kind %d" % kind).is_greater_equal(0)
	return session.use_booster(M3.BOOSTER_SINGLE, session.board.pos(i))


# Pushes the dish down with sack-style drops until it is served.
func _serve_dish(session: M3Session) -> void:
	for n in 16:
		var i := session.board.kinds.find(M3.DISH)
		if i < 0:
			return
		session.swap(session.board.pos(i), session.board.pos(i) + Vector2i.DOWN)


func test_finished_order_drops_its_dish_onto_the_top_row() -> void:
	var session := M3Session.new(_level([{"dish": "menemen", "goals": {1: 1}, "patience": 20}]))
	var steps := _clear_kind(session, 1)
	assert_int(session.orders[0].state).is_equal(M3Session.ORDER_READY)
	assert_bool(_has_step(steps, M3.STEP_ORDER)).is_true()
	var dish := session.board.kinds.find(M3.DISH)
	assert_int(dish).is_between(0, session.board.width - 1)
	assert_bool(session.is_won()).is_false()


func test_serving_every_dish_wins() -> void:
	var session := M3Session.new(_level([{"dish": "menemen", "goals": {1: 1}, "patience": 30}]))
	_clear_kind(session, 1)
	_serve_dish(session)
	assert_int(session.orders[0].state).is_equal(M3Session.ORDER_SERVED)
	assert_int(session.board.kinds.find(M3.DISH)).is_equal(-1)
	assert_bool(session.is_won()).is_true()


func test_ingredients_go_to_the_first_order_that_needs_them() -> void:
	var session := M3Session.new(_level([{"goals": {2: 2}, "patience": 20}, {"goals": {2: 1, 3: 1}, "patience": 20}]))
	_clear_kind(session, 2)
	assert_int(session.orders[0].need[2]).is_equal(1)
	assert_int(session.orders[1].need[2]).is_equal(1)


func test_patience_drops_each_swap_and_running_out_loses() -> void:
	var session := M3Session.new(_level([{"goals": {1: 99}, "patience": 2}]))
	var move: Vector2i = M3MoveFinder.find_moves(session.board)[0]
	var steps := session.swap(session.board.pos(move.x), session.board.pos(move.y))
	assert_bool(_has_step(steps, M3.STEP_PATIENCE)).is_true()
	assert_int(session.orders[0].patience).is_equal(1)
	assert_bool(session.is_lost()).is_false()
	move = M3MoveFinder.find_moves(session.board)[0]
	session.swap(session.board.pos(move.x), session.board.pos(move.y))
	assert_bool(session.is_lost()).is_true()
	assert_bool(session.is_finished()).is_true()


func test_boosters_do_not_use_patience() -> void:
	var session := M3Session.new(_level([{"goals": {1: 99}, "patience": 5}]))
	_clear_kind(session, 2)
	assert_int(session.orders[0].patience).is_equal(5)


func test_dishes_never_match_or_explode() -> void:
	var board := M3Board.from_rows(PackedStringArray(["77712", "12312", "23123"]))
	assert_bool(M3Matcher.find_groups(board).is_empty()).is_true()
	var steps: Array = []
	board.specials[4] = M3.Special.LINE_H
	M3Resolver.new().clear_area(board, M3.Special.NONE, Vector2i(4, 0), steps)
	for x in 3:
		assert_int(board.kinds[x]).is_equal(M3.DISH)


func test_clone_keeps_orders_apart() -> void:
	var session := M3Session.new(_level([{"goals": {1: 3}, "patience": 9}]))
	var copy := session.clone()
	copy.orders[0].need[1] = 0
	copy.orders[0].patience = 1
	assert_int(session.orders[0].need[1]).is_equal(3)
	assert_int(session.orders[0].patience).is_equal(9)


func test_board_view_follows_dishes_and_serving() -> void:
	var session := M3Session.new(_level([{"dish": "menemen", "goals": {1: 1}, "patience": 30}]))
	var view: BoardView = auto_free(BoardView.new())
	view.animate = false
	add_child(view)
	view.size = Vector2(700, 700)
	view.setup(session.board)
	var states: Array = []
	view.order_changed.connect(func(_order: int, state: int) -> void: states.append(state))
	await view.play(_clear_kind(session, 1))
	for n in 16:
		var i := session.board.kinds.find(M3.DISH)
		if i < 0:
			break
		await view.play(session.swap(session.board.pos(i), session.board.pos(i) + Vector2i.DOWN))
	assert_bool(view.tiles_match_board()).is_true()
	assert_int(view.resyncs).is_equal(0)
	assert_array(states).is_equal([M3Session.ORDER_READY, M3Session.ORDER_SERVED])


func test_bot_can_serve_two_orders() -> void:
	var level := _level([{"goals": {1: 6}, "patience": 40}, {"goals": {3: 6}, "patience": 40}], 40)
	var wins := 0
	for s in 5:
		var def: M3LevelDef = level.duplicate()
		def.rng_seed = 300 + s
		if M3Bot.new(s + 1).play(M3Session.new(def)):
			wins += 1
	assert_int(wins).is_greater(0)
