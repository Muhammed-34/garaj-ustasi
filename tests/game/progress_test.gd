extends GdUnitTestSuite

const ProgressScript := preload("res://game/autoload/progress.gd")
const PATH := "user://test_progress.json"


func after_test() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))


func _progress(persist: bool = false) -> Node:
	var progress: Node = auto_free(ProgressScript.new())
	progress.save_path = PATH
	progress.persist = persist
	progress.apply_to_quality = false
	add_child(progress)
	return progress


func test_new_player_starts_at_level_one_with_coins_and_boosters() -> void:
	var progress := _progress()
	assert_bool(progress.is_unlocked(1)).is_true()
	assert_bool(progress.is_unlocked(2)).is_false()
	assert_int(progress.coins()).is_equal(ProgressScript.START_COINS)
	assert_int(progress.booster_stock(M3.BOOSTER_ROW)).is_equal(2)


func test_each_launch_counts_as_a_session() -> void:
	var first := _progress(true)
	assert_int(first.session_number).is_equal(1)
	var second := _progress(true)
	assert_int(second.session_number).is_equal(2)


func test_win_unlocks_next_level_and_pays_coins() -> void:
	var progress := _progress()
	var outcome: Dictionary = progress.record_win(1, 10, 20)
	assert_int(outcome.stars).is_equal(3)
	assert_int(outcome.party_coins).is_equal(MetaRules.PARTY_MAX_MOVES * MetaRules.PARTY_COINS)
	assert_int(outcome.coins).is_equal(80)
	assert_int(progress.coins()).is_equal(280)
	assert_bool(progress.is_unlocked(2)).is_true()


func test_star_thresholds_follow_moves_left() -> void:
	assert_int(ProgressScript.stars_for_result(6, 20)).is_equal(3)
	assert_int(ProgressScript.stars_for_result(3, 20)).is_equal(2)
	assert_int(ProgressScript.stars_for_result(2, 20)).is_equal(1)
	assert_int(ProgressScript.stars_for_result(0, 20)).is_equal(1)


func test_best_stars_are_kept() -> void:
	var progress := _progress()
	progress.record_win(1, 10, 20)
	progress.record_win(1, 0, 20)
	assert_int(progress.stars_for(1)).is_equal(3)


func test_last_level_does_not_unlock_past_the_end() -> void:
	var progress := _progress()
	progress.record_win(Levels.COUNT, 5, 20)
	assert_bool(progress.is_unlocked(Levels.COUNT + 1)).is_false()


func test_boosters_are_used_until_empty() -> void:
	var progress := _progress()
	assert_bool(progress.use_booster(M3.BOOSTER_SHUFFLE)).is_true()
	assert_bool(progress.use_booster(M3.BOOSTER_SHUFFLE)).is_false()
	assert_int(progress.booster_stock(M3.BOOSTER_SHUFFLE)).is_equal(0)


func test_buying_a_booster_spends_coins() -> void:
	var progress := _progress()
	assert_bool(progress.buy_booster(M3.BOOSTER_SINGLE)).is_true()
	assert_int(progress.coins()).is_equal(50)
	assert_int(progress.booster_stock(M3.BOOSTER_SINGLE)).is_equal(4)
	assert_bool(progress.buy_booster(M3.BOOSTER_ROW)).is_false()
	assert_int(progress.coins()).is_equal(50)


func test_continue_needs_enough_coins() -> void:
	var progress := _progress()
	assert_bool(progress.spend_coins(ProgressScript.CONTINUE_COST)).is_false()
	assert_int(progress.coins()).is_equal(ProgressScript.START_COINS)


func test_progress_survives_a_restart() -> void:
	var first := _progress(true)
	first.record_win(1, 10, 20)
	var second := _progress(true)
	assert_int(second.coins()).is_equal(280)
	assert_int(second.stars_for(1)).is_equal(3)


func test_damaged_values_fall_back_to_defaults() -> void:
	SaveFile.write(PATH, {"coins": "çok", "unlocked": 3})
	var progress := _progress()
	assert_int(progress.coins()).is_equal(ProgressScript.START_COINS)
	assert_bool(progress.is_unlocked(3)).is_true()


