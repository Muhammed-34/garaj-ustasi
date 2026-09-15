class_name M3Board
extends RefCounted

const MAX_SACKS_ON_BOARD := 2
const SACK_CHANCE := 0.5
const MAX_KEYS_ON_BOARD := 1
const KEY_CHANCE := 0.5

var width: int
var height: int
var kind_count: int
var kinds := PackedInt32Array()
var specials := PackedInt32Array()
var blockers := PackedInt32Array()
var blocker_hp := PackedInt32Array()
var ground := PackedInt32Array()
# 1 where a mouse sits on the cell's tile; mice move between cells, not with the tiles.
var mice := PackedInt32Array()
# Conveyor direction per cell: 1 carries tiles right, -1 left, 0 no belt. Belts never move themselves.
var belts := PackedInt32Array()
var sacks_to_spawn := 0
var keys_to_spawn := 0
# Finished dishes that found no free top tile yet; the next refill drops them in.
var dishes_to_spawn := 0
var spawn_rng := RandomNumberGenerator.new()
var shuffle_rng := RandomNumberGenerator.new()


func _init(w: int = 7, h: int = 7, kinds_n: int = 5, rng_seed: int = 1) -> void:
	width = w
	height = h
	kind_count = kinds_n
	for layer in [kinds, specials, blockers, blocker_hp, ground, mice, belts]:
		layer.resize(w * h)
	spawn_rng.seed = rng_seed
	shuffle_rng.seed = rng_seed * 7919 + 1


# Digits are tile kinds, "." is empty, "S" is a sack and "Y" is a key.
static func from_rows(rows: PackedStringArray, kinds_n: int = 5, rng_seed: int = 1) -> M3Board:
	var board := M3Board.new(rows[0].length(), rows.size(), kinds_n, rng_seed)
	for y in rows.size():
		for x in rows[y].length():
			var ch := rows[y][x]
			var i := y * board.width + x
			if ch == ".":
				board.kinds[i] = M3.EMPTY
			elif ch == "S":
				board.kinds[i] = M3.SACK
			elif ch == "Y":
				board.kinds[i] = M3.KEY
			else:
				board.kinds[i] = ch.to_int()
	return board


# Layout characters: "." plain, "1"/"2" box with that many hits, "C" kitten crate (2 hits),
# "K" yarn knot on the tile, "P" paw print under the tile, "Z" sleeping cat (M3.SLEEPER_HP hits),
# "F" fur pile (1 hit, spreads), "#" hole that shapes the board, "G" cage (opened by a key),
# "M" mouse sitting on the tile, ">" / "<" conveyor belt carrying tiles right / left.
func apply_layout(layout: PackedStringArray) -> void:
	for y in mini(layout.size(), height):
		for x in mini(layout[y].length(), width):
			var i := y * width + x
			var ch := layout[y][x]
			if ch == "1" or ch == "2":
				set_blocker(i, M3.Block.BOX, ch.to_int())
			elif ch == "C":
				set_blocker(i, M3.Block.CRATE, 2)
			elif ch == "Z":
				set_blocker(i, M3.Block.SLEEPER, M3.SLEEPER_HP)
			elif ch == "F":
				set_blocker(i, M3.Block.FUR, 1)
			elif ch == "#":
				set_blocker(i, M3.Block.HOLE, 0)
			elif ch == "G":
				set_blocker(i, M3.Block.CAGE, 1)
			elif ch == "K":
				set_blocker(i, M3.Block.KNOT, 1)
			elif ch == "P":
				ground[i] = 1
			elif ch == "M":
				mice[i] = 1
			elif ch == ">":
				belts[i] = 1
			elif ch == "<":
				belts[i] = -1


func set_blocker(i: int, block: int, hp: int) -> void:
	blockers[i] = block
	blocker_hp[i] = hp
	if not is_open(i):
		kinds[i] = M3.EMPTY
		specials[i] = M3.Special.NONE


func cell_count() -> int:
	return width * height


func idx(p: Vector2i) -> int:
	return p.y * width + p.x


func pos(i: int) -> Vector2i:
	return Vector2i(i % width, floori(i / float(width)))


func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < width and p.y < height


func is_occupied(i: int) -> bool:
	return kinds[i] != M3.EMPTY or specials[i] != M3.Special.NONE


# Open cells can hold a tile; boxes, crates, sleeping cats and fur close their cell.
func is_open(i: int) -> bool:
	return blockers[i] == M3.Block.NONE or blockers[i] == M3.Block.KNOT


func has_belts() -> bool:
	return belts.has(1) or belts.has(-1)


