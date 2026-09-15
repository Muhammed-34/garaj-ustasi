extends GdUnitTestSuite


func test_defaults_match_the_design() -> void:
	var level := M3LevelDef.new()
	assert_int(level.width).is_equal(7)
	assert_int(level.height).is_equal(7)
	assert_int(level.kind_count).is_equal(5)
	assert_int(level.moves).is_equal(20)


func test_level_survives_save_and_load() -> void:
	var level := M3LevelDef.new()
	level.id = 12
	level.moves = 18
	level.goals[1] = 15
	level.goals[3] = 10
	var path := "user://level_roundtrip_test.tres"
	assert_int(ResourceSaver.save(level, path)).is_equal(OK)
	var loaded: M3LevelDef = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_int(loaded.id).is_equal(12)
	assert_int(loaded.moves).is_equal(18)
	assert_int(loaded.goals[3]).is_equal(10)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_session_uses_level_size_and_kinds() -> void:
	var level := M3LevelDef.new()
	level.width = 6
	level.height = 8
	level.kind_count = 4
	level.goals[1] = 5
	var session := M3Session.new(level)
	assert_int(session.board.width).is_equal(6)
	assert_int(session.board.height).is_equal(8)
	for kind in session.board.kinds:
		assert_int(kind).is_between(1, 4)


func test_session_copies_goals_instead_of_sharing_them() -> void:
	var level := M3LevelDef.new()
	level.goals[1] = 5
	var session := M3Session.new(level)
	session.goals[1] = 0
	assert_int(level.goals[1]).is_equal(5)


func test_session_starts_unfinished_with_level_moves() -> void:
	var level := M3LevelDef.new()
	level.moves = 17
	level.goals[2] = 3
	var session := M3Session.new(level)
	assert_int(session.moves_left).is_equal(17)
	assert_bool(session.is_finished()).is_false()


func test_extra_moves_add_up_during_play() -> void:
	var level := M3LevelDef.new()
	level.goals[2] = 3
	var session := M3Session.new(level)
	session.add_moves(3)
	assert_int(session.moves_left).is_equal(23)
