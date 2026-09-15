class_name M3Session
extends RefCounted

const ORDER_COOKING := 0
const ORDER_READY := 1
const ORDER_SERVED := 2
const BLOCK_GOALS := {M3.Block.BOX: M3.GOAL_BOX, M3.Block.KNOT: M3.GOAL_KNOT, M3.Block.CRATE: M3.GOAL_KITTEN, M3.Block.SLEEPER: M3.GOAL_SLEEPER, M3.Block.FUR: M3.GOAL_FUR, M3.Block.CAGE: M3.GOAL_CAGE}

var level: M3LevelDef
var board: M3Board
var resolver := M3Resolver.new()
var moves_left := 0
# Remaining count per goal key.
var goals := {}
# Total per goal key; starts at the level's goals and grows when fur spreads.
var goal_totals := {}
var stage := 1
# Second-stage goals while the first stage runs. Obstacles broken early already count here
# (they sit on the board from the start); tile clears do not, or the second stage would be free.
var _pending := {}
var _pending_totals := {}
# Restaurant orders: each is {"dish", "need", "total", "patience", "max_patience", "state"}.
# Ingredients go to the first cooking order that needs them; a finished order drops its dish onto the
# board, and the dish is served once it cannot fall any further. Unserved orders lose patience each swap.
var orders: Array = []


func _init(level_def: M3LevelDef, generate_board: bool = true) -> void:
	level = level_def
	board = M3Board.new(level.width, level.height, level.kind_count, level.rng_seed)
	board.apply_layout(level.layout)
	board.sacks_to_spawn = level.sacks
	board.keys_to_spawn = level.keys
	if generate_board:
		board.generate()
	moves_left = level.moves
	for kind in level.goals:
		goals[kind] = level.goals[kind]
		goal_totals[kind] = level.goals[kind]
	for kind in level.goals_2:
		_pending[kind] = level.goals_2[kind]
		_pending_totals[kind] = level.goals_2[kind]
	for order in level.orders:
		var need := {}
		for kind in order.get("goals", {}):
			need[int(kind)] = int(order.goals[kind])
		var patience := int(order.get("patience", level.moves))
		orders.append({"dish": str(order.get("dish", "")), "need": need, "total": need.duplicate(), "patience": patience, "max_patience": patience, "state": ORDER_COOKING})
	_refresh_priority()


func clone() -> M3Session:
	var copy := M3Session.new(level, false)
	copy.board = board.clone()
	copy.moves_left = moves_left
	copy.goals = goals.duplicate()
	copy.goal_totals = goal_totals.duplicate()
	copy.stage = stage
	copy._pending = _pending.duplicate()
	copy._pending_totals = _pending_totals.duplicate()
	copy.orders = orders.duplicate(true)
	copy._refresh_priority()
	return copy


func swap(a: Vector2i, b: Vector2i) -> Array:
	if is_finished():
		return []
	var steps := resolver.try_swap(board, a, b)
	if steps.is_empty():
		return []
	moves_left -= 1
	_doze(steps)
	_track_goals(steps)
	if not is_won():
		_spread(steps)
		_run_mice(steps)
		_convey(steps)
	if not is_won():
		_tick_patience(steps)
	return steps


func use_booster(booster: StringName, cell: Vector2i) -> Array:
	if is_finished():
		return []
	var steps: Array = []
	if booster == M3.BOOSTER_SINGLE:
		resolver.clear_area(board, M3.Special.NONE, cell, steps)
	elif booster == M3.BOOSTER_ROW:
		resolver.clear_area(board, M3.Special.LINE_H, cell, steps)
	elif booster == M3.BOOSTER_SHUFFLE:
		board.shuffle()
		steps.append({"type": M3.STEP_SHUFFLE, "kinds": board.kinds.duplicate(), "specials": board.specials.duplicate()})
		return steps
	else:
		return []
	if steps.is_empty():
		return []
	resolver.settle(board, steps)
	_track_goals(steps)
	return steps


# After a win, leftover moves become line specials that all fire at once.
func party(max_specials: int, rng_seed: int) -> Array:
	var steps: Array = []
	if not is_won() or moves_left <= 0:
		return steps
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var candidates := PackedInt32Array()
	for i in board.cell_count():
		if M3.is_matchable(board.kinds[i]) and board.specials[i] == M3.Special.NONE and board.blockers[i] == M3.Block.NONE:
			candidates.append(i)
	var picked := PackedInt32Array()
	for n in mini(mini(moves_left, max_specials), candidates.size()):
		var pick := rng.randi_range(0, candidates.size() - 1)
		var i := candidates[pick]
		candidates.remove_at(pick)
		var special: int = M3.Special.LINE_H if n % 2 == 0 else M3.Special.LINE_V
		board.specials[i] = special
		steps.append({"type": M3.STEP_SPECIAL, "cells": PackedInt32Array([i]), "special": special, "kind": board.kinds[i]})
		picked.append(i)
	moves_left = 0
	if picked.is_empty():
		return steps
	resolver.clear_cells(board, picked, &"party", steps)
	resolver.settle(board, steps)
	return steps


