extends GdUnitTestSuite

const BoardTest := preload("res://tests/core/board_test.gd")


func _first(steps: Array, type: StringName) -> Dictionary:
	for step in steps:
		if step.type == type:
			return step
	return {}


func _clear_at(board: M3Board, cell: Vector2i, special: int = M3.Special.NONE) -> Array:
	var steps: Array = []
	var resolver := M3Resolver.new()
	if special != M3.Special.NONE:
		board.specials[board.idx(cell)] = special
	resolver.clear_area(board, M3.Special.NONE, cell, steps)
	return steps


func _level(layout: Array, goals: Dictionary, moves: int = 30, sacks: int = 0) -> M3LevelDef:
	var level := M3LevelDef.new()
	level.layout = PackedStringArray(layout)
	level.moves = moves
	level.sacks = sacks
	level.rng_seed = 11
	for key in goals:
		level.goals[key] = goals[key]
	return level


func test_layout_places_every_obstacle() -> void:
	var board := M3Board.new(3, 2)
	board.apply_layout(PackedStringArray(["12C", "KP."]))
	assert_array(Array(board.blockers)).is_equal([M3.Block.BOX, M3.Block.BOX, M3.Block.CRATE, M3.Block.KNOT, M3.Block.NONE, M3.Block.NONE])
	assert_array(Array(board.blocker_hp)).is_equal([1, 2, 2, 1, 0, 0])
	assert_int(board.ground[4]).is_equal(1)
	assert_bool(board.is_open(0)).is_false()
	assert_bool(board.is_open(3)).is_true()


func test_generated_board_leaves_boxes_empty_and_fills_the_rest() -> void:
	var board := M3Board.new(7, 7, 5, 4)
	board.apply_layout(PackedStringArray([".......", ".......", "..222..", "..K.K..", ".......", "PPPPPPP", "......."]))
	board.generate()
	assert_int(board.kinds[board.idx(Vector2i(2, 2))]).is_equal(M3.EMPTY)
	assert_bool(board.is_full()).is_true()
	assert_bool(M3Matcher.find_groups(board).is_empty()).is_true()
	assert_int(board.kinds[board.idx(Vector2i(2, 3))]).is_between(1, 5)


func test_box_takes_one_hit_per_clear() -> void:
	var board := BoardTest.pattern(5, 3)
	board.set_blocker(board.idx(Vector2i(2, 1)), M3.Block.BOX, 2)
	var steps := _clear_at(board, Vector2i(0, 1), M3.Special.LINE_H)
	assert_int(board.blocker_hp[board.idx(Vector2i(2, 1))]).is_equal(1)
	assert_array(Array(_first(steps, M3.STEP_BLOCKER).hp)).is_equal([1])


func test_clearing_next_to_a_box_breaks_it() -> void:
	var board := BoardTest.pattern(5, 3)
	var box := board.idx(Vector2i(2, 1))
	board.set_blocker(box, M3.Block.BOX, 1)
	_clear_at(board, Vector2i(1, 1))
	assert_int(board.blockers[box]).is_equal(M3.Block.NONE)
	assert_bool(board.is_open(box)).is_true()


func test_boxes_split_column_gravity() -> void:
	var board := BoardTest.pattern(5, 3)
	board.set_blocker(board.idx(Vector2i(2, 1)), M3.Block.BOX, 2)
	var top := board.kinds[board.idx(Vector2i(2, 0))]
	var steps := _clear_at(board, Vector2i(2, 2))
	M3Resolver.new().settle(board, steps)
	assert_int(board.kinds[board.idx(Vector2i(2, 0))]).is_equal(top)
	assert_bool(board.is_full()).is_true()


func test_knots_cannot_be_swapped() -> void:
	var board := M3Board.from_rows(PackedStringArray(["11213", "23121", "31232"]))
	board.set_blocker(board.idx(Vector2i(2, 1)), M3.Block.KNOT, 1)
	assert_array(M3Resolver.new().try_swap(board, Vector2i(2, 0), Vector2i(2, 1))).is_empty()
	for move in M3MoveFinder.find_moves(board):
		assert_bool(move.x == 7 or move.y == 7).is_false()


