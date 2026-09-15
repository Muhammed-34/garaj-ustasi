extends GdUnitTestSuite

# Bot win rates on the first 20 of the seeds tools/levels/tune.gd uses. Bands are loose
# because 20 games is a noisy sample; the tuner aims well inside them.
const SEEDS := 20
const BANDS := {0: [0.7, 1.0], 1: [0.25, 0.9], 2: [0.15, 0.8]}


func _win_rate(level_base: M3LevelDef) -> float:
	var wins := 0
	for s in SEEDS:
		var level: M3LevelDef = level_base.duplicate()
		level.rng_seed = 5000 + s
		if M3Bot.new(s + 1).play(M3Session.new(level)):
			wins += 1
	return float(wins) / SEEDS


func test_levels_stay_in_their_difficulty_band() -> void:
	for id in range(1, Levels.COUNT + 1):
		var level := Levels.load_level(id)
		var band: Array = BANDS[level.difficulty]
		var rate := _win_rate(level)
		assert_float(rate).override_failure_message("level %d is too hard (%.2f)" % [id, rate]).is_greater_equal(band[0])
		assert_float(rate).override_failure_message("level %d is too easy (%.2f)" % [id, rate]).is_less_equal(band[1])
