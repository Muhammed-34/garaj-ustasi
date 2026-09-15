extends GdUnitTestSuite


func _rig(level: int, cat: String = "tekir", height: float = 240.0) -> CatRig:
	var rig: CatRig = auto_free(CatRig.new())
	add_child(rig)
	rig.setup(cat, height, level)
	return rig


func test_rig_has_tail_body_head_and_a_hidden_blink() -> void:
	var rig := _rig(2)
	assert_int(rig.part_count()).is_equal(4)
	assert_bool(rig.get_part("blink").visible).is_false()
	assert_object(rig.get_part("blink").get_parent()).is_same(rig.get_part("head"))


func test_static_rig_does_not_animate() -> void:
	assert_int(_rig(0).active_animation_count()).is_equal(0)


func test_blink_only_rig_runs_one_animation() -> void:
	assert_int(_rig(1).active_animation_count()).is_equal(1)


func test_full_rig_breathes_wags_and_blinks() -> void:
	assert_int(_rig(2).active_animation_count()).is_equal(3)


func test_rig_matches_requested_height() -> void:
	var body := _rig(0, "tekir", 240.0).get_part("body")
	assert_float(body.texture.get_height() * body.scale.y).is_equal_approx(240.0, 0.5)


func test_rebuilding_does_not_stack_parts_or_animations() -> void:
	var rig := _rig(2)
	rig.setup("gece", 200.0, 2)
	rig.setup("gece", 200.0, 2)
	assert_int(rig.get_child_count()).is_equal(3)
	assert_int(rig.active_animation_count()).is_equal(3)
