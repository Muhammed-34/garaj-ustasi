class_name M3Bot
extends RefCounted

const MAX_TURNS := 200
const NO_MOVE := Vector2i(-1, -1)

var rng := RandomNumberGenerator.new()


func _init(rng_seed: int = 1) -> void:
	rng.seed = rng_seed


func play(session: M3Session) -> bool:
	for turn in MAX_TURNS:
		if session.is_finished():
			break
		var move := choose_move(session)
		if move == NO_MOVE:
			break
		session.swap(session.board.pos(move.x), session.board.pos(move.y))
	return session.is_won()


func choose_move(session: M3Session) -> Vector2i:
	var best := NO_MOVE
	var best_score := -INF
	for move in M3MoveFinder.find_moves(session.board):
		var trial := session.clone()
		# Reseeding hides future refills; a bot that sees them overstates what a player can win.
		trial.board.spawn_rng.seed = rng.randi()
		trial.swap(trial.board.pos(move.x), trial.board.pos(move.y))
		var score := _score(session, trial) + rng.randf()
		if score > best_score:
			best_score = score
			best = move
	return best


func _score(before: M3Session, after: M3Session) -> float:
	var progress := 0
	for kind in before.goals:
		# A finished first stage swaps the goal keys, so missing keys count as done.
		progress += before.goals[kind] - int(after.goals.get(kind, 0))
	if after.stage > before.stage:
		progress += 10
	progress += _order_progress(before, after)
	var specials := 0
	for special in after.board.specials:
		if special != M3.Special.NONE:
			specials += 1
	var obstacle_hits := before.board.obstacle_count() - after.board.obstacle_count()
	return progress * 10.0 + specials * 4.0 + obstacle_hits * 3.0 + _sack_depth(after) - _sack_depth(before)


# Ingredient steps count like goals; finishing an order and serving its dish are each worth ten.
func _order_progress(before: M3Session, after: M3Session) -> int:
	var total := 0
	for n in before.orders.size():
		var old: Dictionary = before.orders[n]
		var now: Dictionary = after.orders[n]
		for kind in old.need:
			total += int(old.need[kind]) - int(now.need.get(kind, 0))
		total += (int(now.state) - int(old.state)) * 10
	return total


# Rows travelled by all items; a collected sack or key and a served dish count as having travelled the
# whole board, so removing them at the bottom never looks like lost progress.
func _sack_depth(session: M3Session) -> float:
	var board := session.board
	var total := session.level.sacks + session.level.keys
	if total == 0 and session.orders.is_empty():
		return 0.0
	var collected := total - board.count_sacks() - board.count_keys() - board.sacks_to_spawn - board.keys_to_spawn
	var depth := float((collected + session.served_count()) * board.height)
	for i in board.cell_count():
		if M3.is_item(board.kinds[i]):
			depth += board.pos(i).y
	return depth * 6.0