func test_missing_sections_are_filled_in() -> void:
	SaveFile.write(PATH, {"version": 1, "coins": 90})
	var progress := _progress()
	assert_bool(progress.setting("vibration")).is_true()
	assert_int(progress.booster_stock(M3.BOOSTER_ROW)).is_equal(2)
	assert_int(progress.coins()).is_equal(90)


func test_version_1_save_moves_to_version_2_with_earned_cats() -> void:
	SaveFile.write(PATH, {"version": 1, "coins": 90, "unlocked": 6, "stars": {"1": 3, "2": 2, "3": 1, "4": 2, "5": 3}})
	var progress := _progress()
	assert_int(int(progress.data.version)).is_equal(2)
	assert_int(progress.coins()).is_equal(90)
	assert_int(progress.cats().size()).is_equal(1)
	assert_int(int(progress.cats()[0].level)).is_equal(5)
	assert_int(int(progress.data.next_cat_id)).is_equal(2)
	assert_int(progress.next_pending_rescue_level()).is_equal(-1)
	assert_int(progress.calendar_index()).is_equal(0)


func test_version_1_save_without_rescue_levels_has_no_cats() -> void:
	SaveFile.write(PATH, {"version": 1, "unlocked": 3, "stars": {"1": 3, "2": 1}})
	var progress := _progress()
	assert_int(progress.cats().size()).is_equal(0)
	assert_int(progress.levels_until_next_rescue()).is_equal(3)


func test_cat_is_rescued_once_after_its_level() -> void:
	var progress := _progress()
	assert_bool(progress.rescue_cat(5,"Zeytin").is_empty()).is_true()
	progress.record_win(5, 5, 20)
	assert_int(progress.next_pending_rescue_level()).is_equal(5)
	var cat: Dictionary = progress.rescue_cat(5,"  Zey<tin>! ")
	assert_str(str(cat.name)).is_equal("Zeytin")
	assert_str(str(cat.breed)).is_equal(MetaRules.BREEDS[0])
	assert_bool(progress.rescue_cat(5,"Paşa").is_empty()).is_true()
	assert_int(progress.cats().size()).is_equal(1)


func test_empty_name_gets_a_suggestion() -> void:
	var progress := _progress()
	progress.record_win(5, 5, 20)
	var cat: Dictionary = progress.rescue_cat(5,"   ")
	assert_bool(MetaRules.NAME_POOL.has(cat.name)).is_true()


func test_adoption_waits_for_level_60_and_skips_favorites() -> void:
	var progress := _progress()
	progress.record_win(5, 5, 20)
	var cat: Dictionary = progress.rescue_cat(5,"Bulut")
	assert_str(progress.adopt_cat(cat.id, "2026-09-13")).contains("60")
	progress.data.stars["60"] = 1
	progress.set_favorite(cat.id, true)
	assert_str(progress.adopt_cat(cat.id, "2026-09-13")).contains("Favori")
	progress.set_favorite(cat.id, false)
	assert_str(progress.adopt_cat(cat.id, "2026-09-13")).is_empty()
	assert_int(progress.shelter_cats().size()).is_equal(0)


func test_adopted_cat_writes_a_letter_the_next_day() -> void:
	var progress := _progress()
	progress.record_win(5, 5, 20)
	var cat: Dictionary = progress.rescue_cat(5,"Lokum")
	progress.data.stars["60"] = 1
	progress.adopt_cat(cat.id, "2026-12-31")
	assert_int(progress.mailbox("2026-12-31").size()).is_equal(0)
	assert_int(progress.unread_mail_count("2027-01-01")).is_equal(1)
	assert_str(str(progress.mailbox("2027-01-01")[0].text)).contains("Lokum")
	progress.mark_mail_read("2027-01-01")
	assert_int(progress.unread_mail_count("2027-01-01")).is_equal(0)


