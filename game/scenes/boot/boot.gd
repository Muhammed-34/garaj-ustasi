extends Control


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("fde8d0")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var label := Label.new()
	label.text = MetaRules.GAME_NAME
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color("5a3a28"))
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)

	print("boot ok ", Engine.get_version_info().string)
	UiKit.go(&"title")