# A sleeping cat that nobody disturbed during a swap dozes off again and regains one hit.
func _doze(steps: Array) -> void:
	var disturbed := {}
	for step in steps:
		if step.type == M3.STEP_BLOCKER:
			for i in step.cells:
				disturbed[i] = true
	var cells := PackedInt32Array()
	var hp := PackedInt32Array()
	for i in board.cell_count():
		if board.blockers[i] != M3.Block.SLEEPER or disturbed.has(i) or board.blocker_hp[i] >= M3.SLEEPER_HP:
			continue
		board.blocker_hp[i] += 1
		cells.append(i)
		hp.append(board.blocker_hp[i])
	if not cells.is_empty():
		steps.append({"type": M3.STEP_DOZE, "cells": cells, "hp": hp})


# Fur that no swap cleared creeps onto one neighbouring plain tile; its goal grows with it.
func _spread(steps: Array) -> void:
	for step in steps:
		if step.type == M3.STEP_BLOCKER and step.blocks.has(M3.Block.FUR):
			return
	var pairs: Array[Vector2i] = []
	for i in board.cell_count():
		if board.blockers[i] != M3.Block.FUR:
			continue
		var p := board.pos(i)
		for d in M3Resolver.NEIGHBOURS:
			var q: Vector2i = p + d
			if not board.in_bounds(q):
				continue
			var j := board.idx(q)
			if board.blockers[j] == M3.Block.NONE and M3.is_matchable(board.kinds[j]) and board.specials[j] == M3.Special.NONE and board.mice[j] == 0:
				pairs.append(Vector2i(i, j))
	if pairs.is_empty():
		return
	var pick := pairs[board.spawn_rng.randi_range(0, pairs.size() - 1)]
	var kind := board.kinds[pick.y]
	board.set_blocker(pick.y, M3.Block.FUR, 1)
	steps.append({"type": M3.STEP_SPREAD, "from": pick.x, "to": pick.y, "kind": kind})
	if goals.has(M3.GOAL_FUR):
		goals[M3.GOAL_FUR] += 1
		goal_totals[M3.GOAL_FUR] += 1
		steps.append({"type": M3.STEP_GOAL, "remaining": goals.duplicate()})
		_refresh_priority()
	elif _pending.has(M3.GOAL_FUR):
		_pending[M3.GOAL_FUR] += 1
		_pending_totals[M3.GOAL_FUR] += 1
	if not M3MoveFinder.has_move(board):
		board.shuffle()
		steps.append({"type": M3.STEP_SHUFFLE, "kinds": board.kinds.duplicate(), "specials": board.specials.duplicate()})


# Every mouse that survived the swap scurries to a random neighbouring plain tile.
# Two mice never share a cell; a mouse with nowhere to go stays put.
func _run_mice(steps: Array) -> void:
	var runners := PackedInt32Array()
	for i in board.cell_count():
		if board.mice[i] > 0:
			runners.append(i)
	var moves: Array[Vector2i] = []
	for i in runners:
		var p := board.pos(i)
		var options := PackedInt32Array()
		for d in M3Resolver.NEIGHBOURS:
			var q: Vector2i = p + d
			if not board.in_bounds(q):
				continue
			var j := board.idx(q)
			if board.mice[j] == 0 and board.blockers[j] == M3.Block.NONE and M3.is_matchable(board.kinds[j]):
				options.append(j)
		if options.is_empty():
			continue
		var target := options[board.spawn_rng.randi_range(0, options.size() - 1)]
		board.mice[i] = 0
		board.mice[target] = 1
		moves.append(Vector2i(i, target))
	if not moves.is_empty():
		steps.append({"type": M3.STEP_RUN, "moves": moves})


# Belts turn once per swap; matches the belt lines up resolve and count like any others.
func _convey(steps: Array) -> void:
	var moves := board.convey()
	if moves.is_empty():
		return
	var belt_steps: Array = [{"type": M3.STEP_BELT, "moves": moves}]
	resolver.settle(board, belt_steps)
	_track_goals(belt_steps)
	steps.append_array(belt_steps)


func _tick_patience(steps: Array) -> void:
	if orders.is_empty():
		return
	var values := PackedInt32Array()
	for order in orders:
		if order.state != ORDER_SERVED:
			order.patience = maxi(int(order.patience) - 1, 0)
		values.append(order.patience)
	steps.append({"type": M3.STEP_PATIENCE, "patience": values})