func test_knot_pins_its_tile_and_goes_with_it() -> void:
	var board := BoardTest.pattern(5, 3)
	var knot := board.idx(Vector2i(2, 1))
	board.set_blocker(knot, M3.Block.KNOT, 1)
	var kind := board.kinds[knot]
	var steps := _clear_at(board, Vector2i(2, 2))
	M3Resolver.new().settle(board, steps)
	assert_int(board.kinds[knot]).is_equal(kind)
	assert_int(board.blockers[knot]).is_equal(M3.Block.KNOT)
	_clear_at(board, Vector2i(2, 1))
	assert_int(board.blockers[knot]).is_equal(M3.Block.NONE)


func test_paw_print_fades_when_its_tile_clears() -> void:
	var board := BoardTest.pattern(5, 3)
	board.ground[6] = 1
	var steps := _clear_at(board, Vector2i(1, 1))
	assert_int(board.ground[6]).is_equal(0)
	assert_array(Array(_first(steps, M3.STEP_GROUND).cells)).is_equal([6])


func test_sacks_never_match() -> void:
	var board := M3Board.from_rows(PackedStringArray(["SSS12", "12312", "23123"]))
	assert_bool(M3Matcher.find_groups(board).is_empty()).is_true()
	assert_bool(M3Matcher.has_match_at(board, 0)).is_false()


func test_sacks_survive_blasts_and_are_collected_at_the_bottom() -> void:
	var board := BoardTest.pattern(5, 3)
	board.kinds[board.idx(Vector2i(2, 1))] = M3.SACK
	var steps := _clear_at(board, Vector2i(0, 2), M3.Special.LINE_H)
	assert_bool(Array(_first(steps, M3.STEP_CLEAR).kinds).has(M3.SACK)).is_false()
	M3Resolver.new().settle(board, steps)
	assert_array(Array(_first(steps, M3.STEP_COLLECT).cells)).is_equal([board.idx(Vector2i(2, 2))])
	assert_int(board.count_sacks()).is_equal(0)


func test_sack_can_be_pushed_down_without_a_match() -> void:
	var board := M3Board.from_rows(PackedStringArray(["12312", "23S23", "31231"]))
	var sack := board.idx(Vector2i(2, 1))
	var below := board.idx(Vector2i(2, 2))
	assert_bool(M3MoveFinder.find_moves(board).has(Vector2i(sack, below))).is_true()
	var steps := M3Resolver.new().try_swap(board, Vector2i(2, 1), Vector2i(2, 2))
	assert_array(Array(_first(steps, M3.STEP_COLLECT).cells)).is_equal([below])
	assert_int(board.count_sacks()).is_equal(0)


func test_sack_cannot_be_pushed_up_or_sideways_without_a_match() -> void:
	var board := M3Board.from_rows(PackedStringArray(["12312", "23S23", "31231"]))
	assert_array(M3Resolver.new().try_swap(board, Vector2i(2, 1), Vector2i(2, 0))).is_empty()
	assert_array(M3Resolver.new().try_swap(board, Vector2i(2, 1), Vector2i(1, 1))).is_empty()


func test_sack_levels_start_with_two_sacks_and_spawn_the_rest() -> void:
	var session := M3Session.new(_level([], {M3.GOAL_SACK: 3}, 30, 3))
	assert_int(session.board.count_sacks()).is_equal(2)
	assert_int(session.board.sacks_to_spawn).is_equal(1)


func test_session_counts_obstacle_goals() -> void:
	var session := M3Session.new(_level(["...1..."], {M3.GOAL_BOX: 1}))
	session.use_booster(M3.BOOSTER_SINGLE, Vector2i(3, 0))
	assert_int(session.goals[M3.GOAL_BOX]).is_equal(0)
	assert_bool(session.is_won()).is_true()


