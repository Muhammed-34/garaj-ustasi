extends SceneTree

# Plays every level to the end with the bot and a BoardView, looking for anything that would stop a player:
# invalid bot moves, a board with no move left, holes that never refill, unresolved matches, the view
# drifting from the board, and levels the bot never wins.
#   godot --headless --path . -s tools/level_bot/smoke.gd -- --seeds=3 [--from=1 --to=140]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var from := 1
	var to := Levels.COUNT
	var seeds := 3
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--from="):
			from = arg.trim_prefix("--from=").to_int()
		elif arg.begins_with("--to="):
			to = arg.trim_prefix("--to=").to_int()
		elif arg.begins_with("--seeds="):
			seeds = maxi(arg.trim_prefix("--seeds=").to_int(), 1)
	var problems := 0
	var never_won := PackedInt32Array()
	var view := BoardView.new()
	view.animate = false
	root.add_child(view)
	view.size = Vector2(700, 700)
	for id in range(from, to + 1):
		var wins := 0
		for s in seeds:
			var level: M3LevelDef = Levels.load_level(id).duplicate()
			level.rng_seed = 9000 + id * 7 + s
			var session := M3Session.new(level)
			view.setup(session.board)
			var issue := _check_board(session.board)
			if issue != "":
				print("PROBLEM level %d seed %d start: %s" % [id, s, issue])
				problems += 1
				continue
			var bot := M3Bot.new(s + 1)
			var turns := 0
			while not session.is_finished() and turns < M3Bot.MAX_TURNS:
				turns += 1
				var move := bot.choose_move(session)
				if move == M3Bot.NO_MOVE:
					print("PROBLEM level %d seed %d turn %d: no move found" % [id, s, turns])
					problems += 1
					break
				var steps := session.swap(session.board.pos(move.x), session.board.pos(move.y))
				if steps.is_empty():
					print("PROBLEM level %d seed %d turn %d: move rejected" % [id, s, turns])
					problems += 1
					break
				await view.play(steps)
				issue = _check_board(session.board)
				if issue == "" and (view.resyncs > 0 or not view.tiles_match_board()):
					issue = "view out of sync"
				if issue != "":
					print("PROBLEM level %d seed %d turn %d: %s" % [id, s, turns, issue])
					problems += 1
					view.resyncs = 0
					break
			if session.is_won():
				wins += 1
		if wins == 0:
			never_won.append(id)
		print("level %d wins %d/%d" % [id, wins, seeds])
	print("SMOKE levels %d-%d seeds %d problems %d never_won %s" % [from, to, seeds, problems, str(Array(never_won))])
	quit(1 if problems > 0 else 0)


func _check_board(board: M3Board) -> String:
	if not board.is_full():
		return "board has empty open cells"
	if not M3Matcher.find_groups(board).is_empty():
		return "unresolved match on the board"
	if not M3MoveFinder.has_move(board):
		return "no move left"
	return ""
