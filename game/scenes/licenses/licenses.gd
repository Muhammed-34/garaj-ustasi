extends Control

const TURKISH_NOTE := "Oyun, ücretsiz ve açık kaynaklı Godot oyun motoruyla yapılmıştır. Godot ve içindeki bileşenlerin lisansları; yazılımı ücretsiz kullanmaya, değiştirmeye ve dağıtmaya izin verir, karşılığında telif bildirimlerinin ve lisans metinlerinin gösterilmesini ister. Bu metinler hukuki olarak yalnızca özgün İngilizce halleriyle geçerli olduğu için aşağıda çevrilmeden verilmiştir."

var text_label: RichTextLabel


# Android Back matches the on-screen button and returns to Settings, not the map.
func handle_back() -> void:
	UiKit.go(&"settings")


func _ready() -> void:
	add_child(UiKit.background())
	var page := UiKit.page()
	add_child(page)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	page.add_child(column)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	column.add_child(top)
	var back := UiKit.button("‹ Geri", 28, Vector2(150, 72))
	back.pressed.connect(func() -> void: UiKit.go(&"settings"))
	top.add_child(back)
	top.add_child(UiKit.label("Lisanslar", 46))

	var card := PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE, 28, 24))
	column.add_child(card)
	var scroll := DragScroll.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(scroll)
	text_label = RichTextLabel.new()
	text_label.fit_content = true
	# About 90k characters: laying them out on the main thread froze the screen as it opened.
	text_label.threaded = true
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.add_theme_font_size_override("normal_font_size", 20)
	text_label.add_theme_color_override("default_color", UiKit.INK)
	text_label.text = build_text()
	scroll.add_child(text_label)


static func build_text() -> String:
	var lines := PackedStringArray()
	lines.append(MetaRules.GAME_NAME)
	lines.append("Oyundaki tüm çizimler ve sesler bu proje için özgün olarak kodla üretilmiştir.")
	lines.append("")
	lines.append("Lisanslar hakkında")
	lines.append(TURKISH_NOTE)
	lines.append("")
	lines.append("Godot Engine")
	lines.append(_reflow(Engine.get_license_text()))
	lines.append("")
	lines.append("Godot Engine içindeki üçüncü taraf bileşenler")
	for component in Engine.get_copyright_info():
		lines.append("")
		lines.append(str(component.name))
		for part in component.parts:
			for holder in part.copyright:
				lines.append("  © " + str(holder))
			lines.append("  Lisans: " + str(part.license))
	var licenses := Engine.get_license_info()
	for license_name in licenses:
		lines.append("")
		lines.append(str(license_name))
		lines.append(_reflow(str(licenses[license_name])))
	return "\n".join(lines)


# License files are hard-wrapped at ~80 columns; joining lines inside a paragraph lets the phone wrap them.
static func _reflow(text: String) -> String:
	var paragraphs := PackedStringArray()
	for paragraph in text.split("\n\n"):
		paragraphs.append(paragraph.strip_edges().replace("\n", " "))
	return "\n\n".join(paragraphs)
