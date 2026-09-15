extends GdUnitTestSuite


func test_names_keep_only_letters_digits_and_single_spaces() -> void:
	assert_str(MetaRules.sanitize_name("  Mır<>mır!  ")).is_equal("Mırmır")
	assert_str(MetaRules.sanitize_name("Paşa   2")).is_equal("Paşa 2")
	assert_int(MetaRules.sanitize_name("Çokçokçokuzunbirisim").length()).is_equal(MetaRules.MAX_NAME_LENGTH)


func test_suggestions_are_unique_and_skip_taken_names() -> void:
	var names := MetaRules.suggest_names(["Zeytin", "Paşa"], 3, 7)
	assert_int(names.size()).is_equal(3)
	assert_bool(names.has("Zeytin") or names.has("Paşa")).is_false()
	assert_bool(names[0] != names[1] and names[1] != names[2] and names[0] != names[2]).is_true()


func test_rooms_open_every_four_cats() -> void:
	assert_int(MetaRules.rooms_unlocked(0)).is_equal(1)
	assert_int(MetaRules.rooms_unlocked(3)).is_equal(1)
	assert_int(MetaRules.rooms_unlocked(4)).is_equal(2)
	assert_int(MetaRules.rooms_unlocked(16)).is_equal(5)
	assert_int(MetaRules.rooms_unlocked(99)).is_equal(MetaRules.ROOM_NAMES.size())


func test_every_rescue_uses_a_breed_with_art() -> void:
	for n in MetaRules.RESCUE_LEVELS.size():
		var breed := MetaRules.breed_for_rescue(n)
		assert_bool(ArtAtlas.has_sprite("cat_%s_body" % breed)).is_true()
		assert_bool(MetaRules.BREED_LABELS.has(breed)).is_true()


func test_calendar_rewards_grow_and_end_with_a_booster() -> void:
	assert_int(MetaRules.CALENDAR.size()).is_equal(7)
	assert_str(MetaRules.reward_text(MetaRules.CALENDAR[6])).is_equal("300 altın + Lazer")


func test_next_day_crosses_the_year() -> void:
	assert_str(MetaRules.next_day("2026-12-31")).is_equal("2027-01-01")
