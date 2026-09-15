extends SceneTree

# Tunes each level to its target bot win rate and prints table rows ready to paste into level_table.gd.
#   godot --headless --path . -s tools/levels/tune.gd -- --from=1 --to=60 --seeds=40
# Levels with tile goals keep their designed moves; their tile goal counts are scaled instead,
# so every level plays with a familiar number of moves. Levels with only obstacle goals
# (the mechanic intros) get the fewest moves that reach the target, but never below MIN_INTRO_MOVES.
const LevelTable := preload("res://tools/levels/level_table.gd")
const MIN_PERCENT := 20
const MAX_PERCENT := 400
const MIN_MOVES := 8
const MAX_MOVES := 50
const MIN_INTRO_MOVES := 15


func _initialize() -> void:
	var from := 1
	var to: int = LevelTable.TABLE.size()
	var seeds := 40
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--from="):
			from = arg.trim_prefix("--from=").to_int()
		elif arg.begins_with("--to="):
			to = arg.trim_prefix("--to=").to_int()
		elif arg.begins_with("--seeds="):
			seeds = maxi(arg.trim_prefix("--seeds=").to_int(), 1)
	for id in range(from, to + 1):
		var base: M3LevelDef = LevelTable.build(id - 1)
		var target := LevelTable.target_rate(id, base.difficulty)
		if _has_tile_goals(base):
			_tune_goals(id, base, target, seeds)
		else:
			_tune_moves(id, base, target, seeds)
	quit()


func _tune_goals(id: int, base: M3LevelDef, target: float, seeds: int) -> void:
	var rates := {}
	if _rate(_scaled(base, MIN_PERCENT), seeds, rates, MIN_PERCENT) < target:
		print("UNREACHABLE %d moves=%d best=%.2f" % [id, base.moves, rates[MIN_PERCENT]])
		return
	var lo := MIN_PERCENT
	var hi := MAX_PERCENT
	# Largest workload that still reaches the target.
	while lo < hi:
		var mid := (lo + hi + 1) >> 1
		if _rate(_scaled(base, mid), seeds, rates, mid) >= target:
			lo = mid
		else:
			hi = mid - 1
	_report(id, _scaled(base, lo), rates[lo])


func _tune_moves(id: int, base: M3LevelDef, target: float, seeds: int) -> void:
	var rates := {}
	var lo := MIN_MOVES
	var hi := MAX_MOVES
	if _rate(_with_moves(base, hi), seeds, rates, hi) < target:
		print("UNREACHABLE %d best=%.2f" % [id, rates[hi]])
		return
	while lo < hi:
		var mid := (lo + hi) >> 1
		if _rate(_with_moves(base, mid), seeds, rates, mid) >= target:
			hi = mid
		else:
			lo = mid + 1
	var moves := maxi(lo, MIN_INTRO_MOVES)
	_report(id, _with_moves(base, moves), _rate(_with_moves(base, moves), seeds, rates, moves))


func _report(id: int, level: M3LevelDef, rate: float) -> void:
	var row: Array = LevelTable.TABLE[id - 1]
	var orders := PackedStringArray()
	for n in level.orders.size():
		var order: Dictionary = level.orders[n]
		var parts := PackedStringArray()
		for kind in order.goals:
			parts.append("%d: %d" % [kind, order.goals[kind]])
		orders.append("[\"%s\", {%s}, %d]" % [order.dish, ", ".join(parts), row[2][n][2]])
	print("ROW %03d [%d, %d, [%s], {%s}, \"%s\", \"%s\"],  # bot %.2f" % [
		id, level.moves, row[1], ", ".join(orders), _goal_text(row[3], level.goals), row[4], row[5], rate])


# Obstacle goals keep the table's value (usually 0 = all); tile goals show the tuned count.
func _goal_text(row_goals: Dictionary, tuned: Dictionary) -> String:
	var parts := PackedStringArray()
	for key in row_goals:
		var name: String = LevelTable.GOAL_NAMES.get(key, str(key))
		var count: int = row_goals[key] if key > M3.SACK else tuned[key]
		parts.append("%s: %d" % [name, count])
	return ", ".join(parts)


func _has_tile_goals(level: M3LevelDef) -> bool:
	if not level.orders.is_empty():
		return true
	for key in level.goals:
		if key <= level.kind_count:
			return true
	for key in level.goals_2:
		if key <= level.kind_count:
			return true
	return false


func _scaled(base: M3LevelDef, percent: int) -> M3LevelDef:
	var level: M3LevelDef = base.duplicate()
	level.goals = _scaled_goals(base.goals, base.kind_count, percent)
	level.goals_2 = _scaled_goals(base.goals_2, base.kind_count, percent)
	# A fresh array: duplicate() would share the orders with the base level.
	var orders: Array[Dictionary] = []
	for order in base.orders:
		var goals := {}
		for kind in order.goals:
			goals[kind] = maxi(1, roundi(order.goals[kind] * percent / 100.0))
		orders.append({"dish": order.dish, "goals": goals, "patience": order.patience})
	level.orders = orders
	return level


func _scaled_goals(source: Dictionary[int, int], kind_count: int, percent: int) -> Dictionary[int, int]:
	var goals: Dictionary[int, int] = {}
	for key in source:
		goals[key] = maxi(1, roundi(source[key] * percent / 100.0)) if key <= kind_count else source[key]
	return goals


func _with_moves(base: M3LevelDef, moves: int) -> M3LevelDef:
	var level: M3LevelDef = base.duplicate()
	level.moves = moves
	return level


func _rate(template: M3LevelDef, seeds: int, cache: Dictionary, key: int) -> float:
	if cache.has(key):
		return cache[key]
	var wins := 0
	for s in seeds:
		var level: M3LevelDef = template.duplicate()
		level.rng_seed = 5000 + s
		if M3Bot.new(s + 1).play(M3Session.new(level)):
			wins += 1
	cache[key] = float(wins) / seeds
	return cache[key]
