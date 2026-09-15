extends Control

const QUALITY_OPTIONS := [[&"auto", "Otomatik"], [&"low", "Düşük"], [&"mid", "Orta"], [&"high", "Yüksek"]]
const PROFILE_NAMES := {&"low": "Düşük", &"mid": "Orta", &"high": "Yüksek"}

var quality_buttons := {}
var reduce_motion_toggle: Button
var battery_toggle: Button
var vibration_toggle: Button
var sound_toggle: Button

var _current_label: Label


func _ready() -> void:
	add_child(UiKit.background())
	var page := UiKit.page()
	add_child(page)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	page.add_child(column)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	column.add_child(top)
	var back := UiKit.button("‹ Geri", 28, Vector2(150, 72))
	back.pressed.connect(func() -> void: UiKit.go(&"map"))
	top.add_child(back)
	top.add_child(UiKit.label("Ayarlar", 46))

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE, 28, 28))
	column.add_child(card)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 22)
	card.add_child(rows)

	rows.add_child(UiKit.label("Grafik kalitesi", 32))
	var options := HBoxContainer.new()
	options.add_theme_constant_override("separation", 10)
	rows.add_child(options)
	var group := ButtonGroup.new()
	for option in QUALITY_OPTIONS:
		var button := UiKit.button(option[1], 24, Vector2(140, 76), Color.WHITE, UiKit.INK, 22)
		button.toggle_mode = true
		button.button_group = group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_stylebox_override("pressed", UiKit.box(UiKit.ACCENT, 22, 12))
		button.add_theme_stylebox_override("hover_pressed", UiKit.box(UiKit.ACCENT, 22, 12))
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
		button.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
		button.pressed.connect(select_quality.bind(option[0]))
		options.add_child(button)
		quality_buttons[option[0]] = button
	_current_label = UiKit.label("", 24, UiKit.MUTED)
	rows.add_child(_current_label)

	reduce_motion_toggle = _add_toggle(rows, "Animasyonları azalt", "reduce_motion")
	battery_toggle = _add_toggle(rows, "Pil tasarrufu (30 fps)", "battery_saver")
	sound_toggle = _add_toggle(rows, "Ses efektleri", "sound")
	vibration_toggle = _add_toggle(rows, "Titreşim", "vibration")

	var licenses := UiKit.button("Lisanslar", 30, Vector2(0, 88))
	licenses.pressed.connect(func() -> void: UiKit.go(&"licenses"))
	column.add_child(licenses)

	var version := UiKit.label("Sürüm %s" % ProjectSettings.get_setting("application/config/version", "0.1.0"), 22, UiKit.MUTED)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(version)

	_sync()


func select_quality(mode: StringName) -> void:
	var progress := UiKit.progress()
	if progress:
		progress.set_setting("quality", str(mode))
	_sync()


func _add_toggle(parent: Control, text: String, key: String) -> Button:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var caption := UiKit.label(text, 28)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(caption)
	var toggle := UiKit.button("", 24, Vector2(150, 64), Color.WHITE, UiKit.INK, 32)
	toggle.toggle_mode = true
	toggle.add_theme_stylebox_override("pressed", UiKit.box(UiKit.ACCENT, 32, 12))
	toggle.add_theme_stylebox_override("hover_pressed", UiKit.box(UiKit.ACCENT, 32, 12))
	toggle.add_theme_color_override("font_pressed_color", Color.WHITE)
	toggle.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	var progress := UiKit.progress()
	toggle.set_pressed_no_signal(bool(progress.setting(key)) if progress else false)
	toggle.text = "Açık" if toggle.button_pressed else "Kapalı"
	toggle.toggled.connect(func(on: bool) -> void:
		toggle.text = "Açık" if on else "Kapalı"
		var current := UiKit.progress()
		if current:
			current.set_setting(key, on)
		_sync())
	row.add_child(toggle)
	return toggle


func _sync() -> void:
	var progress := UiKit.progress()
	var mode := StringName(str(progress.setting("quality"))) if progress else &"auto"
	if quality_buttons.has(mode):
		quality_buttons[mode].set_pressed_no_signal(true)
	var quality := UiKit.autoload("Quality")
	if quality and quality.profile:
		_current_label.text = "Şu an kullanılan: %s" % PROFILE_NAMES.get(quality.profile.id, "")
