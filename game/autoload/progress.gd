extends Node

signal changed

const SAVE_VERSION := 2
const DEFAULT_PATH := "user://save.json"
const START_COINS := 200
const START_BOOSTERS := {"row": 2, "shuffle": 1, "single": 3}
const BOOSTER_PRICES := {"row": 300, "shuffle": 200, "single": 150}
const CONTINUE_COST := 250
const CONTINUE_MOVES := 5
const WIN_COINS := 20
const STAR_COINS := 10

var save_path := DEFAULT_PATH
var persist := true
var apply_to_quality := true
var data := {}
var session_number := 0
# Set when a level left open by a closed app cost a bowl at launch; the map explains it once.
var bowl_lost_on_launch := false


func _ready() -> void:
	if OS.is_debug_build():
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--save="):
				save_path = arg.trim_prefix("--save=")
	load_game()
	if int(data.bowls.open_level) != 0:
		spend_bowl()
		bowl_lost_on_launch = true
	data.sessions = int(data.sessions) + 1
	session_number = int(data.sessions)
	save()
	if apply_to_quality:
		apply_settings()


static func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"sessions": 0,
		"unlocked": 1,
		"stars": {},
		"coins": START_COINS,
		"boosters": START_BOOSTERS.duplicate(),
		"settings": {"quality": "auto", "reduce_motion": false, "battery_saver": false, "vibration": true, "sound": true},
		"ads": {},
		"cats": [],
		"next_cat_id": 1,
		"mail": [],
		"calendar": {"index": 0, "last_claim": ""},
		"intros_seen": [],
		# open_level is the level of an attempt in progress; a set value on launch means the app was closed mid-level.
		"bowls": {"count": MetaRules.MAX_BOWLS, "refill_at": 0, "open_level": 0},
	}


static func upgrade(raw: Dictionary) -> Dictionary:
	var source := raw
	if not source.is_empty() and int(source.get("version", 1)) < 2:
		source = migrate_1_to_2(source)
	var result := default_data()
	_merge(result, source)
	result.version = SAVE_VERSION
	return result


# Version 1 had no cats; players who already beat rescue levels get those cats with suggested names.
static func migrate_1_to_2(raw: Dictionary) -> Dictionary:
	var migrated := raw.duplicate(true)
	var stars = migrated.get("stars", {})
	var cats := []
	if stars is Dictionary:
		for index in MetaRules.RESCUE_LEVELS.size():
			var level_id: int = MetaRules.RESCUE_LEVELS[index]
			if int(stars.get(str(level_id), 0)) <= 0:
				break
			cats.append(MetaRules.new_cat(index + 1, index, MetaRules.NAME_POOL[index % MetaRules.NAME_POOL.size()], level_id))
	migrated["cats"] = cats
	migrated["next_cat_id"] = cats.size() + 1
	migrated["version"] = 2
	return migrated


static func stars_for_result(moves_left: int, total_moves: int) -> int:
	var ratio := float(moves_left) / maxi(total_moves, 1)
	if ratio >= 0.3:
		return 3
	if ratio >= 0.15:
		return 2
	return 1


func load_game() -> void:
	data = upgrade(SaveFile.read(save_path))


func save() -> void:
	if persist:
		SaveFile.write(save_path, data)


func reset() -> void:
	data = default_data()
	bowl_lost_on_launch = false
	save()
	changed.emit()


func take_bowl_lost_note() -> bool:
	var lost := bowl_lost_on_launch
	bowl_lost_on_launch = false
	return lost


func is_unlocked(level_id: int) -> bool:
	return level_id >= 1 and level_id <= mini(int(data.unlocked), Levels.COUNT)


func stars_for(level_id: int) -> int:
	return int(data.stars.get(str(level_id), 0))


func highest_beaten() -> int:
	var best := 0
	for key in data.stars:
		if int(data.stars[key]) > 0:
			best = maxi(best, int(key))
	return best


func coins() -> int:
	return int(data.coins)


func booster_stock(booster: StringName) -> int:
	return int(data.boosters.get(str(booster), 0))


