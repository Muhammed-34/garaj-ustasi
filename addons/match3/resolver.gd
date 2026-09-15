class_name M3Resolver
extends RefCounted

const NEIGHBOURS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

# Active goal keys: tile kinds and M3.GOAL_* values. Flyers aim at these first.
var priority_kinds := PackedInt32Array()


func _is_goal_target(board: M3Board, j: int) -> bool:
	var block := board.blockers[j]
	if block == M3.Block.BOX and priority_kinds.has(M3.GOAL_BOX):
		return true
	if block == M3.Block.CRATE and priority_kinds.has(M3.GOAL_KITTEN):
		return true
	if block == M3.Block.KNOT and priority_kinds.has(M3.GOAL_KNOT):
		return true
	if block == M3.Block.SLEEPER and priority_kinds.has(M3.GOAL_SLEEPER):
		return true
	if block == M3.Block.FUR and priority_kinds.has(M3.GOAL_FUR):
		return true
	if board.ground[j] > 0 and priority_kinds.has(M3.GOAL_PAW):
		return true
	if board.mice[j] > 0 and priority_kinds.has(M3.GOAL_MOUSE):
		return true
	return board.is_occupied(j) and priority_kinds.has(board.kinds[j])


func try_swap(board: M3Board, a: Vector2i, b: Vector2i) -> Array:
	if not board.in_bounds(a) or not board.in_bounds(b):
		return []
	if absi(a.x - b.x) + absi(a.y - b.y) != 1:
		return []
	var ia := board.idx(a)
	var ib := board.idx(b)
	if not board.is_swappable(ia) or not board.is_swappable(ib):
		return []
	var sa := board.specials[ia]
	var sb := board.specials[ib]
	var steps: Array = []
	var sack_drop := M3MoveFinder.is_sack_drop(board, ia, ib)
	board.swap_cells(ia, ib)
	if sa == M3.Special.COLOR or sb == M3.Special.COLOR or (sa != M3.Special.NONE and sb != M3.Special.NONE):
		steps.append({"type": M3.STEP_SWAP, "a": ia, "b": ib})
		_resolve_combo(board, ia, ib, steps)
	else:
		var groups := M3Matcher.find_groups(board, PackedInt32Array([ia, ib]))
		if groups.is_empty() and not sack_drop:
			board.swap_cells(ia, ib)
			return []
		steps.append({"type": M3.STEP_SWAP, "a": ia, "b": ib})
		if not groups.is_empty():
			_apply_groups(board, groups, steps)
	settle(board, steps)
	return steps


func clear_area(board: M3Board, special: int, cell: Vector2i, steps: Array) -> void:
	if not board.in_bounds(cell):
		return
	var i := board.idx(cell)
	var cells := PackedInt32Array([i])
	if special != M3.Special.NONE:
		cells = area_for(board, special, i)
	_clear(board, cells, &"booster", steps)


func clear_cells(board: M3Board, cells: PackedInt32Array, cause: StringName, steps: Array) -> void:
	_clear(board, cells, cause, steps)


func settle(board: M3Board, steps: Array) -> void:
	for pass_index in M3.MAX_CASCADES:
		_drop_and_refill(board, steps)
		var groups := M3Matcher.find_groups(board)
		if groups.is_empty():
			break
		_apply_groups(board, groups, steps)
	if not board.is_full():
		_drop_and_refill(board, steps)
	if not M3MoveFinder.has_move(board):
		board.shuffle()
		steps.append({"type": M3.STEP_SHUFFLE, "kinds": board.kinds.duplicate(), "specials": board.specials.duplicate()})