# Serves ready orders for dishes that reached the bottom, then drops a dish for every order whose
# ingredients are complete.
func _update_orders(steps: Array, served: int) -> void:
	for n in orders.size():
		var order: Dictionary = orders[n]
		if served > 0 and order.state == ORDER_READY:
			order.state = ORDER_SERVED
			served -= 1
			steps.append({"type": M3.STEP_ORDER, "order": n, "state": ORDER_SERVED})
	var placed := false
	for n in orders.size():
		var order: Dictionary = orders[n]
		if order.state != ORDER_COOKING or not _order_complete(order):
			continue
		order.state = ORDER_READY
		var cell := _place_dish()
		placed = placed or cell >= 0
		steps.append({"type": M3.STEP_ORDER, "order": n, "state": ORDER_READY, "cell": cell})
	if placed and not M3MoveFinder.has_move(board):
		board.shuffle()
		steps.append({"type": M3.STEP_SHUFFLE, "kinds": board.kinds.duplicate(), "specials": board.specials.duplicate()})


func _order_complete(order: Dictionary) -> bool:
	for kind in order.need:
		if int(order.need[kind]) > 0:
			return false
	return true


# The dish replaces a plain tile at the top of a random column, or waits for the next refill.
func _place_dish() -> int:
	var options := PackedInt32Array()
	for x in board.width:
		for y in board.height:
			var i := y * board.width + x
			if board.is_hole(i):
				continue
			if board.blockers[i] == M3.Block.NONE and M3.is_matchable(board.kinds[i]) and board.specials[i] == M3.Special.NONE and board.mice[i] == 0:
				options.append(i)
			break
	if options.is_empty():
		board.dishes_to_spawn += 1
		return -1
	var cell := options[board.spawn_rng.randi_range(0, options.size() - 1)]
	board.kinds[cell] = M3.DISH
	return cell


func _count_for_order(kind: int) -> bool:
	for order in orders:
		if order.state == ORDER_COOKING and int(order.need.get(kind, 0)) > 0:
			order.need[kind] -= 1
			return true
	return false


func served_count() -> int:
	var count := 0
	for order in orders:
		if order.state == ORDER_SERVED:
			count += 1
	return count


func add_moves(amount: int) -> void:
	moves_left += amount


func stage_count() -> int:
	return 1 if level.goals_2.is_empty() else 2


func is_won() -> bool:
	if stage < stage_count():
		return false
	for kind in goals:
		if goals[kind] > 0:
			return false
	for order in orders:
		if order.state != ORDER_SERVED:
			return false
	return true


func is_lost() -> bool:
	if is_won():
		return false
	if moves_left <= 0:
		return true
	for order in orders:
		if order.state != ORDER_SERVED and int(order.patience) <= 0:
			return true
	return false


func is_finished() -> bool:
	return is_won() or is_lost()


func _track_goals(steps: Array) -> void:
	var served := 0
	for step in steps:
		if step.type == M3.STEP_COLLECT and step.get("dish", false):
			served += step.cells.size()
			continue
		if step.type == M3.STEP_CLEAR:
			for kind in step.kinds:
				_count_goal(kind)
		elif step.type == M3.STEP_GROUND:
			for hp in step.hp:
				if hp == 0:
					_count_goal(M3.GOAL_PAW)
		elif step.type == M3.STEP_CATCH:
			for cell in step.cells:
				_count_goal(M3.GOAL_MOUSE)
		elif step.type == M3.STEP_COLLECT and not step.get("key", false):
			for cell in step.cells:
				_count_goal(M3.GOAL_SACK)
		elif step.type == M3.STEP_BLOCKER:
			for n in step.cells.size():
				if step.hp[n] == 0:
					_count_goal(BLOCK_GOALS[step.blocks[n]])
	_update_orders(steps, served)
	steps.append({"type": M3.STEP_GOAL, "remaining": goals.duplicate()})
	if _advance_stage():
		steps.append({"type": M3.STEP_STAGE, "stage": stage, "goals": goals.duplicate()})
		steps.append({"type": M3.STEP_GOAL, "remaining": goals.duplicate()})
	_refresh_priority()


func _count_goal(key: int) -> void:
	if key < M3.DISH and _count_for_order(key):
		return
	if goals.has(key) and goals[key] > 0:
		goals[key] -= 1
	elif stage < stage_count() and key > M3.SACK and int(_pending.get(key, 0)) > 0:
		_pending[key] -= 1


# Once every first-stage goal is done, the second-stage goals take their place.
func _advance_stage() -> bool:
	if stage >= stage_count():
		return false
	for kind in goals:
		if goals[kind] > 0:
			return false
	stage += 1
	goals = _pending.duplicate()
	goal_totals = _pending_totals.duplicate()
	_pending.clear()
	_pending_totals.clear()
	return true


func _refresh_priority() -> void:
	var active := PackedInt32Array()
	for kind in goals:
		if goals[kind] > 0:
			active.append(kind)
	for order in orders:
		if order.state != ORDER_COOKING:
			continue
		for kind in order.need:
			if int(order.need[kind]) > 0 and not active.has(kind):
				active.append(kind)
	resolver.priority_kinds = active
