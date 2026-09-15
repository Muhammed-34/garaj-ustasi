class_name M3MoveFinder
extends RefCounted


# Each returned Vector2i is a pair of cell indices (a, b).
static func find_moves(board: M3Board, limit: int = 0) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var w := board.width
	var n := board.cell_count()
	for i in n:
		var neighbors: Array[int] = []
		if i % w < w - 1:
			neighbors.append(i + 1)
		if i + w < n:
			neighbors.append(i + w)
		for j in neighbors:
			if _is_valid_swap(board, i, j):
				moves.append(Vector2i(i, j))
				if limit > 0 and moves.size() >= limit:
					return moves
	return moves


# An item (sack or key) may always trade places with the tile right below it, so it can never get stuck.
static func is_sack_drop(board: M3Board, a: int, b: int) -> bool:
	var upper := mini(a, b)
	var lower := maxi(a, b)
	return lower - upper == board.width and M3.is_item(board.kinds[upper]) and not M3.is_item(board.kinds[lower])


static func has_move(board: M3Board) -> bool:
	return not find_moves(board, 1).is_empty()


static func _is_valid_swap(board: M3Board, a: int, b: int) -> bool:
	if not board.is_swappable(a) or not board.is_swappable(b):
		return false
	if is_sack_drop(board, a, b):
		return true
	var sa := board.specials[a]
	var sb := board.specials[b]
	if sa == M3.Special.COLOR or sb == M3.Special.COLOR:
		return true
	if sa != M3.Special.NONE and sb != M3.Special.NONE:
		return true
	board.swap_cells(a, b)
	var valid := M3Matcher.has_match_at(board, a) or M3Matcher.has_match_at(board, b)
	board.swap_cells(a, b)
	return valid
