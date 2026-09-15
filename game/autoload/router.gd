extends Node

const SCENES := {
	&"title": "res://game/scenes/title/title.tscn",
	&"map": "res://game/scenes/map/map.tscn",
	&"game": "res://game/scenes/game/game.tscn",
	&"settings": "res://game/scenes/settings/settings.tscn",
	&"licenses": "res://game/scenes/licenses/licenses.tscn",
	&"recipes": "res://game/scenes/recipes/recipes.tscn",
}
const FADE_TIME := 0.18

var params := {}
var busy := false

var _layer := CanvasLayer.new()
var _fade := ColorRect.new()
var _shot_path := ""
var _shot_after := -1.0
var _elapsed := 0.0


func _ready() -> void:
	_layer.layer = 100
	add_child(_layer)
	_fade.color = Color(UiKit.CREAM_TOP, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_fade)
	_read_dev_args()
	set_process(_shot_after >= 0.0 and not _shot_path.is_empty())
	get_tree().set_quit_on_go_back(false)


# Android back button: scenes with handle_back() decide (the title screen closes the app);
# the map returns to the title screen; anything else returns to the map.
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST or busy:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	if UiKit.close_open_popup(scene):
		return
	if scene.has_method("handle_back"):
		scene.handle_back()
	elif scene.scene_file_path == SCENES[&"map"]:
		go(&"title")
	else:
		go(&"map")


# Dev-only screenshot hook: --shot=<png path> --shot-after=<seconds> works on any scene.
func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < _shot_after:
		return
	set_process(false)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shot_path)
	print("shot saved ", _shot_path)
	get_tree().quit()


func _read_dev_args() -> void:
	if not OS.is_debug_build():
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_shot_path = arg.trim_prefix("--shot=")
		elif arg.begins_with("--shot-after="):
			_shot_after = arg.trim_prefix("--shot-after=").to_float()
		elif arg.begins_with("--level="):
			params = {"level_id": arg.trim_prefix("--level=").to_int()}


func go(scene: StringName, new_params: Dictionary = {}) -> void:
	if busy or not SCENES.has(scene):
		return
	busy = true
	params = new_params
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var duration := _fade_time()
	await create_tween().tween_property(_fade, "color:a", 1.0, duration).finished
	get_tree().change_scene_to_file(SCENES[scene])
	await get_tree().process_frame
	await get_tree().process_frame
	await create_tween().tween_property(_fade, "color:a", 0.0, duration).finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false


func _fade_time() -> float:
	var quality := get_node_or_null("/root/Quality")
	return quality.duration(FADE_TIME) if quality and quality.profile else FADE_TIME