func record_win(level_id: int, moves_left: int, total_moves: int) -> Dictionary:
	var stars := stars_for_result(moves_left, total_moves)
	var party := mini(maxi(moves_left, 0), MetaRules.PARTY_MAX_MOVES) * MetaRules.PARTY_COINS
	var earned := WIN_COINS + STAR_COINS * (stars - 1) + party
	data.coins = coins() + earned
	data.stars[str(level_id)] = maxi(stars_for(level_id), stars)
	data.unlocked = maxi(int(data.unlocked), mini(level_id + 1, Levels.COUNT))
	save()
	changed.emit()
	return {"stars": stars, "coins": earned, "party_coins": party}


func use_booster(booster: StringName) -> bool:
	var stock := booster_stock(booster)
	if stock <= 0:
		return false
	data.boosters[str(booster)] = stock - 1
	save()
	changed.emit()
	return true


func buy_booster(booster: StringName) -> bool:
	var price: int = BOOSTER_PRICES.get(str(booster), 0)
	if price <= 0 or not spend_coins(price):
		return false
	data.boosters[str(booster)] = booster_stock(booster) + 1
	save()
	changed.emit()
	return true


func spend_coins(amount: int) -> bool:
	if amount < 0 or coins() < amount:
		return false
	data.coins = coins() - amount
	save()
	changed.emit()
	return true


func cats() -> Array:
	return data.cats


func shelter_cats() -> Array:
	return data.cats.filter(func(cat: Dictionary) -> bool: return not bool(cat.adopted))


func find_cat(cat_id: String) -> Dictionary:
	for cat in data.cats:
		if str(cat.id) == cat_id:
			return cat
	return {}


func next_pending_rescue_level() -> int:
	var index: int = data.cats.size()
	if index >= MetaRules.RESCUE_LEVELS.size():
		return -1
	var level_id: int = MetaRules.RESCUE_LEVELS[index]
	return level_id if stars_for(level_id) > 0 else -1


func pending_rescue_breed() -> String:
	return MetaRules.breed_for_rescue(data.cats.size())


func levels_until_next_rescue() -> int:
	var index: int = data.cats.size()
	if index >= MetaRules.RESCUE_LEVELS.size():
		return -1
	return maxi(0, int(MetaRules.RESCUE_LEVELS[index]) - highest_beaten())


func rescue_cat(level_id: int, cat_name: String) -> Dictionary:
	if next_pending_rescue_level() != level_id:
		return {}
	var clean := MetaRules.sanitize_name(cat_name)
	if clean.is_empty():
		var taken: Array = data.cats.map(func(cat: Dictionary) -> String: return str(cat.name))
		clean = MetaRules.suggest_names(taken, 1, data.cats.size())[0]
	var cat := MetaRules.new_cat(int(data.next_cat_id), data.cats.size(), clean, level_id)
	data.cats.append(cat)
	data.next_cat_id = int(data.next_cat_id) + 1
	save()
	changed.emit()
	return cat


func set_favorite(cat_id: String, favorite: bool) -> void:
	var cat := find_cat(cat_id)
	if cat.is_empty():
		return
	cat.favorite = favorite
	save()
	changed.emit()


func adopt_cat(cat_id: String, today: String = "") -> String:
	var cat := find_cat(cat_id)
	if cat.is_empty():
		return "Kedi bulunamadı."
	var reason := MetaRules.adoption_block_reason(cat, highest_beaten())
	if not reason.is_empty():
		return reason
	cat.adopted = true
	data.mail.append({"cat_id": cat.id, "text": MetaRules.letter_text(cat), "deliver_on": MetaRules.next_day(_today(today)), "read": false})
	save()
	changed.emit()
	return ""


func mailbox(today: String = "") -> Array:
	var day := _today(today)
	return data.mail.filter(func(letter: Dictionary) -> bool: return str(letter.deliver_on) <= day)


func unread_mail_count(today: String = "") -> int:
	return mailbox(today).filter(func(letter: Dictionary) -> bool: return not bool(letter.read)).size()


func mark_mail_read(today: String = "") -> void:
	for letter in mailbox(today):
		letter.read = true
	save()
	changed.emit()


func calendar_index() -> int:
	return int(data.calendar.index) % MetaRules.CALENDAR.size()


func can_claim_calendar(today: String = "") -> bool:
	return str(data.calendar.last_claim) != _today(today)


