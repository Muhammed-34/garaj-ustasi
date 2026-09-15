class_name AdRules
extends RefCounted

const MIN_LEVEL := 12
const LEVELS_BETWEEN := 3
const MIN_GAP_SECONDS := 180.0
const MAX_PER_SESSION := 5
const MAX_PER_DAY := 20
const INTERSTITIAL_CONTEXT := &"win_continue"
const REWARDED_DAILY_CAPS := {&"pre_hard_booster": 5, &"feed_cats": 3, &"calendar_double": 1}

var first_session := true
var levels_since := 0
var session_count := 0
var last_shown_at := -INF
var day_key := ""
var day_count := 0
var rewarded_today := {}


func can_show_interstitial(context: StringName, level_id: int, now: float, today: String) -> bool:
	_roll_day(today)
	if first_session or context != INTERSTITIAL_CONTEXT or level_id < MIN_LEVEL:
		return false
	if levels_since < LEVELS_BETWEEN or now - last_shown_at < MIN_GAP_SECONDS:
		return false
	return session_count < MAX_PER_SESSION and day_count < MAX_PER_DAY


func record_level_completed() -> void:
	levels_since += 1


func record_interstitial(now: float, today: String) -> void:
	_roll_day(today)
	session_count += 1
	day_count += 1
	levels_since = 0
	last_shown_at = now


func can_show_rewarded(placement: StringName, today: String) -> bool:
	_roll_day(today)
	if not REWARDED_DAILY_CAPS.has(placement):
		return true
	return int(rewarded_today.get(placement, 0)) < REWARDED_DAILY_CAPS[placement]


# A watched rewarded ad also restarts the interstitial gap, so the player never gets two ads back to back.
func record_rewarded(placement: StringName, now: float, today: String) -> void:
	_roll_day(today)
	rewarded_today[placement] = int(rewarded_today.get(placement, 0)) + 1
	last_shown_at = now


func save_state() -> Dictionary:
	return {"day": day_key, "day_count": day_count, "rewarded": rewarded_today.duplicate()}


func load_state(state: Dictionary) -> void:
	day_key = str(state.get("day", ""))
	day_count = int(state.get("day_count", 0))
	rewarded_today = {}
	var saved = state.get("rewarded", {})
	if saved is Dictionary:
		for placement in saved:
			rewarded_today[StringName(placement)] = int(saved[placement])


func _roll_day(today: String) -> void:
	if today == day_key:
		return
	day_key = today
	day_count = 0
	rewarded_today.clear()
