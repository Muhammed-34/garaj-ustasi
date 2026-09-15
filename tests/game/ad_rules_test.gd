extends GdUnitTestSuite

const DAY := "2026-09-13"
const NEXT_DAY := "2026-09-14"


func _rules() -> AdRules:
	var rules := AdRules.new()
	rules.first_session = false
	rules.levels_since = 99
	return rules


func _allowed(rules: AdRules, level_id: int = 20, now: float = 10000.0, today: String = DAY) -> bool:
	return rules.can_show_interstitial(AdRules.INTERSTITIAL_CONTEXT, level_id, now, today)


func test_no_interstitials_before_level_twelve() -> void:
	var rules := _rules()
	assert_bool(_allowed(rules, 11)).is_false()
	assert_bool(_allowed(rules, 12)).is_true()


func test_no_interstitials_in_the_first_session() -> void:
	var rules := _rules()
	rules.first_session = true
	assert_bool(_allowed(rules)).is_false()


func test_never_after_a_loss_or_during_tutorial() -> void:
	var rules := _rules()
	for context in [&"loss", &"tutorial", &"rescue"]:
		assert_bool(rules.can_show_interstitial(context, 20, 10000.0, DAY)).is_false()


func test_three_levels_between_interstitials() -> void:
	var rules := _rules()
	rules.record_interstitial(0.0, DAY)
	for n in 2:
		rules.record_level_completed()
	assert_bool(_allowed(rules, 20, 1000.0)).is_false()
	rules.record_level_completed()
	assert_bool(_allowed(rules, 20, 1000.0)).is_true()


func test_at_least_three_minutes_between_ads() -> void:
	var rules := _rules()
	rules.record_interstitial(1000.0, DAY)
	rules.levels_since = 99
	assert_bool(_allowed(rules, 20, 1179.0)).is_false()
	assert_bool(_allowed(rules, 20, 1181.0)).is_true()


func test_session_cap_is_five() -> void:
	var rules := _rules()
	for n in 5:
		rules.record_interstitial(n * 1000.0, DAY)
		rules.levels_since = 99
	assert_bool(_allowed(rules, 20, 100000.0)).is_false()


func test_daily_cap_resets_the_next_day() -> void:
	var rules := _rules()
	for n in 20:
		rules.record_interstitial(n * 1000.0, DAY)
		rules.session_count = 0
		rules.levels_since = 99
	assert_bool(_allowed(rules, 20, 100000.0, DAY)).is_false()
	assert_bool(_allowed(rules, 20, 100000.0, NEXT_DAY)).is_true()


func test_capped_rewarded_placements_stop_for_the_day() -> void:
	var rules := _rules()
	for n in 5:
		assert_bool(rules.can_show_rewarded(&"pre_hard_booster", DAY)).is_true()
		rules.record_rewarded(&"pre_hard_booster", n * 1000.0, DAY)
	assert_bool(rules.can_show_rewarded(&"pre_hard_booster", DAY)).is_false()
	assert_bool(rules.can_show_rewarded(&"pre_hard_booster", NEXT_DAY)).is_true()


func test_uncapped_rewarded_placement_stays_available() -> void:
	var rules := _rules()
	for n in 10:
		rules.record_rewarded(&"continue", n * 1000.0, DAY)
	assert_bool(rules.can_show_rewarded(&"continue", DAY)).is_true()


func test_a_rewarded_ad_delays_the_next_interstitial() -> void:
	var rules := _rules()
	rules.record_rewarded(&"continue", 1000.0, DAY)
	assert_bool(_allowed(rules, 20, 1100.0)).is_false()


func test_daily_counts_survive_save_and_load() -> void:
	var rules := _rules()
	rules.record_interstitial(0.0, DAY)
	rules.record_rewarded(&"feed_cats", 0.0, DAY)
	var restored := AdRules.new()
	restored.load_state(JSON.parse_string(JSON.stringify(rules.save_state())))
	assert_int(restored.day_count).is_equal(1)
	assert_int(int(restored.rewarded_today[&"feed_cats"])).is_equal(1)
