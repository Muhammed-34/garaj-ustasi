extends GdUnitTestSuite

const QualityScript := preload("res://game/autoload/quality.gd")
const GIB := 1024 * 1024 * 1024


func after_test() -> void:
	Engine.max_fps = 0


func _quality(mode: StringName = &"high") -> Node:
	var quality: Node = auto_free(QualityScript.new())
	add_child(quality)
	quality.set_mode(mode)
	return quality


func test_quality_is_registered_as_autoload() -> void:
	assert_bool(ProjectSettings.has_setting("autoload/Quality")).is_true()


func test_memory_picks_the_profile() -> void:
	assert_str(str(QualityScript.profile_id_for_memory(2 * GIB))).is_equal("low")
	assert_str(str(QualityScript.profile_id_for_memory(3 * GIB))).is_equal("low")
	assert_str(str(QualityScript.profile_id_for_memory(4 * GIB))).is_equal("mid")
	assert_str(str(QualityScript.profile_id_for_memory(6 * GIB))).is_equal("high")
	assert_str(str(QualityScript.profile_id_for_memory(0))).is_equal("mid")


func test_low_profile_has_no_particles_and_caps_fps() -> void:
	var quality := _quality(&"low")
	assert_int(quality.particles_per_burst()).is_equal(0)
	assert_bool(quality.shake_enabled()).is_false()
	assert_bool(quality.hit_stop_enabled()).is_false()
	assert_int(Engine.max_fps).is_equal(30)
	assert_float(quality.duration(1.0)).is_less(1.0)


func test_mid_profile_keeps_pause_but_drops_shake() -> void:
	var quality := _quality(&"mid")
	assert_int(quality.particles_per_burst()).is_equal(6)
	assert_bool(quality.shake_enabled()).is_false()
	assert_bool(quality.hit_stop_enabled()).is_true()


func test_high_profile_has_every_effect() -> void:
	var quality := _quality(&"high")
	assert_int(quality.particles_per_burst()).is_equal(12)
	assert_bool(quality.shake_enabled()).is_true()
	assert_bool(quality.trails_enabled()).is_true()
	assert_int(Engine.max_fps).is_equal(60)
	assert_float(quality.duration(1.0)).is_equal(1.0)


func test_reduce_motion_turns_off_movement_effects_only() -> void:
	var quality := _quality(&"high")
	quality.reduce_motion = true
	assert_bool(quality.shake_enabled()).is_false()
	assert_bool(quality.hit_stop_enabled()).is_false()
	assert_bool(quality.parallax_enabled()).is_false()
	assert_bool(quality.trails_enabled()).is_false()
	assert_int(quality.particles_per_burst()).is_equal(12)


func test_battery_saver_caps_fps_and_can_be_undone() -> void:
	var quality := _quality(&"high")
	quality.battery_saver = true
	assert_int(Engine.max_fps).is_equal(30)
	quality.battery_saver = false
	assert_int(Engine.max_fps).is_equal(60)


func test_slow_frames_are_reported_once_in_auto_mode() -> void:
	var quality := _quality(&"high")
	quality.mode = QualityScript.AUTO
	var reports := [0]
	quality.slow_device_detected.connect(func() -> void: reports[0] += 1)
	for n in 400:
		quality.record_frame(0.03)
	assert_int(reports[0]).is_equal(1)


func test_smooth_frames_are_not_reported() -> void:
	var quality := _quality(&"high")
	quality.mode = QualityScript.AUTO
	var reports := [0]
	quality.slow_device_detected.connect(func() -> void: reports[0] += 1)
	for n in 400:
		quality.record_frame(0.016)
	assert_int(reports[0]).is_equal(0)


func test_manual_choice_is_never_second_guessed() -> void:
	var quality := _quality(&"high")
	var reports := [0]
	quality.slow_device_detected.connect(func() -> void: reports[0] += 1)
	for n in 400:
		quality.record_frame(0.05)
	assert_int(reports[0]).is_equal(0)
