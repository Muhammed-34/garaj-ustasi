extends SceneTree

# Usage: godot --headless --path . -s tools/level_bot/run.gd -- --level=res://data/levels/level_001.tres --seeds=500
# Tuning without a level file: -- --moves=15 --goals=1:40,2:40


func _initialize() -> void:
	var level_path := ""
	var seeds := 500
	var moves_override := 0
	var goals_override := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			level_path = arg.trim_prefix("--level=")
		elif arg.begins_with("--seeds="):
			seeds = maxi(arg.trim_prefix("--seeds=").to_int(), 1)
		elif arg.begins_with("--moves="):
			moves_override = arg.trim_prefix("--moves=").to_int()
		elif arg.begins_with("--goals="):
			goals_override = arg.trim_prefix("--goals=")

	var level: M3LevelDef
	if level_path.is_empty():
		level = M3LevelDef.new()
		level.moves = 20
		level.goals[1] = 15
		level.goals[2] = 15
		level_path = "(sample)"
	else:
		level = load(level_path)
	if moves_override > 0:
		level.moves = moves_override
	if not goals_override.is_empty():
		level.goals.clear()
		for pair in goals_override.split(","):
			var parts := pair.split(":")
			level.goals[parts[0].to_int()] = parts[1].to_int()

	var wins := 0
	var goal_left_on_losses := 0
	var started := Time.get_ticks_msec()
	for s in seeds:
		var def: M3LevelDef = level.duplicate()
		def.rng_seed = s + 1
		var session := M3Session.new(def)
		if M3Bot.new(s + 1).play(session):
			wins += 1
		else:
			for kind in session.goals:
				goal_left_on_losses += session.goals[kind]

	var losses := seeds - wins
	print("level=%s moves=%d goals=%s seeds=%d win_rate=%.1f%% avg_goal_left_on_loss=%.1f time=%.1fs" % [
		level_path, level.moves, str(level.goals), seeds, 100.0 * wins / seeds,
		float(goal_left_on_losses) / maxi(losses, 1),
		(Time.get_ticks_msec() - started) / 1000.0,
	])
	quit()
