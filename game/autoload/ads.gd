extends Node

signal rewarded_granted(placement: StringName)
signal interstitial_shown

var enabled: bool = ProjectSettings.get_setting("game/ads_enabled", false)
var persist := true
var provider: AdProvider
var rules := AdRules.new()
var clock := func() -> float: return Time.get_ticks_msec() / 1000.0


func _ready() -> void:
	if provider == null:
		provider = _make_provider()
	var progress := get_node_or_null("/root/Progress")
	if progress:
		rules.first_session = progress.session_number <= 1
		rules.load_state(progress.data.get("ads", {}))


func is_rewarded_available(placement: StringName) -> bool:
	return enabled and provider.is_rewarded_ready(placement) and rules.can_show_rewarded(placement, _today())


func show_rewarded(placement: StringName) -> bool:
	if not is_rewarded_available(placement):
		return false
	var granted: bool = await provider.show_rewarded(placement)
	if granted:
		rules.record_rewarded(placement, clock.call(), _today())
		_persist()
		rewarded_granted.emit(placement)
	return granted


func level_completed() -> void:
	rules.record_level_completed()


func maybe_show_interstitial(context: StringName, level_id: int) -> bool:
	if not enabled or not provider.is_interstitial_ready():
		return false
	if not rules.can_show_interstitial(context, level_id, clock.call(), _today()):
		return false
	var shown: bool = await provider.show_interstitial()
	if shown:
		rules.record_interstitial(clock.call(), _today())
		_persist()
		interstitial_shown.emit()
	return shown


# Release phase C swaps this for the AdMob provider; until then every build declines all ads.
func _make_provider() -> AdProvider:
	return NullAdProvider.new()


func _persist() -> void:
	var progress := get_node_or_null("/root/Progress")
	if progress == null or not persist:
		return
	progress.data.ads = rules.save_state()
	progress.save()


func _today() -> String:
	return Time.get_date_string_from_system()