func test_calendar_pays_once_a_day_and_cycles() -> void:
	var progress := _progress()
	assert_int(int(progress.claim_calendar("2026-09-13").coins)).is_equal(50)
	assert_bool(progress.claim_calendar("2026-09-13").is_empty()).is_true()
	assert_int(int(progress.claim_calendar("2026-09-20").coins)).is_equal(75)
	progress.claim_calendar("2026-09-21")
	var stock: int = progress.booster_stock(M3.BOOSTER_SINGLE)
	assert_str(str(progress.claim_calendar("2026-09-22").booster)).is_equal("single")
	assert_int(progress.booster_stock(M3.BOOSTER_SINGLE)).is_equal(stock + 1)
	for day in ["23", "24", "25"]:
		progress.claim_calendar("2026-09-" + day)
	assert_int(progress.calendar_index()).is_equal(0)


func test_cats_survive_a_restart() -> void:
	var first := _progress(true)
	first.record_win(5, 5, 20)
	first.rescue_cat(5,"Maviş")
	var second := _progress(true)
	assert_str(str(second.cats()[0].name)).is_equal("Maviş")


func test_bowls_start_full_and_a_failure_empties_one() -> void:
	var progress := _progress()
	assert_int(progress.bowls(1000)).is_equal(MetaRules.MAX_BOWLS)
	assert_int(progress.seconds_to_next_bowl(1000)).is_equal(0)
	progress.spend_bowl(1000)
	assert_int(progress.bowls(1000)).is_equal(MetaRules.MAX_BOWLS - 1)
	assert_int(progress.seconds_to_next_bowl(1000)).is_equal(MetaRules.BOWL_REFILL_SECONDS)


func test_bowls_refill_one_at_a_time_up_to_the_maximum() -> void:
	var progress := _progress()
	var refill := MetaRules.BOWL_REFILL_SECONDS
	for n in MetaRules.MAX_BOWLS:
		progress.spend_bowl(1000)
	assert_bool(progress.can_start_level(1000)).is_false()
	assert_int(progress.bowls(1000 + refill - 1)).is_equal(0)
	assert_int(progress.bowls(1000 + refill)).is_equal(1)
	assert_int(progress.seconds_to_next_bowl(1000 + refill)).is_equal(refill)
	assert_int(progress.bowls(1000 + refill * 10)).is_equal(MetaRules.MAX_BOWLS)
	assert_int(progress.seconds_to_next_bowl(1000 + refill * 10)).is_equal(0)


func test_turning_the_clock_back_never_lengthens_the_wait() -> void:
	var progress := _progress()
	progress.spend_bowl(100000)
	assert_int(progress.seconds_to_next_bowl(50000)).is_equal(MetaRules.BOWL_REFILL_SECONDS)


func test_closing_the_app_mid_level_costs_a_bowl() -> void:
	var first := _progress(true)
	first.begin_attempt(4)
	var second := _progress(true)
	assert_int(second.bowls()).is_equal(MetaRules.MAX_BOWLS - 1)
	assert_int(int(second.data.bowls.open_level)).is_equal(0)
	assert_bool(second.take_bowl_lost_note()).is_true()
	assert_bool(second.take_bowl_lost_note()).is_false()


func test_finished_attempt_costs_nothing() -> void:
	var first := _progress(true)
	first.begin_attempt(4)
	first.end_attempt()
	var second := _progress(true)
	assert_int(second.bowls()).is_equal(MetaRules.MAX_BOWLS)
	assert_bool(second.take_bowl_lost_note()).is_false()


func test_bowls_can_be_refilled_with_coins() -> void:
	var progress := _progress()
	progress.data.coins = 400
	assert_bool(progress.refill_bowls_with_coins()).is_false()
	progress.spend_bowl(1000)
	progress.spend_bowl(1000)
	assert_bool(progress.refill_bowls_with_coins()).is_true()
	assert_int(progress.bowls(1000)).is_equal(MetaRules.MAX_BOWLS)
	assert_int(progress.coins()).is_equal(400 - MetaRules.BOWL_REFILL_ALL_COST)


func test_settings_round_trip() -> void:
	var progress := _progress()
	progress.set_setting("vibration", false)
	assert_bool(progress.setting("vibration")).is_false()