# Turns every belt run one cell in its direction and returns (from, to) pairs of the tiles that moved.
# A run is a stretch of same-direction belt cells in one row; tiles skip obstacles and holes on it,
# and the tile at the far end wraps around to the start of its run.
func convey() -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	for y in height:
		var x := 0
		while x < width:
			var direction := belts[y * width + x]
			if direction == 0:
				x += 1
				continue
			var cells := PackedInt32Array()
			while x < width and belts[y * width + x] == direction:
				var i := y * width + x
				if blockers[i] == M3.Block.NONE:
					cells.append(i)
				x += 1
			if cells.size() < 2:
				continue
			if direction < 0:
				cells.reverse()
			var old_kinds := PackedInt32Array()
			var old_specials := PackedInt32Array()
			for i in cells:
				old_kinds.append(kinds[i])
				old_specials.append(specials[i])
			for k in cells.size():
				var to := cells[(k + 1) % cells.size()]
				kinds[to] = old_kinds[k]
				specials[to] = old_specials[k]
				if old_kinds[k] != M3.EMPTY or old_specials[k] != M3.Special.NONE:
					moves.append(Vector2i(cells[k], to))
	return moves


func is_hole(i: int) -> bool:
	return blockers[i] == M3.Block.HOLE


func has_holes() -> bool:
	return blockers.has(M3.Block.HOLE)


# Fixed cells never move with gravity and split their column.
func is_fixed(i: int) -> bool:
	return blockers[i] != M3.Block.NONE


func is_swappable(i: int) -> bool:
	return is_occupied(i) and blockers[i] == M3.Block.NONE


func is_full() -> bool:
	for i in cell_count():
		if is_open(i) and not is_occupied(i):
			return false
	return true


func count_sacks() -> int:
	return kinds.count(M3.SACK)


func count_keys() -> int:
	return kinds.count(M3.KEY)


func count_dishes() -> int:
	return kinds.count(M3.DISH)


func obstacle_count() -> int:
	var total := 0
	for i in cell_count():
		total += blocker_hp[i] + ground[i] + mice[i]
	return total


func clone() -> M3Board:
	var copy := M3Board.new(width, height, kind_count)
	copy.kinds = kinds.duplicate()
	copy.specials = specials.duplicate()
	copy.blockers = blockers.duplicate()
	copy.blocker_hp = blocker_hp.duplicate()
	copy.ground = ground.duplicate()
	copy.mice = mice.duplicate()
	copy.belts = belts.duplicate()
	copy.sacks_to_spawn = sacks_to_spawn
	copy.keys_to_spawn = keys_to_spawn
	copy.dishes_to_spawn = dishes_to_spawn
	copy.spawn_rng.seed = spawn_rng.seed
	copy.spawn_rng.state = spawn_rng.state
	copy.shuffle_rng.seed = shuffle_rng.seed
	copy.shuffle_rng.state = shuffle_rng.state
	return copy


func swap_cells(a: int, b: int) -> void:
	var k := kinds[a]
	kinds[a] = kinds[b]
	kinds[b] = k
	var s := specials[a]
	specials[a] = specials[b]
	specials[b] = s


func generate() -> void:
	var start_sacks := mini(MAX_SACKS_ON_BOARD, sacks_to_spawn)
	var start_keys := mini(MAX_KEYS_ON_BOARD, keys_to_spawn)
	var start_dishes := dishes_to_spawn
	for attempt in 100:
		_fill_without_matches()
		_place_start_items(start_sacks, M3.SACK)
		_place_start_items(start_keys, M3.KEY)
		_place_start_items(start_dishes, M3.DISH)
		if M3Matcher.find_groups(self).is_empty() and M3MoveFinder.has_move(self):
			break
	sacks_to_spawn -= start_sacks
	keys_to_spawn -= start_keys
	dishes_to_spawn -= start_dishes


# Each returned Vector2i is (from_index, to_index). Fixed cells split a column into separate drops.
func apply_gravity() -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	for x in width:
		var write_y := height - 1
		for y in range(height - 1, -1, -1):
			var i := y * width + x
			if is_fixed(i):
				write_y = y - 1
				continue
			if not is_occupied(i):
				continue
			if y != write_y:
				var j := write_y * width + x
				kinds[j] = kinds[i]
				specials[j] = specials[i]
				kinds[i] = M3.EMPTY
				specials[i] = M3.Special.NONE
				moves.append(Vector2i(i, j))
			write_y -= 1
	return moves


