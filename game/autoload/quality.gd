extends Node

signal changed
signal slow_device_detected

const AUTO := &"auto"
const GIB := 1024 * 1024 * 1024
const WATCH_SECONDS := 5.0
const SLOW_FRAME_SECONDS := 0.020

var mode: StringName = AUTO
var reduce_motion := false:
	set(value):
		reduce_motion = value
		changed.emit()
var battery_saver := false:
	set(value):
		battery_saver = value
		_apply_fps()
		changed.emit()
var profile: QualityProfile

var _profiles := {
	&"low": preload("res://game/quality/quality_low.tres"),
	&"mid": preload("res://game/quality/quality_mid.tres"),
	&"high": preload("res://game/quality/quality_high.tres"),
}
var _watch_time := 0.0
var _watch_frames := 0
var _watch_done := false
var _dev_override := false


func _ready() -> void:
	_read_dev_args()
	apply()


func _process(delta: float) -> void:
	record_frame(delta)


# Phones sold as 3 GB / 4 GB report a little less usable memory, hence the 3.2 and 4.2 GiB cut-offs.
static func profile_id_for_memory(bytes: int) -> StringName:
	if bytes <= 0:
		return &"mid"
	if bytes <= int(3.2 * GIB):
		return &"low"
	if bytes <= int(4.2 * GIB):
		return &"mid"
	return &"high"


func set_mode(new_mode: StringName) -> void:
	mode = new_mode
	apply()


func apply() -> void:
	var id := mode
	if id == AUTO or not _profiles.has(id):
		id = profile_id_for_memory(int(OS.get_memory_info().get("physical", 0)))
	profile = _profiles[id]
	_apply_fps()
	changed.emit()


func has_dev_override() -> bool:
	return _dev_override


func particles_per_burst() -> int:
	return profile.particles_per_burst


func shake_enabled() -> bool:
	return profile.screen_shake and not reduce_motion


func hit_stop_enabled() -> bool:
	return profile.hit_stop and not reduce_motion


func trails_enabled() -> bool:
	return profile.trails and not reduce_motion


func parallax_enabled() -> bool:
	return profile.parallax and not reduce_motion


func duration(seconds: float) -> float:
	return seconds * profile.tween_scale


func record_frame(delta: float) -> void:
	if _watch_done or mode != AUTO or profile == null or profile.id == &"low":
		return
	_watch_time += delta
	_watch_frames += 1
	if _watch_time < WATCH_SECONDS:
		return
	var average := _watch_time / _watch_frames
	_watch_time = 0.0
	_watch_frames = 0
	if average > SLOW_FRAME_SECONDS:
		_watch_done = true
		slow_device_detected.emit()


func _apply_fps() -> void:
	if profile == null:
		return
	Engine.max_fps = 30 if battery_saver else profile.max_fps


func _read_dev_args() -> void:
	if not OS.is_debug_build():
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--quality="):
			mode = StringName(arg.trim_prefix("--quality="))
			_dev_override = true
		elif arg == "--reduce-motion":
			reduce_motion = true