func claim_calendar(today: String = "") -> Dictionary:
	if not can_claim_calendar(today):
		return {}
	var reward: Dictionary = MetaRules.CALENDAR[calendar_index()]
	data.coins = coins() + int(reward.get("coins", 0))
	if reward.has("booster"):
		data.boosters[str(reward.booster)] = booster_stock(StringName(reward.booster)) + 1
	data.calendar.index = int(data.calendar.index) + 1
	data.calendar.last_claim = _today(today)
	save()
	changed.emit()
	return reward


func bowls(now: int = -1) -> int:
	_settle_bowls(_now(now))
	return int(data.bowls.count)


func seconds_to_next_bowl(now: int = -1) -> int:
	var t := _now(now)
	_settle_bowls(t)
	if int(data.bowls.count) >= MetaRules.MAX_BOWLS:
		return 0
	return maxi(0, int(data.bowls.refill_at) - t)


func can_start_level(now: int = -1) -> bool:
	return bowls(now) > 0


# Marks a level attempt as under way once the player makes a move.
func begin_attempt(level_id: int) -> void:
	if int(data.bowls.open_level) == level_id:
		return
	data.bowls.open_level = level_id
	save()


func end_attempt() -> void:
	if int(data.bowls.open_level) == 0:
		return
	data.bowls.open_level = 0
	save()


# A failed or abandoned attempt empties one bowl; emptying a full set starts the refill clock.
func spend_bowl(now: int = -1) -> void:
	var t := _now(now)
	_settle_bowls(t)
	var count := int(data.bowls.count)
	if count >= MetaRules.MAX_BOWLS:
		data.bowls.refill_at = t + MetaRules.BOWL_REFILL_SECONDS
	data.bowls.count = maxi(count - 1, 0)
	data.bowls.open_level = 0
	save()
	changed.emit()


func refill_bowls_with_coins() -> bool:
	if int(data.bowls.count) >= MetaRules.MAX_BOWLS or not spend_coins(MetaRules.BOWL_REFILL_ALL_COST):
		return false
	data.bowls.count = MetaRules.MAX_BOWLS
	data.bowls.refill_at = 0
	save()
	changed.emit()
	return true


func _settle_bowls(t: int) -> void:
	var count := int(data.bowls.count)
	if count >= MetaRules.MAX_BOWLS:
		return
	var old_refill := int(data.bowls.refill_at)
	var refill_at := old_refill
	# A missing time, or a clock turned backwards, never makes the wait longer than one refill.
	if refill_at <= 0 or refill_at - t > MetaRules.BOWL_REFILL_SECONDS:
		refill_at = t + MetaRules.BOWL_REFILL_SECONDS
	var before := count
	while count < MetaRules.MAX_BOWLS and t >= refill_at:
		count += 1
		refill_at += MetaRules.BOWL_REFILL_SECONDS
	if count >= MetaRules.MAX_BOWLS:
		refill_at = 0
	data.bowls.count = count
	data.bowls.refill_at = refill_at
	if count != before or refill_at != old_refill:
		save()


func _now(now: int) -> int:
	return now if now >= 0 else int(Time.get_unix_time_from_system())


func intro_seen(intro_id: String) -> bool:
	return data.intros_seen.has(intro_id)


func mark_intro_seen(intro_id: String) -> void:
	if intro_seen(intro_id):
		return
	data.intros_seen.append(intro_id)
	save()


func setting(key: String) -> Variant:
	return data.settings.get(key)


func set_setting(key: String, value: Variant) -> void:
	data.settings[key] = value
	save()
	if apply_to_quality:
		apply_settings()
	changed.emit()


func apply_settings() -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio:
		audio.enabled = bool(setting("sound"))
	var quality := get_node_or_null("/root/Quality")
	if quality == null:
		return
	quality.reduce_motion = bool(setting("reduce_motion"))
	quality.battery_saver = bool(setting("battery_saver"))
	if not quality.has_dev_override():
		quality.set_mode(StringName(str(setting("quality"))))


func _today(today: String) -> String:
	return today if not today.is_empty() else Time.get_date_string_from_system()


# Copies saved values onto the defaults, keeping defaults for missing keys or values of the wrong type.
static func _merge(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		if not target.has(key):
			target[key] = source[key]
			continue
		var current = target[key]
		var incoming = source[key]
		if current is Dictionary and incoming is Dictionary:
			_merge(current, incoming)
		elif typeof(current) == typeof(incoming) or (_is_number(current) and _is_number(incoming)):
			target[key] = incoming


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