# Removes sacks that reached the bottom row and returns their cells.
func collect_sacks() -> PackedInt32Array:
	var collected := PackedInt32Array()
	for x in width:
		var i := (height - 1) * width + x
		if kinds[i] == M3.SACK:
			kinds[i] = M3.EMPTY
			collected.append(i)
	return collected


# Removes keys that cannot fall any further (bottom row, or resting on an obstacle or hole)
# and returns their cells. Unlike sacks, a key never gets stuck above an obstacle.
func collect_keys() -> PackedInt32Array:
	return collect_landed(M3.KEY)


# Removes items of one kind that cannot fall any further and returns their cells.
func collect_landed(kind: int) -> PackedInt32Array:
	var collected := PackedInt32Array()
	for i in cell_count():
		if kinds[i] != kind:
			continue
		var below := i + width
		if below >= cell_count() or is_fixed(below):
			kinds[i] = M3.EMPTY
			collected.append(i)
	return collected


# Each returned Vector2i is (index, kind).
func refill() -> Array[Vector2i]:
	var spawned: Array[Vector2i] = []
	var sacks := count_sacks()
	var keys := count_keys()
	for i in cell_count():
		if not is_open(i) or is_occupied(i):
			continue
		# Item rolls only happen on item levels so plain levels keep their random sequence.
		if dishes_to_spawn > 0 and i < width:
			kinds[i] = M3.DISH
			dishes_to_spawn -= 1
		elif sacks_to_spawn > 0 and i < width and sacks < MAX_SACKS_ON_BOARD and spawn_rng.randf() < SACK_CHANCE:
			kinds[i] = M3.SACK
			sacks_to_spawn -= 1
			sacks += 1
		elif keys_to_spawn > 0 and i < width and keys < MAX_KEYS_ON_BOARD and spawn_rng.randf() < KEY_CHANCE:
			kinds[i] = M3.KEY
			keys_to_spawn -= 1
			keys += 1
		else:
			kinds[i] = spawn_rng.randi_range(1, kind_count)
		spawned.append(Vector2i(i, kinds[i]))
	return spawned


func shuffle() -> void:
	var cells := PackedInt32Array()
	var pool := PackedInt32Array()
	for i in cell_count():
		if M3.is_matchable(kinds[i]) and specials[i] == M3.Special.NONE and blockers[i] == M3.Block.NONE:
			cells.append(i)
			pool.append(kinds[i])
	for attempt in 100:
		for i in range(pool.size() - 1, 0, -1):
			var j := shuffle_rng.randi_range(0, i)
			var t := pool[i]
			pool[i] = pool[j]
			pool[j] = t
		# Greedy placement avoids ready-made matches; a plain permutation almost never works on dense boards.
		var remaining := Array(pool)
		for c in cells:
			var p := pos(c)
			var pick := 0
			for n in remaining.size():
				if not _would_match(p.x, p.y, remaining[n]):
					pick = n
					break
			kinds[c] = remaining[pick]
			remaining.remove_at(pick)
		if M3Matcher.find_groups(self).is_empty() and M3MoveFinder.has_move(self):
			return
	sacks_to_spawn += count_sacks()
	keys_to_spawn += count_keys()
	dishes_to_spawn += count_dishes()
	generate()


func _fill_without_matches() -> void:
	specials.fill(M3.Special.NONE)
	for y in height:
		for x in width:
			var i := y * width + x
			if not is_open(i):
				kinds[i] = M3.EMPTY
				continue
			var k := spawn_rng.randi_range(1, kind_count)
			for tries in kind_count:
				if not _would_match(x, y, k):
					break
				k = k % kind_count + 1
			kinds[i] = k


# Puts items of one kind on random free cells of the top two rows.
func _place_start_items(count: int, kind: int) -> void:
	if count <= 0:
		return
	var candidates := PackedInt32Array()
	for i in mini(width * 2, cell_count()):
		if is_open(i) and blockers[i] == M3.Block.NONE and not M3.is_item(kinds[i]):
			candidates.append(i)
	for n in mini(count, candidates.size()):
		var pick := spawn_rng.randi_range(0, candidates.size() - 1)
		kinds[candidates[pick]] = kind
		candidates.remove_at(pick)


func _would_match(x: int, y: int, k: int) -> bool:
	var i := y * width + x
	if x >= 2 and kinds[i - 1] == k and kinds[i - 2] == k:
		return true
	if y >= 2 and kinds[i - width] == k and kinds[i - 2 * width] == k:
		return true
	return x >= 1 and y >= 1 and kinds[i - 1] == k and kinds[i - width] == k and kinds[i - width - 1] == k