func test_crate_counts_as_a_kitten_after_two_hits() -> void:
	var session := M3Session.new(_level(["...C..."], {M3.GOAL_KITTEN: 1}))
	session.use_booster(M3.BOOSTER_SINGLE, Vector2i(3, 0))
	assert_int(session.goals[M3.GOAL_KITTEN]).is_equal(1)
	session.use_booster(M3.BOOSTER_SINGLE, Vector2i(3, 0))
	assert_int(session.goals[M3.GOAL_KITTEN]).is_equal(0)


func test_sleeping_cat_fills_its_cell_and_wakes_after_three_nudges() -> void:
	var board := BoardTest.pattern(5, 3)
	board.apply_layout(PackedStringArray(["..Z.."]))
	var cat := board.idx(Vector2i(2, 0))
	assert_int(board.blocker_hp[cat]).is_equal(M3.SLEEPER_HP)
	assert_bool(board.is_open(cat)).is_false()
	assert_int(board.kinds[cat]).is_equal(M3.EMPTY)
	for n in M3.SLEEPER_HP:
		var steps := _clear_at(board, Vector2i(2, 1))
		M3Resolver.new().settle(board, steps)
	assert_int(board.blockers[cat]).is_equal(M3.Block.NONE)


# The valid move whose nearer cell lies farthest from the given cell.
func _farthest_move(board: M3Board, from: int) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := -1
	for move in M3MoveFinder.find_moves(board):
		var a := board.pos(move.x) - board.pos(from)
		var b := board.pos(move.y) - board.pos(from)
		var distance := mini(absi(a.x) + absi(a.y), absi(b.x) + absi(b.y))
		if distance > best_distance:
			best_distance = distance
			best = move
	return best


func test_undisturbed_sleeping_cat_dozes_off_after_a_swap() -> void:
	var session := M3Session.new(_level(["Z......"], {M3.GOAL_SLEEPER: 1, 1: 99}))
	session.board.blocker_hp[0] = 1
	var far := _farthest_move(session.board, 0)
	assert_that(far).override_failure_message("no move far from the cat").is_not_equal(Vector2i(-1, -1))
	var steps := session.swap(session.board.pos(far.x), session.board.pos(far.y))
	assert_int(session.board.blocker_hp[0]).is_equal(2)
	assert_array(Array(_first(steps, M3.STEP_DOZE).get("cells", PackedInt32Array()))).is_equal([0])


func test_boosters_do_not_give_a_sleeping_cat_time_to_doze() -> void:
	var session := M3Session.new(_level(["Z......"], {M3.GOAL_SLEEPER: 1, 1: 99}))
	session.board.blocker_hp[0] = 1
	var steps := session.use_booster(M3.BOOSTER_SINGLE, Vector2i(6, 6))
	assert_bool(steps.is_empty()).is_false()
	assert_int(session.board.blocker_hp[0]).is_equal(1)
	assert_bool(_first(steps, M3.STEP_DOZE).is_empty()).is_true()


func test_waking_every_sleeping_cat_counts_the_goal() -> void:
	var session := M3Session.new(_level(["...Z..."], {M3.GOAL_SLEEPER: 1}))
	for n in M3.SLEEPER_HP:
		session.use_booster(M3.BOOSTER_SINGLE, Vector2i(2, 0))
	assert_int(session.goals[M3.GOAL_SLEEPER]).is_equal(0)
	assert_bool(session.is_won()).is_true()


func _fur_count(board: M3Board) -> int:
	return board.blockers.count(M3.Block.FUR)


func test_fur_closes_its_cell_and_clears_with_one_nudge() -> void:
	var board := BoardTest.pattern(5, 3)
	board.apply_layout(PackedStringArray(["..F.."]))
	var fur := board.idx(Vector2i(2, 0))
	assert_bool(board.is_open(fur)).is_false()
	assert_int(board.kinds[fur]).is_equal(M3.EMPTY)
	_clear_at(board, Vector2i(2, 1))
	assert_int(board.blockers[fur]).is_equal(M3.Block.NONE)