func area_for(board: M3Board, special: int, i: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	var p := board.pos(i)
	if special == M3.Special.LINE_H:
		for x in board.width:
			out.append(p.y * board.width + x)
	elif special == M3.Special.LINE_V:
		for y in board.height:
			out.append(y * board.width + p.x)
	elif special == M3.Special.BOMB:
		out = _square(board, p, 1)
	elif special == M3.Special.COLOR:
		var kind := _most_common_kind(board)
		if kind != M3.EMPTY:
			for j in board.cell_count():
				if board.kinds[j] == kind:
					out.append(j)
	elif special == M3.Special.FLYER:
		out.append(i)
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var q: Vector2i = p + d
			if board.in_bounds(q):
				out.append(board.idx(q))
		out.append_array(_pick_targets(board, 1, out))
	return out


func _drop_and_refill(board: M3Board, steps: Array) -> void:
	for pass_index in board.height + 1:
		var moves := board.apply_gravity()
		if not moves.is_empty():
			steps.append({"type": M3.STEP_FALL, "moves": moves})
		var collected := board.collect_sacks()
		var keys := board.collect_keys()
		if collected.is_empty() and keys.is_empty():
			break
		if not collected.is_empty():
			steps.append({"type": M3.STEP_COLLECT, "cells": collected})
		if not keys.is_empty():
			steps.append({"type": M3.STEP_COLLECT, "cells": keys, "key": true})
			_open_cages(board, keys, steps)
	var spawned := board.refill()
	if not spawned.is_empty():
		steps.append({"type": M3.STEP_SPAWN, "cells": spawned})


# Each collected key opens the cage nearest to where it left the board (ties go to the lower index).
func _open_cages(board: M3Board, keys: PackedInt32Array, steps: Array) -> void:
	var cells := PackedInt32Array()
	for key_cell in keys:
		var best := -1
		var best_distance := 1 << 30
		for i in board.cell_count():
			if board.blockers[i] != M3.Block.CAGE:
				continue
			var d := board.pos(i) - board.pos(key_cell)
			var distance := absi(d.x) + absi(d.y)
			if distance < best_distance:
				best_distance = distance
				best = i
		if best < 0:
			break
		board.blockers[best] = M3.Block.NONE
		board.blocker_hp[best] = 0
		cells.append(best)
	if cells.is_empty():
		return
	var blocks := PackedInt32Array()
	blocks.resize(cells.size())
	blocks.fill(M3.Block.CAGE)
	var hp := PackedInt32Array()
	hp.resize(cells.size())
	steps.append({"type": M3.STEP_BLOCKER, "cells": cells, "blocks": blocks, "hp": hp})


func _apply_groups(board: M3Board, groups: Array, steps: Array) -> void:
	var protected := {}
	var start := PackedInt32Array()
	for g in groups:
		if g.special != M3.Special.NONE:
			protected[g.anchor] = true
		start.append_array(g.cells)
	_clear(board, start, &"match", steps, protected)
	for g in groups:
		if g.special == M3.Special.NONE:
			continue
		var kind: int = M3.EMPTY if g.special == M3.Special.COLOR else g.kind
		board.kinds[g.anchor] = kind
		board.specials[g.anchor] = g.special
		steps.append({"type": M3.STEP_SPECIAL, "cells": PackedInt32Array([g.anchor]), "special": g.special, "kind": kind})


func _resolve_combo(board: M3Board, ia: int, ib: int, steps: Array) -> void:
	var sa := board.specials[ia]
	var sb := board.specials[ib]
	var cells := PackedInt32Array([ia, ib])
	var inert := {ia: true, ib: true}
	if sa == M3.Special.COLOR and sb == M3.Special.COLOR:
		for j in board.cell_count():
			cells.append(j)
	elif sa == M3.Special.COLOR or sb == M3.Special.COLOR:
		var color_cell := ia if sa == M3.Special.COLOR else ib
		var other := ib if color_cell == ia else ia
		var other_special := board.specials[other]
		var target_kind := board.kinds[other]
		inert.erase(other)
		if other_special == M3.Special.NONE:
			for j in board.cell_count():
				if board.kinds[j] == target_kind:
					cells.append(j)
		else:
			var converted := PackedInt32Array()
			for j in board.cell_count():
				if j != other and board.kinds[j] == target_kind and board.specials[j] == M3.Special.NONE:
					board.specials[j] = other_special
					converted.append(j)
					cells.append(j)
			if not converted.is_empty():
				steps.append({"type": M3.STEP_SPECIAL, "cells": converted, "special": other_special, "kind": target_kind})
	else:
		var p := board.pos(ib)
		var lines := int(_is_line(sa)) + int(_is_line(sb))
		var bombs := int(sa == M3.Special.BOMB) + int(sb == M3.Special.BOMB)
		var flyers := int(sa == M3.Special.FLYER) + int(sb == M3.Special.FLYER)
		if lines == 2:
			cells.append_array(area_for(board, M3.Special.LINE_H, ib))
			cells.append_array(area_for(board, M3.Special.LINE_V, ib))
		elif lines == 1 and bombs == 1:
			for d in [-1, 0, 1]:
				var row: int = p.y + d
				var col: int = p.x + d
				if row >= 0 and row < board.height:
					for x in board.width:
						cells.append(row * board.width + x)
				if col >= 0 and col < board.width:
					for y in board.height:
						cells.append(y * board.width + col)
		elif bombs == 2:
			cells.append_array(_square(board, p, 2))
		else:
			var carried: int = M3.Special.NONE
			if flyers == 1:
				carried = sa if sa != M3.Special.FLYER else sb
			var targets := _pick_targets(board, 3 if flyers == 2 else 1, PackedInt32Array([ia, ib]))
			for t in targets:
				if carried == M3.Special.NONE:
					cells.append(t)
				else:
					cells.append_array(area_for(board, carried, t))
	_clear(board, cells, &"combo", steps, {}, inert)


# Protected cells are skipped entirely; inert cells are cleared but their special does not fire.
func _clear(board: M3Board, start: PackedInt32Array, cause: StringName, steps: Array, protected: Dictionary = {}, inert: Dictionary = {}) -> void:
	var queue: Array = Array(start)
	queue.reverse()
	var visited := {}
	var cleared := PackedInt32Array()
	var cleared_kinds := PackedInt32Array()
	var hits := {}
	while not queue.is_empty():
		var i: int = queue.pop_back()
		if visited.has(i) or protected.has(i):
			continue
		visited[i] = true
		if not board.is_open(i):
			hits[i] = true
			continue
		if not board.is_occupied(i) or M3.is_item(board.kinds[i]):
			continue
		var special := board.specials[i]
		cleared.append(i)
		cleared_kinds.append(board.kinds[i])
		board.kinds[i] = M3.EMPTY
		board.specials[i] = M3.Special.NONE
		if special != M3.Special.NONE and not inert.has(i):
			var area := area_for(board, special, i)
			for n in range(area.size() - 1, -1, -1):
				queue.append(area[n])
	if not cleared.is_empty():
		steps.append({"type": M3.STEP_CLEAR, "cells": cleared, "kinds": cleared_kinds, "cause": cause})
	_hit_obstacles(board, cleared, hits, steps)


# Every obstacle takes at most one hit per clear: boxes from blasts or neighbouring clears,
# knots and paw prints from their own tile being cleared.
func _hit_obstacles(board: M3Board, cleared: PackedInt32Array, hits: Dictionary, steps: Array) -> void:
	var ground_cells := PackedInt32Array()
	var ground_hp := PackedInt32Array()
	var caught := PackedInt32Array()
	for i in cleared:
		# A mouse on a cleared tile is caught.
		if board.mice[i] > 0:
			board.mice[i] = 0
			caught.append(i)
		var p := board.pos(i)
		for d in NEIGHBOURS:
			var q: Vector2i = p + d
			if board.in_bounds(q) and not board.is_open(board.idx(q)):
				hits[board.idx(q)] = true
		if board.blockers[i] == M3.Block.KNOT:
			hits[i] = true
		if board.ground[i] > 0:
			board.ground[i] -= 1
			ground_cells.append(i)
			ground_hp.append(board.ground[i])
	var block_cells := PackedInt32Array()
	var block_types := PackedInt32Array()
	var block_hp := PackedInt32Array()
	for i: int in hits:
		var block := board.blockers[i]
		if block == M3.Block.NONE or block == M3.Block.HOLE or block == M3.Block.CAGE:
			continue
		board.blocker_hp[i] = maxi(board.blocker_hp[i] - 1, 0)
		if board.blocker_hp[i] == 0:
			board.blockers[i] = M3.Block.NONE
		block_cells.append(i)
		block_types.append(block)
		block_hp.append(board.blocker_hp[i])
	if not block_cells.is_empty():
		steps.append({"type": M3.STEP_BLOCKER, "cells": block_cells, "blocks": block_types, "hp": block_hp})
	if not ground_cells.is_empty():
		steps.append({"type": M3.STEP_GROUND, "cells": ground_cells, "hp": ground_hp})
	if not caught.is_empty():
		steps.append({"type": M3.STEP_CATCH, "cells": caught})


func _is_line(special: int) -> bool:
	return special == M3.Special.LINE_H or special == M3.Special.LINE_V


func _square(board: M3Board, p: Vector2i, radius: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	for y in range(p.y - radius, p.y + radius + 1):
		for x in range(p.x - radius, p.x + radius + 1):
			if x >= 0 and y >= 0 and x < board.width and y < board.height:
				out.append(y * board.width + x)
	return out


func _most_common_kind(board: M3Board) -> int:
	var counts := PackedInt32Array()
	counts.resize(board.kind_count + 1)
	for j in board.cell_count():
		var kind := board.kinds[j]
		if kind > 0 and kind <= board.kind_count:
			counts[kind] += 1
	var best := M3.EMPTY
	for kind in range(1, board.kind_count + 1):
		if counts[kind] > counts[best]:
			best = kind
	return best


func _pick_targets(board: M3Board, count: int, exclude: PackedInt32Array) -> PackedInt32Array:
	var preferred: Array[int] = []
	var others: Array[int] = []
	for j in board.cell_count():
		if exclude.has(j) or M3.is_item(board.kinds[j]):
			continue
		if _is_goal_target(board, j):
			preferred.append(j)
		elif board.is_occupied(j):
			others.append(j)
	var out := PackedInt32Array()
	for n in count:
		var pool := preferred if not preferred.is_empty() else others
		if pool.is_empty():
			break
		var pick := board.spawn_rng.randi_range(0, pool.size() - 1)
		out.append(pool[pick])
		pool.remove_at(pick)
	return out
