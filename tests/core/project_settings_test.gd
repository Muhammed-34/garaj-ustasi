extends GdUnitTestSuite


func test_ads_are_disabled_until_release() -> void:
	assert_bool(ProjectSettings.get_setting("game/ads_enabled", true)).is_false()


func test_mobile_uses_compatibility_renderer() -> void:
	assert_str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile")).is_equal("gl_compatibility")