func test_untouched_fur_spreads_and_its_goal_grows() -> void:
	var session := M3Session.new(_level(["F......"], {M3.GOAL_FUR: 1, 1: 99}))
	var far := _farthest_move(session.board, 0)
	var steps := session.swap(session.board.pos(far.x), session.board.pos(far.y))
	var spread := _first(steps, M3.STEP_SPREAD)
	assert_bool(spread.is_empty()).is_false()
	assert_int(spread.from).is_equal(0)
	assert_array([1, 7]).contains([spread.to])
	assert_int(_fur_count(session.board)).is_equal(2)
	assert_int(session.goals[M3.GOAL_FUR]).is_equal(2)
	assert_int(session.goal_totals[M3.GOAL_FUR]).is_equal(2)


func test_clearing_fur_during_a_swap_stops_the_spread() -> void:
	var session := M3Session.new(_level(["F.....F"], {M3.GOAL_FUR: 2, 1: 99}))
	var steps: Array = [{"type": M3.STEP_BLOCKER, "cells": PackedInt32Array([6]), "blocks": PackedInt32Array([M3.Block.FUR]), "hp": PackedInt32Array([0])}]
	session._spread(steps)
	assert_bool(_first(steps, M3.STEP_SPREAD).is_empty()).is_true()
	assert_int(_fur_count(session.board)).is_equal(2)


func test_boosters_do_not_make_fur_spread() -> void:
	var session := M3Session.new(_level(["F......"], {M3.GOAL_FUR: 1, 1: 99}))
	var steps := session.use_booster(M3.BOOSTER_SINGLE, Vector2i(6, 6))
	assert_bool(steps.is_empty()).is_false()
	assert_bool(_first(steps, M3.STEP_SPREAD).is_empty()).is_true()
	assert_int(_fur_count(session.board)).is_equal(1)


func test_holes_stay_empty_and_survive_blasts() -> void:
	var board := BoardTest.pattern(5, 3)
	board.apply_layout(PackedStringArray(["..#.."]))
	var hole := board.idx(Vector2i(2, 0))
	assert_bool(board.is_hole(hole)).is_true()
	assert_bool(board.is_open(hole)).is_false()
	assert_int(board.kinds[hole]).is_equal(M3.EMPTY)
	var steps := _clear_at(board, Vector2i(0, 0), M3.Special.LINE_H)
	_clear_at(board, Vector2i(2, 1))
	M3Resolver.new().settle(board, steps)
	assert_bool(board.is_hole(hole)).is_true()
	assert_int(board.kinds[hole]).is_equal(M3.EMPTY)
	assert_bool(_first(steps, M3.STEP_BLOCKER).is_empty()).is_true()


func test_tiles_do_not_fall_through_a_hole() -> void:
	var board := BoardTest.pattern(5, 3)
	board.apply_layout(PackedStringArray([".....", "..#.."]))
	var above := board.kinds[board.idx(Vector2i(2, 0))]
	var steps := _clear_at(board, Vector2i(2, 2))
	M3Resolver.new().settle(board, steps)
	assert_int(board.kinds[board.idx(Vector2i(2, 0))]).is_equal(above)
	assert_bool(board.is_full()).is_true()
	assert_int(board.kinds[board.idx(Vector2i(2, 1))]).is_equal(M3.EMPTY)


func test_shaped_board_starts_full_and_playable() -> void:
	var session := M3Session.new(_level(["#..#..#", ".......", ".......", ".......", "#.....#", "##...##", "###.###"], {1: 10}))
	assert_bool(session.board.is_full()).is_true()
	assert_bool(M3Matcher.find_groups(session.board).is_empty()).is_true()
	assert_bool(M3MoveFinder.has_move(session.board)).is_true()
	assert_int(session.board.kinds[0]).is_equal(M3.EMPTY)


func _with_keys(level: M3LevelDef, keys: int) -> M3LevelDef:
	level.keys = keys
	return level


func test_cage_closes_its_cell_and_ignores_blasts() -> void:
	var board := BoardTest.pattern(5, 3)
	board.apply_layout(PackedStringArray(["..G.."]))
	var cage := board.idx(Vector2i(2, 0))
	assert_bool(board.is_open(cage)).is_false()
	var steps := _clear_at(board, Vector2i(0, 1), M3.Special.LINE_H)
	_clear_at(board, Vector2i(2, 1))
	assert_int(board.blockers[cage]).is_equal(M3.Block.CAGE)
	assert_bool(_first(steps, M3.STEP_BLOCKER).is_empty()).is_true()


