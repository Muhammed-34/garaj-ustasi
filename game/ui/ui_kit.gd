class_name UiKit
extends RefCounted

const INK := Color("5a3a28")
const MUTED := Color("9a7a64")
const ACCENT := Color("e8613b")
const DANGER := Color("d94a3a")
const TRACK := Color("eadbc9")
const LOCKED := Color("eadccb")
const CREAM_TOP := Color("fde8d0")
const CREAM_BOTTOM := Color("f6d2ae")
const SHADOW := Color(0.47, 0.27, 0.12, 0.18)
const MODAL_GROUP := &"modal"


static func label(text: String, font_size: int, color: Color = INK) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	return result


static func box(color: Color, radius: int, padding: int, shadow: bool = true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(padding)
	if shadow:
		style.shadow_color = SHADOW
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 5)
	return style


static func button(text: String, font_size: int, min_size: Vector2, fill: Color = Color.WHITE, text_color: Color = INK, radius: int = 40) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = min_size
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	style_button(result, fill, text_color, radius)
	result.pressed.connect(func() -> void: sound(&"click"))
	return result


static func style_button(target: Button, fill: Color, text_color: Color, radius: int) -> void:
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		target.add_theme_color_override(state, text_color)
	target.add_theme_color_override("font_disabled_color", MUTED)
	target.add_theme_stylebox_override("normal", box(fill, radius, 12))
	target.add_theme_stylebox_override("hover", box(fill.lightened(0.06), radius, 12))
	target.add_theme_stylebox_override("pressed", box(fill.darkened(0.08), radius, 12))
	target.add_theme_stylebox_override("hover_pressed", box(fill.darkened(0.08), radius, 12))
	target.add_theme_stylebox_override("disabled", box(LOCKED, radius, 12, false))


static func pill(text: String, fill: Color, text_color: Color, font_size: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := box(fill, 999, 10, false)
	style.content_margin_left = 18
	style.content_margin_right = 18
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(label(text, font_size, text_color))
	return panel


static func background() -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, CREAM_TOP)
	gradient.set_color(1, CREAM_BOTTOM)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_to = Vector2(0, 1)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


static func page() -> MarginContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 32)
	return margin


# Returns the content column of a centered modal card; toggle it with popup_root(rows).visible.
static func popup(parent: Control, width: float = 560.0) -> VBoxContainer:
	var overlay := ColorRect.new()
	overlay.color = Color(0.2, 0.1, 0.05, 0.55)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.add_to_group(MODAL_GROUP)
	parent.add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	panel.add_theme_stylebox_override("panel", box(Color.WHITE, 36, 36))
	center.add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 18)
	panel.add_child(rows)
	return rows


# Hides the first open popup inside root; Android Back uses this so it closes a popup before leaving a screen.
static func close_open_popup(root: Node) -> bool:
	for modal in root.get_tree().get_nodes_in_group(MODAL_GROUP):
		if modal is CanvasItem and modal.is_visible_in_tree() and root.is_ancestor_of(modal):
			modal.visible = false
			return true
	return false


static func popup_root(rows: Control) -> Control:
	return rows.get_parent().get_parent().get_parent()


static func centered_label(text: String, font_size: int, color: Color = INK) -> Label:
	var result := label(text, font_size, color)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return result


static func idle_level() -> int:
	var quality := autoload("Quality")
	if quality == null or quality.profile == null:
		return 2
	var setting: int = quality.profile.shelter_idle_level
	return mini(setting, 1) if quality.reduce_motion else setting


static func autoload(autoload_name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null(autoload_name) if tree else null


static func sound(sound_name: StringName, pitch: float = 1.0) -> void:
	var audio := autoload("Audio")
	if audio:
		audio.play(sound_name, pitch)


static func progress() -> Node:
	return autoload("Progress")


static func ads() -> Node:
	return autoload("Ads")


static func router_params() -> Dictionary:
	var router := autoload("Router")
	return router.params if router else {}


static func go(scene: StringName, params: Dictionary = {}) -> void:
	var router := autoload("Router")
	if router:
		router.go(scene, params)
