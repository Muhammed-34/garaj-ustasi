class_name M3Matcher
extends RefCounted


# Returns groups as {cells: PackedInt32Array, kind: int, special: M3.Special, anchor: int}.
static func find_groups(board: M3Board, swapped := PackedInt32Array()) -> Array:
	var w := board.width
	var h := board.height
	var n := w * h
	var runs: Array = []
	for y in h:
		var x := 0
		while x < w:
			var kind := board.kinds[y * w + x]
			var end := x + 1
			while end < w and board.kinds[y * w + end] == kind:
				end += 1
			if M3.is_matchable(kind) and end - x >= 3:
				var cells := PackedInt32Array()
				for cx in range(x, end):
					cells.append(y * w + cx)
				runs.append({"cells": cells, "horizontal": true})
			x = end
	for x in w:
		var y := 0
		while y < h:
			var kind := board.kinds[y * w + x]
			var end := y + 1
			while end < h and board.kinds[end * w + x] == kind:
				end += 1
			if M3.is_matchable(kind) and end - y >= 3:
				var cells := PackedInt32Array()
				for cy in range(y, end):
					cells.append(cy * w + x)
				runs.append({"cells": cells, "horizontal": false})
			y = end
	var squares: Array = []
	for y in h - 1:
		for x in w - 1:
			var i := y * w + x
			var kind := board.kinds[i]
			if M3.is_matchable(kind) and board.kinds[i + 1] == kind and board.kinds[i + w] == kind and board.kinds[i + w + 1] == kind:
				squares.append(PackedInt32Array([i, i + 1, i + w, i + w + 1]))
	if runs.is_empty() and squares.is_empty():
		return []

	var parent: Array = range(n)
	var marked := PackedByteArray()
	marked.resize(n)
	for run in runs:
		var cells: PackedInt32Array = run.cells
		for c in cells:
			marked[c] = 1
			_union(parent, cells[0], c)
	for square in squares:
		for c in square:
			marked[c] = 1
			_union(parent, square[0], c)

	var groups := {}
	var order: Array[int] = []
	for i in n:
		if marked[i] == 0:
			continue
		var root := _root(parent, i)
		if not groups.has(root):
			groups[root] = {
				"cells": [], "kind": board.kinds[i], "has_h": false, "has_v": false,
				"h_cells": {}, "v_cells": {}, "best_len": 0, "best_run": PackedInt32Array(),
				"best_horizontal": true, "square_cell": -1,
			}
			order.append(root)
		groups[root].cells.append(i)
	for run in runs:
		var cells: PackedInt32Array = run.cells
		var g: Dictionary = groups[_root(parent, cells[0])]
		if run.horizontal:
			g.has_h = true
			for c in cells:
				g.h_cells[c] = true
		else:
			g.has_v = true
			for c in cells:
				g.v_cells[c] = true
		if cells.size() > g.best_len:
			g.best_len = cells.size()
			g.best_run = cells
			g.best_horizontal = run.horizontal
	for square in squares:
		var g: Dictionary = groups[_root(parent, square[0])]
		if g.square_cell < 0:
			g.square_cell = square[0]

	var result: Array = []
	for root in order:
		var g: Dictionary = groups[root]
		var special: int = M3.Special.NONE
		var preferred := -1
		if g.best_len >= 5:
			special = M3.Special.COLOR
			preferred = g.best_run[g.best_len >> 1]
		elif g.has_h and g.has_v:
			special = M3.Special.BOMB
			for c in g.h_cells:
				if g.v_cells.has(c):
					preferred = c
					break
		elif g.best_len == 4:
			special = M3.Special.LINE_H if g.best_horizontal else M3.Special.LINE_V
			preferred = g.best_run[1]
		elif g.square_cell >= 0:
			special = M3.Special.FLYER
			preferred = g.square_cell
		var anchor := -1
		if special != M3.Special.NONE:
			anchor = _pick_anchor(board, g.cells, swapped, preferred)
			if anchor < 0:
				special = M3.Special.NONE
		result.append({"cells": PackedInt32Array(g.cells), "kind": g.kind, "special": special, "anchor": anchor})
	return result


static func has_match_at(board: M3Board, i: int) -> bool:
	var kind := board.kinds[i]
	if not M3.is_matchable(kind):
		return false
	var w := board.width
	var h := board.height
	var x := i % w
	var y := floori(i / float(w))
	var count := 1
	var cx := x - 1
	while cx >= 0 and board.kinds[y * w + cx] == kind:
		count += 1
		cx -= 1
	cx = x + 1
	while cx < w and board.kinds[y * w + cx] == kind:
		count += 1
		cx += 1
	if count >= 3:
		return true
	count = 1
	var cy := y - 1
	while cy >= 0 and board.kinds[cy * w + x] == kind:
		count += 1
		cy -= 1
	cy = y + 1
	while cy < h and board.kinds[cy * w + x] == kind:
		count += 1
		cy += 1
	if count >= 3:
		return true
	for oy in [-1, 0]:
		for ox in [-1, 0]:
			var tx: int = x + ox
			var ty: int = y + oy
			if tx < 0 or ty < 0 or tx + 1 >= w or ty + 1 >= h:
				continue
			var t := ty * w + tx
			if board.kinds[t] == kind and board.kinds[t + 1] == kind and board.kinds[t + w] == kind and board.kinds[t + w + 1] == kind:
				return true
	return false


static func _pick_anchor(board: M3Board, cells: Array, swapped: PackedInt32Array, preferred: int) -> int:
	for s in swapped:
		if cells.has(s) and _can_anchor(board, s):
			return s
	if preferred >= 0 and _can_anchor(board, preferred):
		return preferred
	for c in cells:
		if _can_anchor(board, c):
			return c
	return -1


static func _can_anchor(board: M3Board, i: int) -> bool:
	return board.specials[i] == M3.Special.NONE and board.blockers[i] == M3.Block.NONE


static func _root(parent: Array, i: int) -> int:
	var r := i
	while parent[r] != r:
		r = parent[r]
	while parent[i] != r:
		var next: int = parent[i]
		parent[i] = r
		i = next
	return r


static func _union(parent: Array, a: int, b: int) -> void:
	parent[_root(parent, a)] = _root(parent, b)