func test_keys_never_match_or_explode() -> void:
	var board := M3Board.from_rows(PackedStringArray(["YYY12", "12312", "23123"]))
	assert_bool(M3Matcher.find_groups(board).is_empty()).is_true()
	_clear_at(board, Vector2i(3, 0), M3.Special.LINE_H)
	for x in 3:
		assert_int(board.kinds[x]).is_equal(M3.KEY)


func test_key_at_the_bottom_opens_the_nearest_cage() -> void:
	var board := M3Board.from_rows(PackedStringArray(["12312", "23Y23", "31231"]))
	var near := board.idx(Vector2i(4, 2))
	var far := board.idx(Vector2i(0, 0))
	board.set_blocker(near, M3.Block.CAGE, 1)
	board.set_blocker(far, M3.Block.CAGE, 1)
	var steps := M3Resolver.new().try_swap(board, Vector2i(2, 1), Vector2i(2, 2))
	var collect := _first(steps, M3.STEP_COLLECT)
	assert_array(Array(collect.cells)).is_equal([board.idx(Vector2i(2, 2))])
	assert_bool(collect.get("key", false)).is_true()
	assert_int(board.blockers[near]).is_equal(M3.Block.NONE)
	assert_int(board.blockers[far]).is_equal(M3.Block.CAGE)


func test_key_resting_on_an_obstacle_is_collected() -> void:
	var board := M3Board.from_rows(PackedStringArray(["12Y12", "23123", "31231"]))
	board.set_blocker(board.idx(Vector2i(2, 1)), M3.Block.BOX, 1)
	var cage := board.idx(Vector2i(4, 2))
	board.set_blocker(cage, M3.Block.CAGE, 1)
	var steps: Array = []
	M3Resolver.new().settle(board, steps)
	assert_int(board.count_keys()).is_equal(0)
	assert_int(board.blockers[cage]).is_equal(M3.Block.NONE)


func test_opened_cages_count_the_goal_and_sacks_do_not() -> void:
	var session := M3Session.new(_with_keys(_level([".......", ".......", ".......", "...G..."], {M3.GOAL_CAGE: 1, M3.GOAL_SACK: 5}), 1))
	assert_int(session.board.count_keys()).is_equal(1)
	for n in 12:
		var key := session.board.kinds.find(M3.KEY)
		if key < 0:
			break
		session.swap(session.board.pos(key), session.board.pos(key) + Vector2i.DOWN)
	assert_int(session.goals[M3.GOAL_CAGE]).is_equal(0)
	assert_int(session.goals[M3.GOAL_SACK]).is_equal(5)


func test_mouse_sits_on_a_tile_and_is_caught_when_it_clears() -> void:
	var board := BoardTest.pattern(5, 3)
	board.apply_layout(PackedStringArray([".....", "..M.."]))
	var mouse := board.idx(Vector2i(2, 1))
	assert_int(board.mice[mouse]).is_equal(1)
	assert_bool(board.is_open(mouse)).is_true()
	assert_int(board.kinds[mouse]).is_between(1, 5)
	var steps := _clear_at(board, Vector2i(2, 1))
	assert_int(board.mice[mouse]).is_equal(0)
	assert_array(Array(_first(steps, M3.STEP_CATCH).cells)).is_equal([mouse])


func test_uncaught_mouse_runs_to_a_neighbouring_tile_after_a_swap() -> void:
	var session := M3Session.new(_level([".......", ".......", ".......", "...M..."], {M3.GOAL_MOUSE: 1, 1: 99}))
	var start := session.board.idx(Vector2i(3, 3))
	var far := _farthest_move(session.board, start)
	var steps := session.swap(session.board.pos(far.x), session.board.pos(far.y))
	var run := _first(steps, M3.STEP_RUN)
	assert_bool(run.is_empty()).override_failure_message("mouse did not run").is_false()
	var move: Vector2i = run.moves[0]
	assert_int(move.x).is_equal(start)
	var d := session.board.pos(move.y) - session.board.pos(start)
	assert_int(absi(d.x) + absi(d.y)).is_equal(1)
	assert_int(session.board.mice.count(1)).is_equal(1)
	assert_int(session.board.mice[move.y]).is_equal(1)


