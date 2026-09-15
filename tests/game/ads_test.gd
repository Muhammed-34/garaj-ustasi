extends GdUnitTestSuite

const AdsScript := preload("res://game/autoload/ads.gd")


class FakeProvider extends AdProvider:
	var shown := 0

	func is_rewarded_ready(_placement: StringName) -> bool:
		return true

	func show_rewarded(_placement: StringName) -> bool:
		shown += 1
		return true

	func is_interstitial_ready() -> bool:
		return true

	func show_interstitial() -> bool:
		shown += 1
		return true


func _ads(enabled: bool, provider: AdProvider = null) -> Node:
	var ads: Node = auto_free(AdsScript.new())
	ads.provider = provider
	ads.enabled = enabled
	ads.persist = false
	add_child(ads)
	ads.rules.first_session = false
	ads.rules.levels_since = 99
	return ads


func test_ads_are_switched_off_in_project_settings() -> void:
	assert_bool(ProjectSettings.get_setting("game/ads_enabled", true)).is_false()


func test_default_provider_is_the_null_provider() -> void:
	assert_object(_ads(true).provider).is_instanceof(NullAdProvider)


func test_null_provider_never_offers_a_reward() -> void:
	assert_bool(_ads(true).is_rewarded_available(&"continue")).is_false()


func test_switched_off_ads_never_show_even_with_a_ready_network() -> void:
	var provider := FakeProvider.new()
	var ads := _ads(false, provider)
	assert_bool(ads.is_rewarded_available(&"continue")).is_false()
	assert_bool(await ads.maybe_show_interstitial(&"win_continue", 20)).is_false()
	assert_int(provider.shown).is_equal(0)


func test_switched_on_ads_grant_rewards() -> void:
	var provider := FakeProvider.new()
	var ads := _ads(true, provider)
	assert_bool(await ads.show_rewarded(&"continue")).is_true()
	assert_int(provider.shown).is_equal(1)


func test_interstitials_follow_the_rules() -> void:
	var provider := FakeProvider.new()
	var ads := _ads(true, provider)
	assert_bool(await ads.maybe_show_interstitial(&"win_continue", 5)).is_false()
	assert_bool(await ads.maybe_show_interstitial(&"win_continue", 20)).is_true()
	assert_bool(await ads.maybe_show_interstitial(&"win_continue", 21)).is_false()
	assert_int(provider.shown).is_equal(1)
