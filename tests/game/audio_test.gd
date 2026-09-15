extends GdUnitTestSuite

var _audio: Node


func before_test() -> void:
	_audio = get_tree().root.get_node("Audio")
	_audio.enabled = true
	_audio.history.clear()


func after_test() -> void:
	_audio.enabled = true
	_audio.history.clear()


func test_every_sound_is_generated() -> void:
	for sound in _audio.SOUNDS:
		assert_bool(ResourceLoader.exists(_audio.SOUND_PATH % sound)).override_failure_message("missing %s" % sound).is_true()


func test_muted_audio_plays_nothing() -> void:
	_audio.play(&"pop")
	_audio.enabled = false
	_audio.play(&"coin")
	assert_array(_audio.history).is_equal([&"pop"])


func test_cascades_rise_a_semitone_per_step() -> void:
	assert_float(_audio.chain_pitch(1)).is_equal(1.0)
	assert_float(_audio.chain_pitch(13)).is_equal_approx(2.0, 0.001)
	assert_float(_audio.chain_pitch(40)).is_equal_approx(2.0, 0.001)


func test_buttons_click() -> void:
	var button: Button = auto_free(UiKit.button("Tamam", 20, Vector2.ZERO))
	button.pressed.emit()
	assert_array(_audio.history).contains([&"click"])


func test_board_moves_make_sounds() -> void:
	var level := M3LevelDef.new()
	level.goals[1] = 999
	level.moves = 20
	var session := M3Session.new(level)
	var view: BoardView = auto_free(BoardView.new())
	view.animate = false
	view.size = Vector2(700, 700)
	add_child(view)
	view.setup(session.board)
	var move: Vector2i = M3MoveFinder.find_moves(session.board)[0]
	await view.play(session.swap(session.board.pos(move.x), session.board.pos(move.y)))
	assert_array(_audio.history).contains([&"swap", &"pop"])