func test_mouse_never_runs_onto_an_obstacle() -> void:
	var session := M3Session.new(_level(["...1...", "..1M1..", "......."], {M3.GOAL_MOUSE: 1, 1: 99}))
	var start := session.board.idx(Vector2i(3, 1))
	var far := _farthest_move(session.board, start)
	var steps := session.swap(session.board.pos(far.x), session.board.pos(far.y))
	var run := _first(steps, M3.STEP_RUN)
	assert_bool(run.is_empty()).is_false()
	assert_int(run.moves[0].y).is_equal(session.board.idx(Vector2i(3, 2)))


func test_boosters_do_not_make_mice_run() -> void:
	var session := M3Session.new(_level([".......", ".......", ".......", "...M..."], {M3.GOAL_MOUSE: 1, 1: 99}))
	var steps := session.use_booster(M3.BOOSTER_SINGLE, Vector2i(0, 0))
	assert_bool(_first(steps, M3.STEP_RUN).is_empty()).is_true()
	assert_int(session.board.mice[session.board.idx(Vector2i(3, 3))]).is_equal(1)


func test_catching_every_mouse_wins() -> void:
	var session := M3Session.new(_level([".......", ".......", ".......", "...M..."], {M3.GOAL_MOUSE: 1}))
	session.use_booster(M3.BOOSTER_SINGLE, Vector2i(3, 3))
	assert_int(session.goals[M3.GOAL_MOUSE]).is_equal(0)
	assert_bool(session.is_won()).is_true()


func test_plain_levels_keep_their_random_sequence() -> void:
	var level := _level([], {1: 10})
	var a := M3Session.new(level)
	var b := M3Board.new(7, 7, 5, level.rng_seed)
	b.generate()
	assert_array(Array(a.board.kinds)).is_equal(Array(b.kinds))


func test_bot_can_finish_each_obstacle_type() -> void:
	var levels := [
		_level([".......", ".......", "1111111", ".......", ".......", ".......", "......."], {M3.GOAL_BOX: 7}, 40),
		_level([".......", ".......", ".......", "..PPP..", "..PPP..", ".......", "......."], {M3.GOAL_PAW: 6}, 40),
		_level([], {M3.GOAL_SACK: 3}, 40, 3),
		_level([".......", ".......", ".K...K.", ".......", ".K...K.", ".......", "......."], {M3.GOAL_KNOT: 4}, 40),
		_level([".......", ".......", ".......", "...C...", ".......", ".......", "......."], {M3.GOAL_KITTEN: 1}, 40),
		_level([".......", ".......", ".Z...Z.", ".......", ".......", ".......", "......."], {M3.GOAL_SLEEPER: 2}, 40),
		_level([".......", ".......", ".......", "..FFF..", ".......", ".......", "......."], {M3.GOAL_FUR: 3}, 40),
		_level(["###.###", "##...##", "#.....#", ".......", "#.....#", "##...##", "###.###"], {1: 10}, 40),
		_with_keys(_level([".......", "..G.G..", ".......", ".......", ".......", ".......", "......."], {M3.GOAL_CAGE: 2}, 40), 2),
		_level([".......", ".M...M.", ".......", ".......", ".......", ".......", "......."], {M3.GOAL_MOUSE: 2}, 40),
	]
	for level in levels:
		var wins := 0
		for s in 5:
			var def: M3LevelDef = level.duplicate()
			def.rng_seed = 100 + s
			if M3Bot.new(s + 1).play(M3Session.new(def)):
				wins += 1
		assert_int(wins).override_failure_message("goals %s never won" % str(level.goals)).is_greater(0)
